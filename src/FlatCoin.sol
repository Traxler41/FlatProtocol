//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract FlatCoin is ERC20, Ownable, Pausable {
    address immutable i_owner;

    mapping(address => uint256) s_tokenHolders;

    constructor() ERC20("FlatCoin", "FC") Ownable(msg.sender) {
        i_owner = msg.sender;
    }

    /**
     *
     * @param _minter Address that wants to mint FlatCoin
     * @param _amount Amount of FlatCoin to be minted
     */
    function mint(address _minter, uint256 _amount) external whenNotPaused {
        _mint(_minter, _amount);
    }

    /**
     *
     * @param _burner Address that wants to burn FlatCoin
     * @param _amount Amount of FlatCoin to be burnt
     */
    function burn(address _burner, uint256 _amount) external {
        _burn(_burner, _amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value) internal override(ERC20) whenNotPaused {
        super._update(from, to, value);
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    /**
     *
     * @param _staker Address of staker
     */
    function getTokenHolderAmount(address _staker) public view returns (uint256) {
        return s_tokenHolders[_staker];
    }
}
