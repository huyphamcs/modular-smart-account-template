# ERC-4337 Smart Account Starter Template

A minimal, production-ready starter template for building ERC-4337 smart accounts with ERC-7579 module support. This template provides a solid foundation for creating custom smart account implementations.

## 📦 What's Included

This template contains everything you need to start building smart account applications:

### Core Contracts (~240 lines)
```
src/
├── Kernel.sol                    # Main ERC-4337 smart account contract
├── core/
│   └── ModuleManager.sol         # ERC-7579 module management system
├── factory/
│   └── AccountFactory.sol        # CREATE2 deterministic deployment
└── interfaces/
    ├── IAccount.sol              # ERC-4337 account interface
    ├── IEntryPoint.sol           # EntryPoint interface
    ├── IModule.sol               # ERC-7579 module interface
    └── PackedUserOperation.sol   # UserOperation structure
```

### Testing & Deployment
- **`test/Kernel.t.sol`** - Comprehensive test suite with 6 test cases
- **`script/Deploy.s.sol`** - Production deployment script
- **`foundry.toml`** - Pre-configured for Sepolia and Mainnet

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of ERC-4337 and smart accounts

### Installation

```bash
# Clone or use this template
cd starter-template

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test -vv
```

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Add your configuration
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 🎯 What This Template Can Do

### 1. **Smart Account Functionality**
- ✅ **ERC-4337 Compliance** - Full support for account abstraction
- ✅ **Owner-based Validation** - ECDSA signature validation
- ✅ **Single Transactions** - Execute individual transactions
- ✅ **Batch Transactions** - Execute multiple transactions in one UserOp
- ✅ **Ownership Transfer** - Transfer account control to new owner
- ✅ **Gas Sponsorship Ready** - Compatible with paymasters

### 2. **Module System (ERC-7579)**
- ✅ **Install Modules** - Add custom functionality via modules
- ✅ **Uninstall Modules** - Remove modules when no longer needed
- ✅ **Module Lifecycle** - Proper `onInstall` and `onUninstall` hooks
- ✅ **Extensible Architecture** - Build validators, executors, hooks, and more

### 3. **Deterministic Deployment**
- ✅ **CREATE2 Factory** - Predictable account addresses
- ✅ **Counterfactual Addresses** - Know address before deployment
- ✅ **Salt-based Creation** - Custom salts for unique addresses

## 🏭 Production Usage

### Deploying to Testnet (Sepolia)

```bash
# Deploy factory and create first account
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# The script will output:
# - Factory address
# - Account implementation address
# - Your first account address
```

### Deploying to Mainnet

```bash
# Same command, different RPC
forge script script/Deploy.s.sol \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --slow  # Add delay between transactions
```

### Creating Additional Accounts

```solidity
// In your application
AccountFactory factory = AccountFactory(FACTORY_ADDRESS);

// Create account with custom salt
bytes32 salt = keccak256(abi.encodePacked("user-", userId));
address account = factory.createAccount(ownerAddress, salt);

// Get address before deployment (counterfactual)
address predictedAddress = factory.getAddress(ownerAddress, salt);
```

### Using Accounts in Production

```solidity
Kernel account = Kernel(payable(accountAddress));

// Single transaction
account.execute(
    targetContract,
    0,  // value in wei
    abi.encodeWithSignature("someFunction(uint256)", 123)
);

// Batch transactions (gas efficient!)
address[] memory targets = new address[](3);
uint256[] memory values = new uint256[](3);
bytes[] memory datas = new bytes[](3);

targets[0] = tokenContract;
datas[0] = abi.encodeWithSignature("approve(address,uint256)", spender, amount);

targets[1] = dexContract;
datas[1] = abi.encodeWithSignature("swap(address,address,uint256)", tokenA, tokenB, amount);

targets[2] = stakingContract;
datas[2] = abi.encodeWithSignature("stake(uint256)", amount);

account.executeBatch(targets, values, datas);
```

## 🔧 Development Guide

### Building Custom Features

#### 1. **Creating Custom Validators**

Validators control who can authorize transactions. Examples: multi-sig, biometrics, session keys.

**Files to create:**
```
src/modules/validators/
└── MyCustomValidator.sol
```

**Implementation:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IModule} from "../../interfaces/IModule.sol";
import {PackedUserOperation} from "../../interfaces/PackedUserOperation.sol";

