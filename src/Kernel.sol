// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IAccount} from "./interfaces/IAccount.sol";
import {IEntryPoint} from "./interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "./interfaces/PackedUserOperation.sol";
import {ModuleManager} from "./core/ModuleManager.sol";

/**
 * @title Kernel
 * @notice Minimal ERC-4337 smart account with ERC-7579 module support
 * @dev Starting point for all custom account implementations
 */
contract Kernel is IAccount, ModuleManager {
    IEntryPoint public immutable entryPoint;
    address public owner;

    error OnlyEntryPoint();
    error OnlyOwner();
    error InvalidCaller();
    error AlreadyInitialized();
    error ExecutionFailed();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) revert OnlyEntryPoint();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
    }

    /**
     * @notice Initialize account with owner
     * @dev Called once during deployment
     */
    function initialize(address _owner) external {
        if (owner != address(0)) revert AlreadyInitialized();
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @notice Validate user operation
     * @dev Called by EntryPoint during validation phase
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);

        if (missingAccountFunds > 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds
            }("");
            require(success, "Payment failed");
        }
    }

    /**
     * @notice Execute single transaction
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory result) {
        if (msg.sender != address(entryPoint) && msg.sender != owner) {
            revert InvalidCaller();
        }

        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * @notice Execute batch of transactions
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external {
        if (msg.sender != address(entryPoint) && msg.sender != owner) {
            revert InvalidCaller();
        }

        require(
            targets.length == values.length && values.length == datas.length,
            "Length mismatch"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call{
                value: values[i]
            }(datas[i]);
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }
    }

    /**
     * @notice Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Validate signature
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view virtual returns (uint256) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash)
        );
        address signer = _recover(hash, userOp.signature);

        if (signer != owner) {
            return 1; // SIG_VALIDATION_FAILED
        }
        return 0; // SIG_VALIDATION_SUCCESS
    }

    function _recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) return address(0);

        return ecrecover(hash, v, r, s);
    }

    receive() external payable {}
}
