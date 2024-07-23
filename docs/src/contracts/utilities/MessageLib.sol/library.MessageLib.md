# MessageLib
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/41a89a99de073bdfa320a66b9536780475689209/contracts/utilities/MessageLib.sol)


## State Variables
### MSG_TYPE_OFFSET

```solidity
uint8 constant MSG_TYPE_OFFSET = 0;
```


### USER_OFFSET

```solidity
uint8 constant USER_OFFSET = 1;
```


### AMOUNT_OFFSET

```solidity
uint8 constant AMOUNT_OFFSET = 21;
```


### DATA_OFFSET

```solidity
uint8 constant DATA_OFFSET = 53;
```


## Functions
### encodeRetirementCommand


```solidity
function encodeRetirementCommand(bytes memory data) internal pure returns (bytes memory command);
```

### _encodeTransferMessage


```solidity
function _encodeTransferMessage(
    address recipient,
    uint256 amount
) internal pure returns (bytes memory message);
```

### _encodeRetirementMessage


```solidity
function _encodeRetirementMessage(
    address beneficiary,
    uint256 amount,
    bytes memory data
) internal pure returns (bytes memory message);
```

### _encodeWithdrawAnyMessage


```solidity
function _encodeWithdrawAnyMessage(
    address recipient,
    uint256 amount
) internal pure returns (bytes memory message);
```

### _decodeMessageType


```solidity
function _decodeMessageType(bytes memory message)
    internal
    pure
    returns (bool isValidType, MessageType messageType);
```

### _decodeTransferMessage


```solidity
function _decodeTransferMessage(bytes memory message)
    internal
    pure
    returns (address recipient, uint256 amount);
```

### _decodeRetirementMessage


```solidity
function _decodeRetirementMessage(bytes memory message)
    internal
    pure
    returns (address beneficiary, uint256 amount, bytes memory data);
```

### _decodeWithdrawAnyMessage


```solidity
function _decodeWithdrawAnyMessage(bytes memory message)
    internal
    pure
    returns (address recipient, uint256 amount);
```

### decodeRetireCommandReason


```solidity
function decodeRetireCommandReason(bytes memory message) internal pure returns (bytes memory reasonData);
```

### hasCommand


```solidity
function hasCommand(SendParam memory params) internal pure returns (bool);
```

## Errors
### InvalidMessageType

```solidity
error InvalidMessageType(bytes1 operationByte);
```

## Enums
### MessageType

```solidity
enum MessageType {
    NO_OP,
    SEND,
    SEND_AND_CALL,
    RETIREMENT,
    WITHDRAW_ANY,
    WITHDRAW_SPECIFIC
}
```