contract MyCustomValidator is IModule {
    // Storage for validator state
    mapping(address => bytes) public validatorData;

    function onInstall(bytes calldata data) external override {
        // Initialize validator for this account
        validatorData[msg.sender] = data;
    }

    function onUninstall(bytes calldata data) external override {
        // Cleanup validator state
        delete validatorData[msg.sender];
    }

    function isModuleType(uint256 typeId) external pure returns (bool) {
        return typeId == 1; // TYPE_VALIDATOR
    }

    function isInitialized(address account) external view returns (bool) {
        return validatorData[account].length > 0;
    }

    // Custom validation logic
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external view returns (uint256 validationData) {
        // Your custom validation logic here
        // Return 0 for success, 1 for failure
    }
}
```

**Files to adjust:**
- `src/Kernel.sol` - Modify `_validateSignature` to support pluggable validators
- `test/MyCustomValidator.t.sol` - Add comprehensive tests

#### 2. **Creating Custom Executors**

Executors enable specific addresses/contracts to execute transactions with limited permissions.

**Files to create:**
```
src/modules/executors/
└── SessionKeyExecutor.sol
```

**Implementation:**
```solidity
contract SessionKeyExecutor is IModule {
    struct SessionKey {
        address key;
        uint48 validUntil;
        uint48 validAfter;
    }

    mapping(address => mapping(address => SessionKey)) public sessionKeys;

    function onInstall(bytes calldata data) external override {
        (address key, uint48 validUntil, uint48 validAfter) = 
            abi.decode(data, (address, uint48, uint48));
        
        sessionKeys[msg.sender][key] = SessionKey(key, validUntil, validAfter);
    }

    function onUninstall(bytes calldata data) external override {
        address key = abi.decode(data, (address));
        delete sessionKeys[msg.sender][key];
    }

    function isModuleType(uint256 typeId) external pure returns (bool) {
        return typeId == 2; // TYPE_EXECUTOR
    }

    function isInitialized(address account) external view returns (bool) {
        // Check if any session keys exist
        return true; // Implement proper check
    }

    function executeViaExecutor(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory) {
        SessionKey memory session = sessionKeys[msg.sender][tx.origin];
        require(block.timestamp >= session.validAfter, "Too early");
        require(block.timestamp <= session.validUntil, "Expired");
        
        // Execute the transaction
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "Execution failed");
        return result;
    }
}
```

**Files to adjust:**
- `src/Kernel.sol` - Add executor support in `execute` function
- `test/SessionKeyExecutor.t.sol` - Test session key functionality

#### 3. **Creating Custom Hooks**

Hooks run before/after transactions for additional checks or actions.

**Files to create:**
```
src/modules/hooks/
└── SpendingLimitHook.sol
```

**Implementation:**
```solidity
contract SpendingLimitHook is IModule {
    struct Limit {
        uint256 limit;
        uint256 spent;
        uint48 resetTime;
    }

    mapping(address => Limit) public limits;

    function onInstall(bytes calldata data) external override {
        uint256 dailyLimit = abi.decode(data, (uint256));
        limits[msg.sender] = Limit({
            limit: dailyLimit,
            spent: 0,
            resetTime: uint48(block.timestamp + 1 days)
        });
    }

    function onUninstall(bytes calldata) external override {
        delete limits[msg.sender];
    }

    function isModuleType(uint256 typeId) external pure returns (bool) {
        return typeId == 4; // TYPE_HOOK
    }

    function isInitialized(address account) external view returns (bool) {
        return limits[account].limit > 0;
    }

    function preCheck(
        address account,
        uint256 value
    ) external returns (bool) {
        Limit storage limit = limits[account];
        
        // Reset if period expired
        if (block.timestamp >= limit.resetTime) {
            limit.spent = 0;
            limit.resetTime = uint48(block.timestamp + 1 days);
        }
        
        // Check limit
        require(limit.spent + value <= limit.limit, "Spending limit exceeded");
        limit.spent += value;
        
        return true;
    }
}
```

**Files to adjust:**
- `src/core/ModuleManager.sol` - Add hook execution in module manager
- `src/Kernel.sol` - Call hooks in `execute` and `executeBatch`
- `test/SpendingLimitHook.t.sol` - Test spending limits

#### 4. **Creating Fallback Handlers**

Fallback handlers add custom functions to your account.

**Files to create:**
```
src/modules/fallback/
└── TokenReceiverFallback.sol
```

**Implementation:**
```solidity
contract TokenReceiverFallback is IModule {
    event TokenReceived(address token, address from, uint256 amount);

    function onInstall(bytes calldata) external override {}
    function onUninstall(bytes calldata) external override {}

    function isModuleType(uint256 typeId) external pure returns (bool) {
        return typeId == 3; // TYPE_FALLBACK
    }

    function isInitialized(address) external pure returns (bool) {
        return true;
    }

    // ERC721 receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        emit TokenReceived(msg.sender, from, tokenId);
        return this.onERC721Received.selector;
    }

    // ERC1155 receiver
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata
    ) external returns (bytes4) {
        emit TokenReceived(msg.sender, from, amount);
        return this.onERC1155Received.selector;
    }
}
```

**Files to adjust:**
- `src/Kernel.sol` - Add `fallback()` function to delegate to fallback handlers
- `test/TokenReceiverFallback.t.sol` - Test token receiving

### Testing Your Features

```bash
# Run all tests
forge test -vv

