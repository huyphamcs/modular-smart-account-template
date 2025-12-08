// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Kernel} from "../src/Kernel.sol";
import {AccountFactory} from "../src/factory/AccountFactory.sol";
import {IEntryPoint} from "../src/interfaces/IEntryPoint.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying with address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // EntryPoint address (v0.7)
        IEntryPoint entryPoint = IEntryPoint(
            0x0000000071727De22E5E9d8BAf0edAc6f37da032
        );

        // Deploy factory
        AccountFactory factory = new AccountFactory(entryPoint);
        console2.log("AccountFactory deployed at:", address(factory));
        console2.log(
            "Account implementation at:",
            factory.accountImplementation()
        );

        // Optionally create an account
        bytes32 salt = keccak256(
            abi.encodePacked("my-account", block.timestamp)
        );
        address account = factory.createAccount(deployer, salt);
        console2.log("Account created at:", account);

        vm.stopBroadcast();
    }
}
