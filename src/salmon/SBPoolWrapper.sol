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

contract SBPoolWrapper is ERC20, BeraMixin {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using KodiaqLibrary for IKodiaqRouter;

    address[] path = new address[](2);
    IKodiaqRouter kodiaqRouter;
    IKodiaqFactory kodiaqFactory;
    address kodiaqPair;
    uint256 leverageFactor;
    address beraReserve;
    uint256 feePercentage = 2e16; // 2% fee for lending by default
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

    function borrow(
        uint256 amount,
        uint256 deadline
    ) public {
        // Calculate amounts and fees
        uint256 collateralToUse = kodiaqRouter.getQuote(amount, path[1], path[0]);
        uint256 amountAfterFees = amount - amount.fmul(feePercentage, FixedPointMathLib.WAD);
        uint256 feeAmount = collateralToUse.fmul(feePercentage, FixedPointMathLib.WAD);
        uint256 collateralToUseAfterFee = collateralToUse - feeAmount;
        borrowedAmount[msg.sender] += amountAfterFees;

        // Transfer fee to the reserves

        ERC20(this).safeTransfer(beraReserve, feeAmount);
        
        // Swap to get user BERA 
        kodiaqRouter.swapExactTokensForBERASupportingFeeOnTransferTokens(
            collateralToUseAfterFee,
            amountAfterFees,
            path,
            msg.sender,
            deadline
        );

        // Calculate how much LP is needed to bring balance of original Collateral back.
        uint256 lpToWithdraw = (collateralToUseAfterFee * (10**18 - uint256(ERC20(path[0]).decimals()))).fdiv(
            ERC20(kodiaqPair).totalSupply(),
            FixedPointMathLib.WAD
        );

        // Withdraw LP needed to execute the dex swaps
        IBeraReserve(beraReserve).withdrawToken(kodiaqPair, address(this), lpToWithdraw);

        // Restore Collateral balance
        kodiaqRouter.removeLiquidityBERASupportingFeeOnTransferTokens(
            path[0],
            lpToWithdraw,
            collateralToUseAfterFee,
            0,
            beraReserve,
            deadline
        );
    }

    function repay(address user, uint256 deadline) external payable {
        borrowedAmount[user] -= msg.value;
        // Restore Dex Niceness
        // TODO fix this up, if the price of BERA increased a lot, this function could fail.
        kodiaqRouter.addLiquidityBERA{value: msg.value}(path[1], 0, 0, msg.value, beraReserve, deadline);
    }

    function depositCollateral(uint256 user, uint256 collateral) public {
        // Pull tokens from user
        ERC20(path[0]).safeTransferFrom(msg.sender, beraReserve, collateral);
        // Mint sbTokens to the user
        _mint(msg.sender, collateral);
    }

    function withdrawlCollateral(uint256 amount) public {
        uint256 usedCollateral = kodiaqRouter.getQuote(borrowedAmount[msg.sender], path[1], path[0]);
        require(amount < usedCollateral, "SBPool: Withdrawing would make user insolvent");
        // Burn sbTokens
        _burn(msg.sender, amount);
        IBeraReserve(beraReserve).withdrawToken(path[0], msg.sender, amount);
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

    function liquidate(address user, uint256 amount) external {
        uint256 liqAmount = amountEligibleForLiquidation(user);
        if (liqAmount == 0) revert("SBPool: User is solvent");
        require (amount < liqAmount, "SBPool: User is not that insolvent");
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
