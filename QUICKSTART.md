# Starter Template - Quick Reference

## 📁 Location
`/Users/anderson/Workspace/kernel/starter-template/`

## 📦 What's Included

### Contracts (~240 lines total)
- ✅ **Kernel.sol** - ERC-4337 smart account
- ✅ **ModuleManager.sol** - ERC-7579 module support  
- ✅ **AccountFactory.sol** - CREATE2 deployment
- ✅ **Interfaces** - IAccount, IEntryPoint, IModule

### Testing & Deployment
- ✅ **Kernel.t.sol** - Complete test suite
- ✅ **Deploy.s.sol** - Deployment script
- ✅ **foundry.toml** - Foundry configuration

### Documentation
- ✅ **README.md** - Complete usage guide

## 🚀 Quick Start

```bash
cd starter-template

# Install dependencies
forge install
    
# Build
forge build

# Test
forge test -vv

# Deploy to Sepolia
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast
```

## 📝 File Structure

```
starter-template/
├── src/
│   ├── Kernel.sol
│   ├── core/
│   │   └── ModuleManager.sol
│   ├── factory/
│   │   └── AccountFactory.sol
│   └── interfaces/
│       ├── IAccount.sol
│       ├── IEntryPoint.sol
│       ├── IModule.sol
│       └── PackedUserOperation.sol
├── test/
│   └── SimpleAccount.t.sol
├── script/
│   └── Deploy.s.sol
├── foundry.toml
├── .env.example
├── .gitignore
└── README.md
```

## ✨ Features

- **Minimal** - Only ~240 lines of production code
- **Production-Ready** - Based on Kernel patterns
- **Tested** - Complete test coverage
- **Documented** - Comprehensive README
- **Extensible** - Module system for custom features

## 🔧 Next Steps

1. Copy `.env.example` to `.env` and add your keys
2. Run tests: `forge test`
3. Deploy to testnet
4. Build custom modules (see README.md)
5. Integrate with your application

See **README.md** for complete documentation!
