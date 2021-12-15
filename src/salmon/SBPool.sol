pragma solidity 0.8.10;
// SPDX-License-Identifier: GPL-3.0-only

/* Local Imports */
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IKodiaqPair} from "../../interfaces/IKodiaqPair.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";
import {KodiaqLibrary} from "../kodiaq/KodiaqLibrary.sol";

/* Package Imports */
import {ERC20} from "bera-solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "bera-solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "bera-solmate/utils/FixedPointMathlib.sol";
import {SBERC20} from "./SBERC20.sol";

contract SBPool {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for SBERC20;
    using FixedPointMathLib for uint256;
    using KodiaqLibrary for IKodiaqRouter;
    SBERC20[] sbTokens = new SBERC20[](2);
    IKodiaqPair kodiaqPair;
    IKodiaqRouter kodiaqRouter;
    uint256 leverageFactor;
    address beraReserve;
    address sbController;
    uint256 feePercentage = 3e16; // 3% fee for borrowing
    uint256 liqFeePercentage = feePercentage; // 3% penalty for getting liquidated
    // Setting these equal helps prevent the Pool from operating at a loss
    mapping(SBERC20 => mapping(address => uint256)) borrowedAmount; // sbToken => (wallet => amount)

    constructor(
        address _kodiaqRouter,
        uint256 _leverageFactor,
        address _kodiaqPair
    ) {
        // Setup
        leverageFactor = _leverageFactor;
        kodiaqRouter = IKodiaqRouter(_kodiaqRouter);
        kodiaqPair = IKodiaqPair(_kodiaqPair);
        sbTokens[0] = new SBERC20(address(this), kodiaqPair.token0());
        sbTokens[1] = new SBERC20(address(this), kodiaqPair.token1());
    }

    /*///////////////////////////////////////////////////////////////
                                Borrow
    //////////////////////////////////////////////////////////////*/

    function borrow(uint256 amount, uint256 index) public {
        // Calculate amounts and fees
        SBERC20 colToken = (index == 0) ? sbTokens[1] : sbTokens[0];
        SBERC20 borToken = (colToken == sbTokens[1]) ? sbTokens[0] : sbTokens[1];
        uint256 collateralRequired = kodiaqRouter.getQuote(amount, address(colToken.underlying()), address(borToken.underlying()));
        uint256 collateralRequiredWithFee = collateralRequired.fmul(1e18 + feePercentage, FixedPointMathLib.WAD);

        // Increment borrowed amount, run safety checks and burn fee tokens.
        borrowedAmount[borToken][msg.sender] += amount;
        require(withinLeverageFactor(msg.sender, index), "SBPool: Cannot execute borrow, too levered");
        SBERC20(colToken).burn(msg.sender, collateralRequiredWithFee - collateralRequired);

        // Swap to get tokens
        address[] memory path = new address[](2);
        path[0] = address(colToken);
        path[1] = address(borToken);
        IBeraReserve(beraReserve).withdrawToken(path[0], address(this), collateralRequired);
        kodiaqRouter.swapExactTokensForTokens(
            collateralRequired,
            amount,
            path,
            msg.sender,
            block.timestamp + 1
        );

        // Calculate how much LP is needed to get all tokens out of the pool contract.
        (uint112 reserves0, uint112 reserves1,) = kodiaqPair.getReserves();
        uint112 reservesToUse = (address(colToken) == kodiaqPair.token0()) ? reserves0 : reserves1;
        uint256 requiredLP = collateralRequired * ERC20(address(kodiaqPair)).totalSupply() / reservesToUse;

        // Withdraw LP needed to execute the dex swap
        IBeraReserve(beraReserve).withdrawToken(address(kodiaqPair), address(this), requiredLP);

        // Restore Collateral balance
        kodiaqRouter.removeLiquidity(
            path[0],
            path[1],
            requiredLP,
            0,
            0,
            beraReserve,
            block.timestamp + 1
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Manage Collateral
    //////////////////////////////////////////////////////////////*/

    function depositCollateral(address user, uint256 index, uint256 amount) public {
        // Pull tokens from user
        ERC20(sbTokens[index].underlying()).safeTransferFrom(msg.sender, beraReserve, amount);
        // Mint sbTokens to the user
        sbTokens[index].mint(user, amount);
    }

    function withdrawCollateral(uint256 amount, uint256 index) public {
        uint256 requiredCollateral = minRequiredCollateralToRemainSolvent(msg.sender, index);
        // Burn sbTokens
        sbTokens[index].burn(msg.sender, amount);
        require(withinLeverageFactor(msg.sender, index), "SBPool: Cannot execute withdrawl, user too levered");
        // Withdraw the underlying collateral to the user
        IBeraReserve(beraReserve).withdrawToken(address(sbTokens[index].underlying()), msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Manage Debt
    //////////////////////////////////////////////////////////////*/

    function repayDebt(address user, uint256 amount, uint256 index) external {
        // Setup
        SBERC20 colToken = (index == 1) ? sbTokens[1] : sbTokens[0];
        SBERC20 repayToken = (colToken == sbTokens[1]) ? sbTokens[0] : sbTokens[1];
        ERC20 underlying = repayToken.underlying();
        
        // Pay back tokens
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        borrowedAmount[repayToken][user] -= amount;

        // Re supply the liquidity that was removed in `borrow()`
        uint256 colValue = kodiaqRouter.getQuote(amount, address(repayToken.underlying()), address(colToken.underlying()));
        IBeraReserve(beraReserve).withdrawToken(address(colToken), address(this), colValue);
        kodiaqRouter.addLiquidity(address(colToken), address(repayToken), colValue, amount, colValue, amount, beraReserve, block.timestamp + 1);
    }

    function liquidate(address user, uint256 deposit, uint256 index) external {
        SBERC20 depositToken = index == 0 ? sbTokens[1] : sbTokens[0];
        SBERC20 seizeToken = index == 0 ? sbTokens[0] : sbTokens[1];
        uint256 maxSeize = amountEligibleForLiquidation(user, index);
        if (maxSeize == 0) revert("SBPool: User is out of collateral to seize");

        // Ensure seize numbers are valid
        uint256 valueOfDeposit = kodiaqRouter.getQuote(deposit, address(depositToken.underlying()), address(seizeToken.underlying()));
        uint256 toSeize = FixedPointMathLib.min(maxSeize, FixedPointMathLib.min(valueOfDeposit, seizeToken.balanceOf(user)));
        uint256 valueOfToSeize = kodiaqRouter.getQuote(toSeize, address(seizeToken.underlying()), address(depositToken.underlying()));

        // Discount incentive to liquidator
        valueOfToSeize = valueOfToSeize.fmul(1e18 - liqFeePercentage, FixedPointMathLib.WAD);
        // Pull borrowed tokens from the liquidator
        depositToken.safeTransferFrom(msg.sender, beraReserve, valueOfToSeize);
        // Liquidate liquidatee
        seizeToken.safeTransferFrom(user, msg.sender, toSeize);
        // Debt has been repayed
        borrowedAmount[seizeToken][user] -= valueOfToSeize;
    }

    /*///////////////////////////////////////////////////////////////
                            Helper Functions
    //////////////////////////////////////////////////////////////*/

    function isSolvent(address user, uint256 index) public view returns (bool) {
        return amountEligibleForLiquidation(user, index) == 0;
    }

    function withinLeverageFactor(address user, uint256 index) public view returns (bool) {
        uint256 minimumCollateral = minRequiredCollateralToRemainSolvent(user, index);
        uint256 colBalance = sbTokens[index].balanceOf(user);
        // Leverage factor [0, 1e18)
        return colBalance.fmul(leverageFactor, FixedPointMathLib.WAD) >= minimumCollateral;
    }

    function amountEligibleForLiquidation(address user, uint256 index) public view returns (uint256) {
        uint256 totalCollateral = sbTokens[index].balanceOf(user);
        uint256 requiredCollateral = minRequiredCollateralToRemainSolvent(user, index);
        if (requiredCollateral <= totalCollateral) return 0;
        return requiredCollateral - totalCollateral;
    }

    function minRequiredCollateralToRemainSolvent(address user, uint256 index) public view returns (uint256) {
        if (index == 0)
            return kodiaqRouter.getQuote(borrowedAmount[sbTokens[1]][msg.sender], address(sbTokens[1].underlying()), address(sbTokens[0].underlying()));
        return kodiaqRouter.getQuote(borrowedAmount[sbTokens[0]][msg.sender], address(sbTokens[0].underlying()), address(sbTokens[1].underlying()));
    }
}
