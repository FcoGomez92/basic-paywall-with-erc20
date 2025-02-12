// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BasicPaywallWithERC20} from "src/BasicPaywallWithERC20.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20DecimalsMock} from "script/mocks/ERC20DecimalsMock.sol";

contract BasicPaywallTest is Test {
    BasicPaywallWithERC20 basicPaywallWithERC20;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant SECONDS_PER_MONTH = 30 days;
    uint256 constant SECONDS_PER_YEAR = 365 days;
    address constant DEFAULT_FOUNDRY_ACCOUNT =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    uint256 constant USDC_MONTH_PRICE = 2e6;
    uint256 constant USDT_MONTH_PRICE = 4e6;
    uint256 constant USDC_YEAR_PRICE = 20e6;
    uint256 constant USDT_YEAR_PRICE = 40e6;
    uint256 constant USER_INITIAL_BALANCE = 1000e6;

    event NewPaidUser(
        address indexed user,
        address indexed token,
        bool indexed isYearlyPurchase,
        uint256 endTimestamp
    );
    event Withdraw(uint256 indexed amount, address indexed token);
    event TokenAdded(
        address indexed token,
        uint256 monthPrice,
        uint256 yearPrice
    );
    event TokenRemoved(address indexed token);
    event PricesUpdated(
        address indexed token,
        uint256 monthPrice,
        uint256 yearPrice
    );

    function setUp() public {
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();
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

        basicPaywallWithERC20 = new BasicPaywallWithERC20(
            supportedTokens,
            monthPrices,
            yearPrices
        );

        // Give some stablecoins to the users
        ERC20DecimalsMock(config.usdcAddress).mint(alice, USER_INITIAL_BALANCE);
        ERC20DecimalsMock(config.usdtAddress).mint(bob, USER_INITIAL_BALANCE);
    }

    /*
     * ============================
     * =    CONSTRUCTOR TESTS     =
     * ============================
     */

    function testConstructorRevertIfTokenAndPricesArraysLengthMismatch()
        public
    {
        address[] memory supportedTokens = new address[](2);
        uint256[] memory monthPrices = new uint256[](1);
        uint256[] memory yearPrices = new uint256[](1);

        (supportedTokens[0], supportedTokens[1]) = (
            config.usdcAddress,
            config.usdtAddress
        );
        monthPrices[0] = config.usdcMonthPrice;
        yearPrices[0] = config.usdcYearPrice;

        vm.expectRevert(
            BasicPaywallWithERC20
                .BasicPaywallWithERC20__MismatchInTokenAndPricesArrayLength
                .selector
        );
        new BasicPaywallWithERC20(supportedTokens, monthPrices, yearPrices);
    }

    function testConstructorRevertIfPricesArraysLengthMismatch() public {
        address[] memory supportedTokens = new address[](1);
        uint256[] memory monthPrices = new uint256[](1);
        uint256[] memory yearPrices = new uint256[](2);

        supportedTokens[0] = config.usdcAddress;
        monthPrices[0] = config.usdcMonthPrice;
        (yearPrices[0], yearPrices[1]) = (
            config.usdcYearPrice,
            config.usdtYearPrice
        );

        vm.expectRevert(
            BasicPaywallWithERC20
                .BasicPaywallWithERC20__MismatchInPricesArrayLength
                .selector
        );
        new BasicPaywallWithERC20(supportedTokens, monthPrices, yearPrices);
    }

    function testConstructorSetTheSupportedTokensCorrectly() public view {
        address[] memory supportedTokens = basicPaywallWithERC20
            .getSupportedTokens();

        vm.assertEq(supportedTokens.length, 2);
        vm.assertEq(supportedTokens[0], config.usdcAddress);
        vm.assertEq(supportedTokens[1], config.usdtAddress);
    }

    function testConstructorSetThePricesCorrectly() public view {
        (uint256 usdcMonthPrice, uint256 usdcYearPrice) = basicPaywallWithERC20
            .getPriceByToken(config.usdcAddress);
        (uint256 usdtMonthPrice, uint256 usdtYearPrice) = basicPaywallWithERC20
            .getPriceByToken(config.usdtAddress);

        vm.assertEq(usdcMonthPrice, USDC_MONTH_PRICE);
        vm.assertEq(usdcYearPrice, USDC_YEAR_PRICE);
        vm.assertEq(usdtMonthPrice, USDT_MONTH_PRICE);
        vm.assertEq(usdtYearPrice, USDT_YEAR_PRICE);
    }

    /*
     * ============================
     * =      PURCHASE TESTS      =
     * ============================
     */

    function testRevertIfPurchaseDurationIsInvalid() public {
        vm.startPrank(alice);
        vm.expectRevert();
        basicPaywallWithERC20.purchase(
            config.usdcAddress,
            BasicPaywallWithERC20.PurchaseDuration(uint(2))
        );
        vm.stopPrank();
    }

    function testRevertIfTransferFromFails() public {
        vm.startPrank(alice);
        vm.expectRevert();
        basicPaywallWithERC20.purchase(
            config.usdcAddress,
            BasicPaywallWithERC20.PurchaseDuration(0)
        );
        vm.stopPrank();
    }

    function testUserCanPurchaseCorrectly() public {
        ERC20DecimalsMock usdc = ERC20DecimalsMock(config.usdcAddress);
        uint256 aliceInitialBalance = usdc.balanceOf(alice);
        uint256 paywallInitialBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        );

        vm.startPrank(alice);
        usdc.approve(address(basicPaywallWithERC20), USDC_MONTH_PRICE);
        basicPaywallWithERC20.purchase(
            config.usdcAddress,
            BasicPaywallWithERC20.PurchaseDuration(0)
        );
        vm.stopPrank();

        uint256 aliceFinalBalance = usdc.balanceOf(alice);
        uint256 paywallFinalBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        );

        vm.assertEq(aliceFinalBalance, aliceInitialBalance - USDC_MONTH_PRICE);
        vm.assertEq(
            paywallFinalBalance,
            paywallInitialBalance + USDC_MONTH_PRICE
        );
    }

    /*
     * ============================
     * =  OWNER MANAGEMENT TESTS  =
     * ============================
     */
    function testOwnerCanUpdatePricesForASupportedToken() public {
        uint256 newMonthPrice = 3e6;
        uint256 newYearPrice = 30e6;

        basicPaywallWithERC20.updatePrices(
            config.usdcAddress,
            newMonthPrice,
            newYearPrice
        );

        (uint256 monthPrice, uint256 yearPrice) = basicPaywallWithERC20
            .getPriceByToken(config.usdcAddress);

        vm.assertEq(monthPrice, newMonthPrice);
        vm.assertEq(yearPrice, newYearPrice);
    }

    function testRevertIfTheTokenIsNotSupported() public {
        address notSupportedToken = makeAddr("not_supported");
        vm.expectRevert(
            abi.encodeWithSelector(
                BasicPaywallWithERC20
                    .BasicPaywallWithERC20__TokenNotSupported
                    .selector,
                notSupportedToken
            )
        );
        basicPaywallWithERC20.updatePrices(
            notSupportedToken,
            USDC_MONTH_PRICE,
            USDC_YEAR_PRICE
        );
    }

    function testRevertIfZeroAddressIsProvided() public {
        vm.expectRevert(
            BasicPaywallWithERC20.BasicPaywallWithERC20__ZeroAddress.selector
        );
        basicPaywallWithERC20.addSupportedToken(
            address(0),
            USDC_MONTH_PRICE,
            USDC_YEAR_PRICE
        );
    }

    function testOwnerCanAddNewSupportedToken() public {
        address newToken = makeAddr("new_token");
        uint256 newTokenMonthPrice = 3e6;
        uint256 newTokenYearPrice = 30e6;
        uint256 previousSupportedTokensLength = basicPaywallWithERC20
            .getSupportedTokens()
            .length;

        basicPaywallWithERC20.addSupportedToken(
            newToken,
            newTokenMonthPrice,
            newTokenYearPrice
        );

        (uint256 monthPrice, uint256 yearPrice) = basicPaywallWithERC20
            .getPriceByToken(newToken);
        uint256 currentSupportedTokensLength = basicPaywallWithERC20
            .getSupportedTokens()
            .length;

        vm.assertEq(
            previousSupportedTokensLength + 1,
            currentSupportedTokensLength
        );
        vm.assertEq(monthPrice, newTokenMonthPrice);
        vm.assertEq(yearPrice, newTokenYearPrice);
    }

    function testOwnerCanRemoveATokenFromSupportedTokenList() public {
        address tokenToRemove = config.usdcAddress;
        uint256 previousSupportedTokensLength = basicPaywallWithERC20
            .getSupportedTokens()
            .length;

        basicPaywallWithERC20.removeSupportedToken(tokenToRemove);

        uint256 currentSupportedTokensLength = basicPaywallWithERC20
            .getSupportedTokens()
            .length;

        vm.assertEq(
            previousSupportedTokensLength - 1,
            currentSupportedTokensLength
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                BasicPaywallWithERC20
                    .BasicPaywallWithERC20__TokenNotSupported
                    .selector,
                tokenToRemove
            )
        );
        basicPaywallWithERC20.getPriceByToken(tokenToRemove);
    }

    /*
     * ============================
     * =     WITHDRAWALS TESTS    =
     * ============================
     */

    modifier usersHavePurchased() {
        vm.startPrank(alice);
        ERC20DecimalsMock(config.usdcAddress).approve(
            address(basicPaywallWithERC20),
            USDC_MONTH_PRICE
        );
        basicPaywallWithERC20.purchase(
            config.usdcAddress,
            BasicPaywallWithERC20.PurchaseDuration.MONTH
        );
        vm.stopPrank();

        vm.startPrank(bob);
        ERC20DecimalsMock(config.usdtAddress).approve(
            address(basicPaywallWithERC20),
            USDT_YEAR_PRICE
        );
        basicPaywallWithERC20.purchase(
            config.usdtAddress,
            BasicPaywallWithERC20.PurchaseDuration.YEAR
        );
        vm.stopPrank();
        _;
    }

    function testRevertIfNotOwnerWantToWithdraw() public usersHavePurchased {
        vm.startPrank(alice);
        vm.expectRevert();
        basicPaywallWithERC20.withdrawToken(
            config.usdcAddress,
            USDC_MONTH_PRICE
        );
        vm.stopPrank();
    }

    function testRevertIfOwnerWantToWithdrawMoreThanBalanceAvailable()
        public
        usersHavePurchased
    {
        address tokenToWithdraw = config.usdcAddress;

        vm.expectRevert(
            abi.encodeWithSelector(
                BasicPaywallWithERC20
                    .BasicPaywallWithERC20__InsufficientBalance
                    .selector,
                tokenToWithdraw
            )
        );
        basicPaywallWithERC20.withdrawToken(tokenToWithdraw, USDC_YEAR_PRICE);
    }

    function testOwnerCanWithdrawASupportedToken() public usersHavePurchased {
        ERC20DecimalsMock usdc = ERC20DecimalsMock(config.usdcAddress);
        uint256 ownerInitialBalance = usdc.balanceOf(address(this));
        uint256 paywallInitialBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        );

        basicPaywallWithERC20.withdrawToken(
            config.usdcAddress,
            USDC_MONTH_PRICE
        );

        uint256 ownerFinalBalance = usdc.balanceOf(address(this));
        uint256 paywallFinalBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        );

        vm.assertEq(ownerFinalBalance, ownerInitialBalance + USDC_MONTH_PRICE);
        vm.assertEq(
            paywallFinalBalance,
            paywallInitialBalance - USDC_MONTH_PRICE
        );
    }

    function testOwnerCanWithdrawAllBalanceOfSupportedTokens()
        public
        usersHavePurchased
    {
        ERC20DecimalsMock usdc = ERC20DecimalsMock(config.usdcAddress);
        ERC20DecimalsMock usdt = ERC20DecimalsMock(config.usdtAddress);
        uint256 ownerInitialBalance = usdc.balanceOf(address(this)) +
            usdt.balanceOf(address(this));
        uint256 paywallInitialBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        ) + usdt.balanceOf(address(basicPaywallWithERC20));

        basicPaywallWithERC20.withdrawAll();

        uint256 ownerFinalBalance = usdc.balanceOf(address(this)) +
            usdt.balanceOf(address(this));
        uint256 paywallFinalBalance = usdc.balanceOf(
            address(basicPaywallWithERC20)
        ) + usdt.balanceOf(address(basicPaywallWithERC20));

        vm.assertEq(
            ownerFinalBalance,
            ownerInitialBalance + USDC_MONTH_PRICE + USDT_YEAR_PRICE
        );
        vm.assertEq(
            paywallFinalBalance,
            paywallInitialBalance - USDC_MONTH_PRICE - USDT_YEAR_PRICE
        );
    }

    /*
     * ============================
     * =       EVENT TESTS        =
     * ============================
     */

    function testNewPaidUserEventEmitWithRightArgumentsOnMonthPurchase()
        public
    {
        vm.startPrank(alice);
        ERC20DecimalsMock(config.usdcAddress).approve(
            address(basicPaywallWithERC20),
            USDC_MONTH_PRICE
        );

        uint256 currentTimestamp = block.timestamp;

        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit NewPaidUser(
            alice,
            config.usdcAddress,
            false,
            currentTimestamp + SECONDS_PER_MONTH
        );
        basicPaywallWithERC20.purchase(
            config.usdcAddress,
            BasicPaywallWithERC20.PurchaseDuration.MONTH
        );

        vm.stopPrank();
    }

    function testNewPaidUserEventEmitWithRightArgumentsOnYearPurchase() public {
        vm.startPrank(bob);
        ERC20DecimalsMock(config.usdtAddress).approve(
            address(basicPaywallWithERC20),
            USDT_YEAR_PRICE
        );

        uint256 currentTimestamp = block.timestamp;

        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit NewPaidUser(
            bob,
            config.usdtAddress,
            true,
            currentTimestamp + SECONDS_PER_YEAR
        );
        basicPaywallWithERC20.purchase(
            config.usdtAddress,
            BasicPaywallWithERC20.PurchaseDuration.YEAR
        );

        vm.stopPrank();
    }

    function testWithdrawEventEmitWhenOwnerWithdrawASupportedToken()
        public
        usersHavePurchased
    {
        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit Withdraw(USDC_MONTH_PRICE, config.usdcAddress);

        basicPaywallWithERC20.withdrawToken(
            config.usdcAddress,
            USDC_MONTH_PRICE
        );
    }

    function testTokenAddedEventEmitWhenOwnerAddNewSupportedToken() public {
        address newToken = makeAddr("new_token");
        uint256 newTokenMonthPrice = 3e6;
        uint256 newTokenYearPrice = 30e6;

        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit TokenAdded(newToken, newTokenMonthPrice, newTokenYearPrice);

        basicPaywallWithERC20.addSupportedToken(
            newToken,
            newTokenMonthPrice,
            newTokenYearPrice
        );
    }

    function testTokenRemovedEventEmitWhenOwnerRemoveATokenFromSupportedTokenList()
        public
    {
        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit TokenRemoved(config.usdcAddress);

        basicPaywallWithERC20.removeSupportedToken(config.usdcAddress);
    }

    function testPricesUpdatedEventEmitWhenOwnerUpdatePricesForASupportedToken()
        public
    {
        uint256 newMonthPrice = 3e6;
        uint256 newYearPrice = 30e6;

        vm.expectEmit(true, true, true, true, address(basicPaywallWithERC20));
        emit PricesUpdated(config.usdcAddress, newMonthPrice, newYearPrice);

        basicPaywallWithERC20.updatePrices(
            config.usdcAddress,
            newMonthPrice,
            newYearPrice
        );
    }
}
