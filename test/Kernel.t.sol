// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Kernel} from "../src/Kernel.sol";
import {AccountFactory} from "../src/factory/AccountFactory.sol";
import {IEntryPoint} from "../src/interfaces/IEntryPoint.sol";

contract KernelTest is Test {
    Kernel public account;
    AccountFactory public factory;
    IEntryPoint public entryPoint;

    address public owner;
    uint256 public ownerKey;

    function setUp() public {
        // Setup owner
        ownerKey = 0x1234;
        owner = vm.addr(ownerKey);

        // Deploy EntryPoint (mock for testing)
        entryPoint = IEntryPoint(
            address(0x0000000071727De22E5E9d8BAf0edAc6f37da032)
        );

        // Deploy factory
        factory = new AccountFactory(entryPoint);

        // Create account
        bytes32 salt = keccak256("test-account");
        address accountAddr = factory.createAccount(owner, salt);
        account = Kernel(payable(accountAddr));

        // Fund account
        vm.deal(address(account), 10 ether);
    }

    function test_Initialize() public {
        assertEq(account.owner(), owner);
        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function test_Execute() public {
        address target = address(0x123);
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(owner);
        // Send the money to the target
        account.execute(target, value, data);

        assertEq(target.balance, value);
    }

    function test_ExecuteBatch() public {
        address[] memory targets = new address[](2);
        targets[0] = address(0x123);
        targets[1] = address(0x456);

        uint256[] memory values = new uint256[](2);
        values[0] = 1 ether;
        values[1] = 2 ether;

        bytes[] memory datas = new bytes[](2);
        datas[0] = "";
        datas[1] = "";

        vm.prank(owner);
        account.executeBatch(targets, values, datas);

        assertEq(targets[0].balance, 1 ether);
        assertEq(targets[1].balance, 2 ether);
    }

    function test_TransferOwnership() public {
        address newOwner = address(0x789);

        vm.prank(owner);
        account.transferOwnership(newOwner);

        assertEq(account.owner(), newOwner);
    }

    function test_RevertWhen_UnauthorizedCaller() public {
        address unauthorized = address(0x999);

        vm.prank(unauthorized);
        vm.expectRevert(Kernel.InvalidCaller.selector);
        account.execute(address(0x123), 0, "");
    }

    function test_DeterministicAddress() public {
        bytes32 salt = keccak256("another-account");
        address predicted = factory.getAddress(owner, salt);
        address actual = factory.createAccount(owner, salt);

        assertEq(predicted, actual);
    }
}
