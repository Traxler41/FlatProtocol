// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract FlatCoin is ERC20, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address private s_engine;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event EngineUpdated(address indexed newEngine);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error FlatCoin__NotEngine();
    error FlatCoin__ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyEngine() {
        if (msg.sender != s_engine) revert FlatCoin__NotEngine();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("FlatCoin", "FC") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                        ENGINE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the engine contract that controls mint/burn
     * @dev Can only be set once or updated by owner (governance)
     */
    function setEngine(address engine) external onlyOwner {
        if (engine == address(0)) revert FlatCoin__ZeroAddress();

        s_engine = engine;
        emit EngineUpdated(engine);
    }

    function getEngine() external view returns (address) {
        return s_engine;
    }

    /*//////////////////////////////////////////////////////////////
                            CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint new FlatCoins
     * @dev Only callable by engine
     */
    function mint(address to, uint256 amount) external onlyEngine whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @notice Burn FlatCoins
     * @dev Only callable by engine
     */
    function burn(address from, uint256 amount) external onlyEngine whenNotPaused {
        _burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY CONTROLS
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Prevent transfers when paused
     */
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }
}
