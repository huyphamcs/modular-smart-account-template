// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Kernel} from "../Kernel.sol";
import {IEntryPoint} from "../interfaces/IEntryPoint.sol";

/**
 * @title AccountFactory
 * @notice Deploys Kernel instances with CREATE2
 */
contract AccountFactory {
    IEntryPoint public immutable entryPoint;
    address public immutable accountImplementation;

    event AccountCreated(
        address indexed account,
        address indexed owner,
        bytes32 salt
    );

    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        accountImplementation = address(new Kernel(_entryPoint));
    }

    /**
     * @notice Create account with deterministic address
     */
    function createAccount(
        address owner,
        bytes32 salt
    ) external returns (address) {
        address account = getAddress(owner, salt);

        if (account.code.length > 0) {
            return account;
        }

        bytes memory code = _getProxyCode(accountImplementation);
        assembly {
            account := create2(0, add(code, 32), mload(code), salt)
        }

        Kernel(payable(account)).initialize(owner);

        emit AccountCreated(account, owner, salt);

        return account;
    }

    /**
     * @notice Get counterfactual address
     */
    function getAddress(
        address owner,
        bytes32 salt
    ) public view returns (address) {
        bytes memory code = _getProxyCode(accountImplementation);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code))
        );
        return address(uint160(uint256(hash)));
    }

    function _getProxyCode(
        address implementation
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf3"
            );
    }
}
