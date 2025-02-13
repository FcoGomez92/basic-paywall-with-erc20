# Basic Paywall with ERC20

A gas-optimized smart contract implementation for payment systems that grant access to content or services, such as paywalls or premium subscriptions. The system supports multiple ERC20 tokens and different subscription durations.


## Features

- Support for multiple ERC20 tokens
- Monthly and yearly subscription tiers
- Gas-optimized implementation
- Owner-controlled token and price management
- Secure withdrawal system
- Notice: This contract does not implement auto-renewable purchase logic.


## Project Structure

```
├── src/
│   └── BasicPaywallWithERC20.sol    # Main contract
├── script/
│   ├── mocks                
│       └── ERC20DecimalsMock.sol    # ERC20 mock contract with configurable decimals
│   ├── Deploy.s.sol                 # Deployment script
│   └── HelperConfig.s.sol           # Network configurations
├── test/
│   └── integration/                  
│       └── DeployTest.t.sol         # Integration test files
│   └── unit/                        
│       └── BasicPaywallTest.t.sol   # Unit test files
├── docs/
│   └── BasicPaywallWithERC20.md     # Smart Contract documentation
└── Makefile                         # Build and deployment commands
└── foundry.toml                     # Foundry config
```


## Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and see a response like `git version x.x.x`
- [Foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and see a response like `forge 0.2.0`
- [Make](https://www.gnu.org/software/make/)
  - You'll know you did it right if you can run `make --version` and see a response like `GNU Make 3.81`

### Installing Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```


## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/FcoGomez92/basic-paywall-with-erc20.git
cd basic-paywall-with-erc20
```

2. Install dependencies:
```bash
make all
```


## Development

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Format
```bash
forge fmt
```

### Gas Snapshots
```bash
forge snapshot
```

### Local Blockchain
```bash
make anvil
```


## Deployment

### Configure Deployer Account

1. Import your deployer wallet:
```bash
cast wallet import deployer --interactive
# Enter private key when prompted
# Enter password when prompted
```

2. Create a `.env` file:
```env
DEPLOYER_ADDRESS=<your-deployer-address>

SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
ARBITRUM_RPC_URL=<your-arbitrum-rpc-url>

ETHERSCAN_API_KEY=<your-etherscan-api-key>
ARBISCAN_API_KEY=<your-arbiscan-api-key>
```

3. Configure the owner address in `script/HelperConfig.s.sol`:
```solidity
address constant OWNER_ACCOUNT = <your-owner-address>; // Replace with actual owner address
```

### Deploy Commands

Local deployment:
```bash
make deploy
```

Sepolia testnet deployment:
```bash
make deploySepolia
```

Arbitrum mainnet deployment:
```bash
make deployArbitrum
```


## Contract Architecture

### BasicPaywallWithERC20.sol

The main contract implements a subscription-based paywall system with the following key features:

#### Core Functions
- `purchase(address _token, PurchaseDuration duration)`: Purchase a subscription
- `withdrawToken(address _token, uint256 _amount)`: Withdraw specific amount of tokens
- `withdrawAll()`: Withdraw all supported tokens
- `updatePrices(address token, uint256 _monthPrice, uint256 _yearPrice)`: Update subscription prices
- `addSupportedToken(address token, uint256 monthPrice, uint256 yearPrice)`: Add new supported token
- `removeSupportedToken(address token)`: Remove supported token

For detailed documentation of all functions, events, errors and more, see the [Contract Documentation](docs/contract.BasicPaywallWithERC20.md).

### Network Configurations

The `HelperConfig.s.sol` contract provides configurations for:
- Local development (Anvil)
- Ethereum Sepolia Testnet
- Arbitrum Mainnet

Each network configuration includes:
- USDC and USDT addresses
- Monthly and yearly prices for each token
- Owner address


## Adding Support for a New Chain

To add support for a new EVM-compatible chain, follow these steps:

1. Add the RPC URL to your `.env` file:
```env
NEW_CHAIN_RPC_URL=<your-new-chain-rpc-url>
```

2. Add the chain configuration to `foundry.toml`:
```toml
[rpc_endpoints]
new_chain = "${NEW_CHAIN_RPC_URL}"

[etherscan]
new_chain = { key = "${NEW_CHAIN_EXPLORER_API_KEY}" }
```

3. Create a new configuration function in `script/HelperConfig.s.sol`:
```solidity
function getNewChainConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        usdcAddress: <usdc-address-on-new-chain>,
        usdtAddress: <usdt-address-on-new-chain>,
        usdcMonthPrice: USDC_MONTH_PRICE,
        usdtMonthPrice: USDT_MONTH_PRICE,
        usdcYearPrice: USDC_YEAR_PRICE,
        usdtYearPrice: USDT_YEAR_PRICE,
        owner: OWNER_ACCOUNT
    });
}
```

4. Add the chain ID and configuration to the constructor in `script/HelperConfig.s.sol`:
```solidity
uint256 constant NEW_CHAIN_ID = <your-chain-id>;

constructor() {
    // ... existing configurations ...
    networkConfigs[NEW_CHAIN_ID] = getNewChainConfig();
}
```

5. Add a new deployment command to the `Makefile`:
```makefile
deployNewChain : 
	@forge script script/Deploy.s.sol:Deploy --rpc-url new_chain --sender ${DEPLOYER_ADDRESS} --account deployer --broadcast --verify -vvvv
```

Now you can deploy to the new chain using:
```bash
make deployNewChain
```


## License

This project is licensed under the MIT License.

## Author

Francisco Gómez
- X: [@FcoGomez92_](https://twitter.com/FcoGomez92_)
- GitHub: [FcoGomez92](https://github.com/FcoGomez92)