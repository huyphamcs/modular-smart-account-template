// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IEntryPoint {
    function getUserOpHash(
        PackedUserOperation calldata userOp
    ) external view returns (bytes32);
    function depositTo(address account) external payable;
    function withdrawTo(
        address payable withdrawAddress,
        uint256 withdrawAmount
    ) external;
}

struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
