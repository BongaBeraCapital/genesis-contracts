pragma solidity 0.8.10;
// SPDX-License-Identifier: GPL-3.0-only

/* Local Imports */
import {BeraMixin} from "../mixins/BeraMixin.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";
import {IKodiaqPair} from "../../interfaces/IKodiaqPair.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";
import {IKodiaqFactory} from "../../interfaces/IKodiaqFactory.sol";
import {KodiaqLibrary} from "../kodiaq/KodiaqLibrary.sol";

/* Package Imports */
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathlib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract SBPoolWrapperBera is ERC20, BeraMixin {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using KodiaqLibrary for IKodiaqRouter;

    address[] path = new address[](2);
    IKodiaqRouter kodiaqRouter;
    IKodiaqFactory kodiaqFactory;
    address kodiaqPair;
    uint256 leverageFactor;
    address beraReserve;
    uint256 feePercentage = 2.5e16; // 2% fee for lending by default
    uint256 liqFeePercentage = 1e17; // 10% penalty for getting liquidated
    mapping(address => uint256) borrowedAmount;
    mapping(address => uint256) depositedCollateral;

    constructor(
        address _storageAddress,
        address _kodiaqRouter,
        address _kodiaqFactory,
        uint256 _leverageFactor,
        address _token,
        uint256 _feePercentage
    )
        ERC20(
            string(abi.encodePacked("Salmon Brothers ", ERC20(_token).name())),
            string(abi.encodePacked("sb", ERC20(_token).symbol())),
            ERC20(_token).decimals()
        )
        BeraMixin(_storageAddress)
    {
        // Setup
        leverageFactor = _leverageFactor;
        feePercentage = _feePercentage;
        kodiaqFactory = IKodiaqFactory(_kodiaqFactory);
        kodiaqRouter = IKodiaqRouter(_kodiaqRouter);
        path[0] = _token;
        path[1] = kodiaqRouter.WBERA();
        kodiaqPair = kodiaqFactory.getPair(path[0], kodiaqRouter.WBERA());
        assert(kodiaqPair != address(0));
    }

    /*///////////////////////////////////////////////////////////////
                            Borrow & Repay
    //////////////////////////////////////////////////////////////*/

    function borrow(uint256 amountToBorrow) public {
        // Calculate amounts and fees
        uint256 collateralToUse = kodiaqRouter.getQuote(amountToBorrow, path[1], path[0]);
        uint256 amountAfterFees = amountToBorrow - amountToBorrow.fmul(feePercentage, FixedPointMathLib.WAD);
        uint256 feeAmount = collateralToUse.fmul(feePercentage, FixedPointMathLib.WAD);
        uint256 collateralToUseAfterFee = collateralToUse - feeAmount;
        borrowedAmount[msg.sender] += amountAfterFees;

        // Burn fee portion of sbXXX token
        _burn(msg.sender, feeAmount);

        // Swap to get user BERA
        kodiaqRouter.swapExactTokensForBERASupportingFeeOnTransferTokens(
            collateralToUseAfterFee,
            amountAfterFees,
            path,
            msg.sender,
            block.timestamp + 1
        );

        // Calculate how much LP is needed to bring balance of original Collateral back.
        uint256 lpToWithdraw = (collateralToUseAfterFee * (10**18 - uint256(ERC20(path[0]).decimals()))).fdiv(
            ERC20(kodiaqPair).totalSupply(),
            FixedPointMathLib.WAD
        );

        // Withdraw LP needed to execute the dex swap
        IBeraReserve(beraReserve).withdrawToken(kodiaqPair, address(this), lpToWithdraw);

        // Restore Collateral balance
        kodiaqRouter.removeLiquidityBERASupportingFeeOnTransferTokens(
            path[0],
            lpToWithdraw,
            collateralToUseAfterFee,
            0,
            beraReserve,
            block.timestamp + 1
        );
    }

    function repay(address user) external payable {
        borrowedAmount[user] -= msg.value;
        kodiaqRouter.addLiquidityBERA{value: msg.value}(path[1], 0, 0, msg.value, beraReserve, block.timestamp + 1);
    }

    function liquidate(address user, uint256 amount) external {
        uint256 liqAmount = amountEligibleForLiquidation(user);
        if (liqAmount == 0) revert("SBPool: User is solvent");
        // If amount is too large, chop it down to fully liq user
        if (amount >= liqAmount)
            amount = liqAmount;
        // Transfer in underlying
        ERC20(path[0]).safeTransferFrom(msg.sender, beraReserve, amount);
        uint256 liquidationReward = amount.fmul(1e18 + liqFeePercentage, FixedPointMathLib.WAD);
        // Reward user with amountUnderlying + incentive sb tokens
        allowance[from][msg.sender] = liquidationReward;
        // Override solvency safety checks because user is getting liquidated
        this.transferForLiquidation(user, msg.sender, liquidationReward);
    }

    /*///////////////////////////////////////////////////////////////
                            Manage Collateral
    //////////////////////////////////////////////////////////////*/

    function depositCollateral(uint256 user, uint256 collateral) public {
        // Pull tokens from user
        ERC20(path[0]).safeTransferFrom(msg.sender, beraReserve, collateral);
        // Mint sbTokens to the user
        _mint(msg.sender, collateral);
    }

    function withdrawlCollateral(uint256 amountToWithdraw) public {
        uint256 usedCollateral = kodiaqRouter.getQuote(borrowedAmount[msg.sender], path[1], path[0]);
        require(amountToWithdraw < usedCollateral, "SBPool: Withdrawing would make user insolvent");
        // Burn sbTokens
        _burn(msg.sender, amountToWithdraw);
        // Withdraw the underlying collateral to the user
        IBeraReserve(beraReserve).withdrawToken(path[0], msg.sender, amountToWithdraw);
    }

    function amountEligibleForLiquidation(address user) public view returns (uint256) {
        uint256 borrowed = borrowedAmount[user];
        uint256 collateralInBera = kodiaqRouter.getQuote(this.balanceOf(user), path[0], path[1]);
        if (collateralInBera >= borrowed) return 0;
        return borrowed - collateralInBera;
    }

    function isSolvent(address user) public view returns (bool) {
        return amountEligibleForLiquidation(user) == 0;
    }

    function transferForLiquidation(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        super.transferFrom(from, to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-20 Overrides
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        super.transfer(to, amount);
        require(isSolvent(msg.sender), "SBPool: User insolvent post-transfer");
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        super.transferFrom(from, to, amount);
        require(isSolvent(from), "SBPool: User insolvent post-transfer");
    }
}
