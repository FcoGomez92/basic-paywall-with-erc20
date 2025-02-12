// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BasicPaywallWithERC20
 * @author Francisco Gómez. X: @FcoGomez92_; GitHub: FcoGomez92
 *
 * This contract is a gas optimized minimal implementation for payment systems that grant access to content or services,
 * such as paywalls or premium subscriptions.
 * The contract owner can manage prices for different durations (monthly or yearly) and manage supported tokens.
 *
 * @notice As a basic implementation, this contract is focused solely on payment processing.
 *         Access control and user management must be handled offchain.
 */
contract BasicPaywallWithERC20 is Ownable {
    /*
     * ============================
     * =         ERRORS           =
     * ============================
     */
    error BasicPaywallWithERC20__MismatchInTokenAndPricesArrayLength();
    error BasicPaywallWithERC20__MismatchInPricesArrayLength();
    error BasicPaywallWithERC20__TokenNotSupported(address token);
    error BasicPaywallWithERC20__InsufficientBalance(address token);
    error BasicPaywallWithERC20__ZeroAddress();

    /*
     * ============================
     * =    LIBRARIES & TYPES     =
     * ============================
     */
    using SafeERC20 for IERC20;

    struct Prices {
        bool isActive; // always true once added. Used to check if the token is supported.
        uint256 monthPrice;
        uint256 yearPrice;
    }

    /**
     * @notice By design, this contract only allows two different durations or tiers.
     */
    enum PurchaseDuration {
        MONTH,
        YEAR
    }

    /*
     * ============================
     * =         CONSTANTS        =
     * ============================
     */
    uint256 private constant SECONDS_PER_MONTH = 30 days;
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    /*
     * ============================
     * =      STATE VARIABLES     =
     * ============================
     */
    mapping(address => Prices) private s_pricesBySupportedToken;
    address[] private s_supportedTokens;

    /*
     * ============================
     * =         EVENTS           =
     * ============================
     */
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

    /*
     * ============================
     * =         MODIFIERS        =
     * ============================
     */
    modifier isSupportedToken(address token) {
        if (!s_pricesBySupportedToken[token].isActive) {
            revert BasicPaywallWithERC20__TokenNotSupported(token);
        }
        _;
    }

    modifier validAddress(address addr) {
        if (addr == address(0)) {
            revert BasicPaywallWithERC20__ZeroAddress();
        }
        _;
    }

    /*
     * ============================
     * =         FUNCTIONS        =
     * ============================
     */
    /**
     * @notice This function is used to initialize the contract with the supported tokens and their prices.
     * @dev The token addresses and their prices must be in the same index.
     * @param tokenAddresses List of the supported tokens addresses.
     * @param monthPrices List of the prices for the monthly tier.
     * @param yearPrices List of the prices for the yearly tier.
     */
    constructor(
        address[] memory tokenAddresses,
        uint256[] memory monthPrices,
        uint256[] memory yearPrices
    ) Ownable(msg.sender) {
        if (tokenAddresses.length != monthPrices.length) {
            revert BasicPaywallWithERC20__MismatchInTokenAndPricesArrayLength();
        }
        if (monthPrices.length != yearPrices.length) {
            revert BasicPaywallWithERC20__MismatchInPricesArrayLength();
        }

        uint256 len = tokenAddresses.length;
        for (uint256 i = 0; i < len; ) {
            _addSupportedToken(
                tokenAddresses[i],
                monthPrices[i],
                yearPrices[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /*
     * ============================
     * =         EXTERNAL         =
     * ============================
     */
    /**
     * @notice This function is used to purchase access to the content or service.
     * @param _token The address of the token used to purchase the access. Must be supported.
     * @param duration The duration tier of the purchase.
     * @dev Uses SafeERC20 to protect against faulty ERC20 implementations and non-standard token behavior.
     */
    function purchase(
        address _token,
        PurchaseDuration duration
    ) external isSupportedToken(_token) {
        bool isYearlyPurchase = duration == PurchaseDuration.YEAR;
        Prices memory pricesByToken = s_pricesBySupportedToken[_token];
        uint256 price = isYearlyPurchase
            ? pricesByToken.yearPrice
            : pricesByToken.monthPrice;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), price);

        emit NewPaidUser(
            msg.sender,
            _token,
            isYearlyPurchase,
            block.timestamp +
                (isYearlyPurchase ? SECONDS_PER_YEAR : SECONDS_PER_MONTH)
        );
    }

    /**
     * @notice This function is used to withdraw tokens from the contract.
     * @notice This function not use the isSupportedToken modifier because it is also used to recover tokens sent to the contract by error.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawToken(
        address _token,
        uint256 _amount
    ) external onlyOwner validAddress(_token) {
        IERC20 token = IERC20(_token);
        if (token.balanceOf(address(this)) < _amount) {
            revert BasicPaywallWithERC20__InsufficientBalance(_token);
        }
        _withdraw(token, _amount);
    }

    /**
     * @notice This function is used to withdraw all the tokens from the contract.
     */
    function withdrawAll() external onlyOwner {
        uint256 len = s_supportedTokens.length;
        for (uint256 i = 0; i < len; ) {
            IERC20 token = IERC20(s_supportedTokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                _withdraw(token, balance);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function is used to update the prices for a supported token.
     * @param token The address of the token to update the prices. Must be supported.
     * @param _monthPrice The new price for the monthly tier.
     * @param _yearPrice The new price for the yearly tier.
     * @dev We update the entire struct at once, even though `isActive` was already `true`, because this approach is more gas efficient.
     *      It minimizes storage writes by performing a single write operation.
     */
    function updatePrices(
        address token,
        uint256 _monthPrice,
        uint256 _yearPrice
    ) external onlyOwner isSupportedToken(token) {
        s_pricesBySupportedToken[token] = Prices({
            isActive: true,
            monthPrice: _monthPrice,
            yearPrice: _yearPrice
        });

        emit PricesUpdated(token, _monthPrice, _yearPrice);
    }

    /**
     * @notice This function is used to add a new supported token.
     * @param token The address of the token to add.
     * @param monthPrice The price for the monthly tier.
     * @param yearPrice The price for the yearly tier.
     */
    function addSupportedToken(
        address token,
        uint256 monthPrice,
        uint256 yearPrice
    ) external onlyOwner validAddress(token) {
        _addSupportedToken(token, monthPrice, yearPrice);
    }

    /**
     * @notice This function is used to remove a supported token.
     * @param token The address of the token to update the prices. Must be supported.
     */
    function removeSupportedToken(
        address token
    ) external onlyOwner isSupportedToken(token) {
        delete s_pricesBySupportedToken[token];

        uint256 len = s_supportedTokens.length;
        for (uint256 i = 0; i < len; ) {
            if (s_supportedTokens[i] == token) {
                s_supportedTokens[i] = s_supportedTokens[len - 1];
                s_supportedTokens.pop();
                emit TokenRemoved(token);
                return;
            }
            unchecked {
                ++i;
            }
        }
    }

    /*
     * ============================
     * =         INTERNAL         =
     * ============================
     */
    /**
     * @notice This function make the transfer from this contract to the owner address.
     * @param _token The address of the token to withdraw. Must be supported.
     * @param _amount The amount to withdraw.
     * @dev Uses SafeERC20 to protect against faulty ERC20 implementations and non-standard token behavior.
     */
    function _withdraw(IERC20 _token, uint256 _amount) internal {
        _token.safeTransfer(owner(), _amount);

        emit Withdraw(_amount, address(_token));
    }

    /*
     * ============================
     * =         PRIVATE          =
     * ============================
     */
    /**
     * @notice This function is used to add a new supported token.
     * @param _token The address of the token to add.
     * @param _monthPrice The price for the monthly tier.
     * @param _yearPrice The price for the yearly tier.
     */
    function _addSupportedToken(
        address _token,
        uint256 _monthPrice,
        uint256 _yearPrice
    ) private {
        s_pricesBySupportedToken[_token] = Prices({
            isActive: true,
            monthPrice: _monthPrice,
            yearPrice: _yearPrice
        });
        s_supportedTokens.push(_token);

        emit TokenAdded(_token, _monthPrice, _yearPrice);
    }

    /*
     * ============================
     * =       VIEW & PURE        =
     * ============================
     */
    /**
     * @notice This function return the prices using a supported token.
     * @param token The address of the supported token.
     * @return monthPrice The price for the monthly tier using this token.
     * @return yearPrice The price for the yearly tier using this token.
     */
    function getPriceByToken(
        address token
    )
        external
        view
        isSupportedToken(token)
        returns (uint256 monthPrice, uint256 yearPrice)
    {
        Prices memory pricesByToken = s_pricesBySupportedToken[token];

        return (pricesByToken.monthPrice, pricesByToken.yearPrice);
    }
    /**
     * @notice This function returns all the supported tokens.
     * @return supportedTokens The list of supported token addresses.
     */
    function getSupportedTokens()
        external
        view
        returns (address[] memory supportedTokens)
    {
        return s_supportedTokens;
    }
}
