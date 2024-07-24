# TransientBytesLib
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/utilities/TransientBytesLib.sol)

**Author:**
philogy <https://github.com/philogy>


## State Variables
### LENGTH_MASK
*4-bytes is way above current max contract size, meant to account for future EVM
versions.*


```solidity
uint256 internal constant LENGTH_MASK = 0xffffffff;
```


### MAX_LENGTH

```solidity
uint256 internal constant MAX_LENGTH = LENGTH_MASK;
```


### LENGTH_BYTES

```solidity
uint256 internal constant LENGTH_BYTES = 4;
```


## Functions
### length


```solidity
function length(TransientBytes storage self) internal view returns (uint256 len);
```

### setCd


```solidity
function setCd(TransientBytes storage self, bytes calldata data) internal;
```

### set


```solidity
function set(TransientBytes storage self, bytes memory data) internal;
```

### get


```solidity
function get(TransientBytes storage self) internal view returns (bytes memory data);
```

### agus


```solidity
function agus(TransientBytes storage self) internal;
```

## Errors
### DataTooLarge

```solidity
error DataTooLarge();
```

### OutOfOrderSlots

```solidity
error OutOfOrderSlots();
```

### RangeTooLarge

```solidity
error RangeTooLarge();
```

