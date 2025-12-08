## Foundry

- ├── src/
│   ├── Kernel.sol          # Main account contract
│   ├── core/
│   │   └── ModuleManager.sol       # Module management
│   └── factory/AccountFactory.sol  # CREATE2 deployment with deterministic addresses
- Complete interfaces (IAccount, IEntryPoint, IModule)

**Testing & Deployment**
- `Kernel.t.sol` - 7 comprehensive tests
- `Deploy.s.sol` - Production deployment script
- `foundry.toml` - Configured for Sepolia/Mainneteracting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

#### Single Transaction

```solidity
Kernel account = Kernel(payable(ACCOUNT_ADDRESS));

// As owner
account.execute(ript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
