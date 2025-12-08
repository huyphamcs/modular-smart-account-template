// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IModule} from "../interfaces/IModule.sol";

/**
 * @title ModuleManager
 * @notice Manages ERC-7579 modules
 */
abstract contract ModuleManager {
    mapping(address => bool) public isModuleInstalled;

    event ModuleInstalled(address indexed module);
    event ModuleUninstalled(address indexed module);

    error ModuleAlreadyInstalled();
    error ModuleNotInstalled();

    function installModule(
        address module,
        bytes calldata data
    ) external virtual {
        if (isModuleInstalled[module]) revert ModuleAlreadyInstalled();

        isModuleInstalled[module] = true;
        IModule(module).onInstall(data);

        emit ModuleInstalled(module);
    }

    function uninstallModule(
        address module,
        bytes calldata data
    ) external virtual {
        if (!isModuleInstalled[module]) revert ModuleNotInstalled();

        isModuleInstalled[module] = false;
        IModule(module).onUninstall(data);

        emit ModuleUninstalled(module);
    }
}
