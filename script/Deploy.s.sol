// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BasicPaywallWithERC20} from "src/BasicPaywallWithERC20.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract Deploy is Script {
    function run() public returns (HelperConfig, BasicPaywallWithERC20) {
        return deployBasicPaywall();
    }

    function deployBasicPaywall()
        public
        returns (HelperConfig, BasicPaywallWithERC20)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address[] memory supportedTokens = new address[](2);
        (supportedTokens[0], supportedTokens[1]) = (
            config.usdcAddress,
            config.usdtAddress
        );
        uint256[] memory monthPrices = new uint256[](2);
        (monthPrices[0], monthPrices[1]) = (
            config.usdcMonthPrice,
            config.usdtMonthPrice
        );
        uint256[] memory yearPrices = new uint256[](2);
        (yearPrices[0], yearPrices[1]) = (
            config.usdcYearPrice,
            config.usdtYearPrice
        );

        vm.startBroadcast();
        BasicPaywallWithERC20 basicPaywallWithERC20 = new BasicPaywallWithERC20(
            supportedTokens,
            monthPrices,
            yearPrices
        );
        // For security, I use a separate account just for deploying contracts and instantly transfer ownership to the actual owner.
        basicPaywallWithERC20.transferOwnership(config.owner);
        vm.stopBroadcast();
        return (helperConfig, basicPaywallWithERC20);
    }
}