# Run specific test file
forge test --match-path test/MyCustomValidator.t.sol -vvv

# Run specific test function
forge test --match-test test_ValidatorInstallation -vvvv

# Generate gas report
forge test --gas-report

# Generate coverage report
forge coverage
```

### Example Test Structure

```solidity
// test/MyCustomValidator.t.sol
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {Kernel} from "../src/Kernel.sol";
import {MyCustomValidator} from "../src/modules/validators/MyCustomValidator.sol";

contract MyCustomValidatorTest is Test {
    Kernel account;
    MyCustomValidator validator;

    function setUp() public {
        // Deploy contracts
        validator = new MyCustomValidator();
        // ... setup account
    }

    function test_InstallValidator() public {
        bytes memory data = abi.encode(/* validator config */);
        account.installModule(address(validator), data);
        
        assertTrue(account.isModuleInstalled(address(validator)));
    }

    function test_ValidateUserOp() public {
        // Test validation logic
    }

    function test_UninstallValidator() public {
        // Test uninstallation
    }
}
```

## 📚 Architecture Overview

### Contract Inheritance

```
Kernel (Main Account)
  └── implements IAccount (ERC-4337)
  └── extends ModuleManager (ERC-7579)
```

### Module Types

| Type | ID | Purpose | Examples |
|------|----|---------| ---------|
| Validator | 1 | Validate transactions | ECDSA, Multi-sig, Passkey |
| Executor | 2 | Execute with permissions | Session keys, Automation |
| Fallback | 3 | Handle unknown calls | Token receivers, Custom functions |
| Hook | 4 | Pre/post execution checks | Spending limits, Allowlists |

### Key Design Patterns

1. **Minimal Core** - Keep `Kernel.sol` simple, extend via modules
2. **Module Lifecycle** - All modules implement `onInstall`/`onUninstall`
3. **Gas Optimization** - Batch transactions, efficient storage
4. **Upgradeability** - Use modules instead of upgrading core contract

## 🔐 Security Considerations

### Before Production

- [ ] **Audit your custom modules** - Security review is critical
- [ ] **Test extensively** - Unit tests, integration tests, fuzzing
- [ ] **Gas optimization** - Profile and optimize hot paths
- [ ] **Access control** - Verify only authorized callers
- [ ] **Reentrancy protection** - Use checks-effects-interactions
- [ ] **Integer overflow** - Use Solidity 0.8+ built-in checks

### Best Practices

```solidity
// ✅ Good: Check before state change
function execute(address target, uint256 value, bytes calldata data) external {
    require(msg.sender == owner || msg.sender == address(entryPoint));
    // ... execute
}

// ❌ Bad: State change before check
function execute(address target, uint256 value, bytes calldata data) external {
    // ... execute
    require(msg.sender == owner);  // Too late!
}
```

## 🛠️ Foundry Commands Reference

### Build
```bash
forge build                          # Compile contracts
forge build --sizes                  # Show contract sizes
forge build --force                  # Force recompilation
```

### Test
```bash
forge test                           # Run all tests
forge test -vv                       # Verbose (show logs)
forge test -vvvv                     # Very verbose (show traces)
forge test --gas-report              # Show gas usage
forge test --match-contract MyTest   # Run specific contract
forge test --match-test testName     # Run specific test
forge coverage                       # Generate coverage report
```

### Deploy
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

### Interact
```bash
# Call view function
cast call $ACCOUNT "owner()" --rpc-url sepolia

# Send transaction
cast send $ACCOUNT "execute(address,uint256,bytes)" $TARGET 0 0x --rpc-url sepolia --private-key $PRIVATE_KEY

# Get account balance
cast balance $ACCOUNT --rpc-url sepolia
```

## 📖 Additional Resources

### Documentation
- [ERC-4337 Specification](https://eips.ethereum.org/EIPS/eip-4337)
- [ERC-7579 Specification](https://eips.ethereum.org/EIPS/eip-7579)
- [Foundry Book](https://book.getfoundry.sh/)
- [Account Abstraction Docs](https://docs.alchemy.com/docs/account-abstraction-overview)

### Example Implementations
- [ZeroDev Kernel](https://github.com/zerodevapp/kernel) - Production-grade reference
- See `DEVELOPMENT_JOURNEY.md` for detailed evolution from starter to production

### Community
- [ERC-4337 Discord](https://discord.gg/account-abstraction)
- [Foundry Telegram](https://t.me/foundry_rs)

## 🤝 Contributing

Contributions are welcome! This template is designed to be:
- **Minimal** - Easy to understand and extend
- **Educational** - Well-commented and documented
- **Production-ready** - Battle-tested patterns

## 📄 License

MIT License - see LICENSE file for details

---

**Ready to build?** Start by exploring the code, running tests, and creating your first custom module! 🚀
