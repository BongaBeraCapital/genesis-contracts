// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

/* Package Imports */
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/* Local Imports */
import {ArrayLib} from "../utils/ArrayLib.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";

contract BeraValidatorRewards {
    using ArrayLib for uint256[];
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    address private immutable validatorAuthority;
    address private beraReserve;

    address[] private rewardPairs;

    constructor(address _validatorAuthority) {
        validatorAuthority = _validatorAuthority;
    }

    function distribute(address[] calldata validators, uint256[] calldata stakedAmounts) external {
        require(msg.sender == validatorAuthority, "BeraValidatorRewards: Only Validator");
        uint256 numValidators = validators.length;
        uint256 numPairs = rewardPairs.length;
        uint256 totalStaked = stakedAmounts.sum();

        for (uint256 i = 0; i < numPairs; i += 1) {
            ERC20 pair = ERC20(rewardPairs[i]);
            uint256 b = ERC20(pair).balanceOf(address(this));

            // 25 % To Reserves
            pair.approve(beraReserve, b / 4);
            IBeraReserve(beraReserve).depositToken(pair, b/4);
            b -= b / 4;
            
            // 75 % To Validators
            for (uint256 j = 0; j < numValidators; j += 1) {
                uint256 toSend = stakedAmounts[i].fdiv(b, FixedPointMathLib.WAD);
                pair.safeTransfer(validators[i], toSend);
            }
        }
    }
}
