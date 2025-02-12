// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BasicPaywallWithERC20} from "src/BasicPaywallWithERC20.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Deploy} from "script/Deploy.s.sol";

contract DeployTest is Test {
    BasicPaywallWithERC20 basicPaywallWithERC20;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    uint256 constant USDC_MONTH_PRICE = 2e6;
    uint256 constant USDT_MONTH_PRICE = 4e6;
    uint256 constant USDC_YEAR_PRICE = 20e6;
    uint256 constant USDT_YEAR_PRICE = 40e6;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        Deploy deploy = new Deploy();
        (helperConfig, basicPaywallWithERC20) = deploy.run();
        config = helperConfig.getConfig();
    }

    function testOwnerIsSettedCorrectly() public {
        address owner = basicPaywallWithERC20.owner();

        assertEq(owner, ANVIL_DEFAULT_ACCOUNT);
    }

    function testDeployScriptSetTheSupportedTokensCorrectly() public {
        address[] memory supportedTokens = basicPaywallWithERC20
            .getSupportedTokens();

        vm.assertEq(supportedTokens.length, 2);
        vm.assertEq(supportedTokens[0], config.usdcAddress);
        vm.assertEq(supportedTokens[1], config.usdtAddress);
    }

    function testDeployScriptSetThePricesCorrectly() public {
        (uint256 usdcMonthPrice, uint256 usdcYearPrice) = basicPaywallWithERC20
            .getPriceByToken(config.usdcAddress);
        (uint256 usdtMonthPrice, uint256 usdtYearPrice) = basicPaywallWithERC20
            .getPriceByToken(config.usdtAddress);

        vm.assertEq(usdcMonthPrice, USDC_MONTH_PRICE);
        vm.assertEq(usdcYearPrice, USDC_YEAR_PRICE);
        vm.assertEq(usdtMonthPrice, USDT_MONTH_PRICE);
        vm.assertEq(usdtYearPrice, USDT_YEAR_PRICE);
    }
}
