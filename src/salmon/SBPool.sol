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

contract SBPool is BeraMixin {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using KodiaqLibrary for IKodiaqRouter;
    IKodiaqRouter kodiaqRouter;
    IKodiaqFactory kodiaqFactory;
    address kodiaqPair;
    uint256 leverageFactor;
    address beraReserve;
    uint256 feePercentage = 2e16; // 2% fee for lending by default
    mapping(address => uint256) borrowedAmount;


    constructor(address _storageAddress, address _kodiaqRouter, address _kodiaqFactory, uint256 _leverageFactor, address token, uint256 _feePercentage) BeraMixin(_storageAddress) {
        version = 1;
        leverageFactor = _leverageFactor;
        feePercentage = _feePercentage;
        kodiaqFactory = IKodiaqFactory(_kodiaqFactory);
        kodiaqRouter = IKodiaqRouter(_kodiaqRouter);
        kodiaqPair = kodiaqFactory.getPair(token, kodiaqRouter.WBERA());
    }

    function borrow(address _token, uint256 amount, uint256 deadline) external {
        ERC20 token = ERC20(_token);
        address wbera = kodiaqRouter.WBERA();
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 valueLoanable = amount.fmul(leverageFactor, FixedPointMathLib.WAD); // i.e 33% means 
        uint256 beraBorrowed = kodiaqRouter.getQuote(valueLoanable, _token, wbera);
        borrowedAmount[msg.sender] += beraBorrowed;
        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = address(token);
        path[1] = wbera;
        uint256 feeAmount = valueLoanable.fmul(feePercentage, FixedPointMathLib.WAD);
        token.safeTransfer(beraReserve, feeAmount);
        kodiaqRouter.swapExactTokensForBERASupportingFeeOnTransferTokens(valueLoanable-feeAmount, 0, path, msg.sender, deadline);
        IBeraReserve(beraReserve).withdrawToken(kodiaqPair, address(this), 1);
        uint256 totalLpSupply = ERC20(kodiaqPair).totalSupply();
        uint256 amountToWithdraw = valueLoanable * (10**18 - uint256(token.decimals())).fdiv(totalLpSupply, FixedPointMathLib.WAD);
        kodiaqRouter.removeLiquidityBERASupportingFeeOnTransferTokens(_token, amountToWithdraw, valueLoanable, 0, address(this), deadline);
    }  

    function repay(ERC20 token, uint256 amount, uint256 deadline) external {
        // borrowedAmount[msg.sender] += beraBorrowed;
    }

    function isSolvent(address user) external {
    }

    function liquidate(address user) external {

    }
}