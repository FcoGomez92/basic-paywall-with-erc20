// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20DecimalsMock} from "./mocks/ERC20DecimalsMock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    /**
    @dev Set with the preferred supported tokens. For simplicity, I'm using only USDC and USDT. 
     If you need to support more than two or three tokens, you can modify the struct and getter functions to accept arrays.
     Eg:
        address[] supportedTokenAddresses
        uint256[] monthPrices
        uint256[] yearPrices
    */
    struct NetworkConfig {
        address usdcAddress;
        address usdtAddress;
        uint256 usdcMonthPrice;
        uint256 usdtMonthPrice;
        uint256 usdcYearPrice;
        uint256 usdtYearPrice;
        address owner;
    }

    uint8 constant STABLE_COIN_DECIMALS = 6;
    uint256 constant USDC_MONTH_PRICE = 2e6;
    uint256 constant USDT_MONTH_PRICE = 4e6;
    uint256 constant USDC_YEAR_PRICE = 20e6;
    uint256 constant USDT_YEAR_PRICE = 40e6;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42161;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant OWNER_ACCOUNT = address(0); // IMPORTANT!!! Config with the actual owner address

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ARBITRUM_MAINNET_CHAIN_ID] = getArbMainnetConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateLocalConfig();
        } else if (networkConfigs[chainId].owner != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getOrCreateLocalConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.usdcAddress != address(0)) {
            return localNetworkConfig;
        }

        // deploy mocks
        console2.log("Deploying mocks...");
        vm.startBroadcast();
        ERC20DecimalsMock usdcMock = new ERC20DecimalsMock(
            "USDC",
            "USDC",
            STABLE_COIN_DECIMALS
        );
        ERC20DecimalsMock usdtMock = new ERC20DecimalsMock(
            "USDT",
            "USDT",
            STABLE_COIN_DECIMALS
        );
        vm.stopBroadcast();
        console2.log("Mocks deployed!");

        localNetworkConfig = NetworkConfig({
            usdcAddress: address(usdcMock),
            usdtAddress: address(usdtMock),
            usdcMonthPrice: USDC_MONTH_PRICE,
            usdtMonthPrice: USDT_MONTH_PRICE,
            usdcYearPrice: USDC_YEAR_PRICE,
            usdtYearPrice: USDT_YEAR_PRICE,
            owner: ANVIL_DEFAULT_ACCOUNT
        });

        return localNetworkConfig;
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                usdcAddress: 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8,
                usdtAddress: 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0,
                usdcMonthPrice: USDC_MONTH_PRICE,
                usdtMonthPrice: USDT_MONTH_PRICE,
                usdcYearPrice: USDC_YEAR_PRICE,
                usdtYearPrice: USDT_YEAR_PRICE,
                owner: OWNER_ACCOUNT
            });
    }

    function getArbMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                usdcAddress: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
                usdtAddress: 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
                usdcMonthPrice: USDC_MONTH_PRICE,
                usdtMonthPrice: USDT_MONTH_PRICE,
                usdcYearPrice: USDC_YEAR_PRICE,
                usdtYearPrice: USDT_YEAR_PRICE,
                owner: OWNER_ACCOUNT
            });
    }
}
