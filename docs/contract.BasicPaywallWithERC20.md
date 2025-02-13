# BasicPaywallWithERC20
**Inherits:**
Ownable

**Author:**
Francisco Gómez. X: @FcoGomez92_; GitHub: FcoGomez92
This contract is a gas optimized minimal implementation for payment systems that grant access to content or services,
such as paywalls or premium subscriptions.
The contract owner can manage prices for different durations (monthly or yearly) and manage supported tokens.

As a basic implementation, this contract is focused solely on payment processing.
Access control and user management must be handled offchain.


## State Variables
### SECONDS_PER_MONTH

```solidity
uint256 private constant SECONDS_PER_MONTH = 30 days;
```


### SECONDS_PER_YEAR

```solidity
uint256 private constant SECONDS_PER_YEAR = 365 days;
```


### s_pricesBySupportedToken

```solidity
mapping(address => Prices) private s_pricesBySupportedToken;
```


### s_supportedTokens

```solidity
address[] private s_supportedTokens;
```


## Functions
### isSupportedToken


```solidity
modifier isSupportedToken(address token);
```

### validAddress


```solidity
modifier validAddress(address addr);
```

### constructor

This function is used to initialize the contract with the supported tokens and their prices.

*The token addresses and their prices must be in the same index.*


```solidity
constructor(address[] memory tokenAddresses, uint256[] memory monthPrices, uint256[] memory yearPrices)
    Ownable(msg.sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddresses`|`address[]`|List of the supported tokens addresses.|
|`monthPrices`|`uint256[]`|List of the prices for the monthly tier.|
|`yearPrices`|`uint256[]`|List of the prices for the yearly tier.|


### purchase

This function is used to purchase access to the content or service.

*Uses SafeERC20 to protect against faulty ERC20 implementations and non-standard token behavior.*


```solidity
function purchase(address _token, PurchaseDuration duration) external isSupportedToken(_token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the token used to purchase the access. Must be supported.|
|`duration`|`PurchaseDuration`|The duration tier of the purchase.|


### withdrawToken

This function is used to withdraw tokens from the contract.

This function not use the isSupportedToken modifier because it is also used to recover tokens sent to the contract by error.


```solidity
function withdrawToken(address _token, uint256 _amount) external onlyOwner validAddress(_token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the token to withdraw.|
|`_amount`|`uint256`|The amount of tokens to withdraw.|


### withdrawAll

This function is used to withdraw all the tokens from the contract.


```solidity
function withdrawAll() external onlyOwner;
```

### updatePrices

This function is used to update the prices for a supported token.

*We update the entire struct at once, even though `isActive` was already `true`, because this approach is more gas efficient.
It minimizes storage writes by performing a single write operation.*


```solidity
function updatePrices(address token, uint256 _monthPrice, uint256 _yearPrice)
    external
    onlyOwner
    isSupportedToken(token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to update the prices. Must be supported.|
|`_monthPrice`|`uint256`|The new price for the monthly tier.|
|`_yearPrice`|`uint256`|The new price for the yearly tier.|


### addSupportedToken

This function is used to add a new supported token.


```solidity
function addSupportedToken(address token, uint256 monthPrice, uint256 yearPrice)
    external
    onlyOwner
    validAddress(token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to add.|
|`monthPrice`|`uint256`|The price for the monthly tier.|
|`yearPrice`|`uint256`|The price for the yearly tier.|


### removeSupportedToken

This function is used to remove a supported token.


```solidity
function removeSupportedToken(address token) external onlyOwner isSupportedToken(token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to update the prices. Must be supported.|


### _withdraw

This function make the transfer from this contract to the owner address.

*Uses SafeERC20 to protect against faulty ERC20 implementations and non-standard token behavior.*


```solidity
function _withdraw(IERC20 _token, uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`IERC20`|The address of the token to withdraw. Must be supported.|
|`_amount`|`uint256`|The amount to withdraw.|


### _addSupportedToken

This function is used to add a new supported token.


```solidity
function _addSupportedToken(address _token, uint256 _monthPrice, uint256 _yearPrice) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the token to add.|
|`_monthPrice`|`uint256`|The price for the monthly tier.|
|`_yearPrice`|`uint256`|The price for the yearly tier.|


### getPriceByToken

This function return the prices using a supported token.


```solidity
function getPriceByToken(address token)
    external
    view
    isSupportedToken(token)
    returns (uint256 monthPrice, uint256 yearPrice);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the supported token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`monthPrice`|`uint256`|The price for the monthly tier using this token.|
|`yearPrice`|`uint256`|The price for the yearly tier using this token.|


### getSupportedTokens

This function returns all the supported tokens.


```solidity
function getSupportedTokens() external view returns (address[] memory supportedTokens);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`supportedTokens`|`address[]`|The list of supported token addresses.|


## Events
### NewPaidUser

```solidity
event NewPaidUser(address indexed user, address indexed token, bool indexed isYearlyPurchase, uint256 endTimestamp);
```

### Withdraw

```solidity
event Withdraw(uint256 indexed amount, address indexed token);
```

### TokenAdded

```solidity
event TokenAdded(address indexed token, uint256 monthPrice, uint256 yearPrice);
```

### TokenRemoved

```solidity
event TokenRemoved(address indexed token);
```

### PricesUpdated

```solidity
event PricesUpdated(address indexed token, uint256 monthPrice, uint256 yearPrice);
```

## Errors
### BasicPaywallWithERC20__MismatchInTokenAndPricesArrayLength

```solidity
error BasicPaywallWithERC20__MismatchInTokenAndPricesArrayLength();
```

### BasicPaywallWithERC20__MismatchInPricesArrayLength

```solidity
error BasicPaywallWithERC20__MismatchInPricesArrayLength();
```

### BasicPaywallWithERC20__TokenNotSupported

```solidity
error BasicPaywallWithERC20__TokenNotSupported(address token);
```

### BasicPaywallWithERC20__InsufficientBalance

```solidity
error BasicPaywallWithERC20__InsufficientBalance(address token);
```

### BasicPaywallWithERC20__ZeroAddress

```solidity
error BasicPaywallWithERC20__ZeroAddress();
```

## Structs
### Prices

```solidity
struct Prices {
    bool isActive;
    uint256 monthPrice;
    uint256 yearPrice;
}
```

## Enums
### PurchaseDuration
By design, this contract only allows two different durations or tiers.


```solidity
enum PurchaseDuration {
    MONTH,
    YEAR
}
```

