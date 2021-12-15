pragma solidity 0.8.10;
// SPDX-License-Identifier: AGPL-3.0-only

/* Package Imports */

import {ERC20} from "bera-solmate/tokens/ERC20.sol";

interface ISBPool {
    function withinLeverageFactor(address user) external view returns(bool);
}
contract SBERC20 is ERC20 {
    ERC20 public underlying;
    ISBPool sbPool;
    constructor(address _sbPool, address _underlying) ERC20("", "", ERC20(_underlying).decimals()) {
        underlying = ERC20(_underlying);
        sbPool = ISBPool(_sbPool);
        name = string(abi.encodePacked("Salmon Brothers ", underlying.name()));
        symbol = string(abi.encodePacked("sb", underlying.symbol()));
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-20 Overrides
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external {
        require(msg.sender == address(sbPool), "SBERC20: Sender must be the SBPool");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external  {
        require(msg.sender == address(sbPool), "SBERC20: Sender must be the SBPool");
        _burn(from, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        super.transfer(to, amount);
        require(sbPool.withinLeverageFactor(msg.sender), "SBPool: User outside of leverage limits post-transfer");
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (msg.sender == address(sbPool)) {
            allowance[from][msg.sender] = amount;
        }
        super.transferFrom(from, to, amount);
        require(msg.sender == address(sbPool) || sbPool.withinLeverageFactor(from), "SBPool: User outside of leverage limits post-transfer");
    }
}
