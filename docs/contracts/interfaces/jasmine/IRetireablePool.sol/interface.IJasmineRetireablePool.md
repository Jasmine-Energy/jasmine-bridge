# IJasmineRetireablePool
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/interfaces/jasmine/IRetireablePool.sol)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Extends pools with retirement functionality and events.


## Functions
### retire

Burns 'quantity' of tokens from 'owner' in the name of 'beneficiary'.

*Internally, calls are routed to Retirement Service to facilitate the retirement.*

*Emits a [Retirement](/contracts/interfaces/jasmine/IRetireablePool.sol/interface.IJasmineRetireablePool.md#retirement) event.*

*Requirements:
- msg.sender must be approved for owner's JLTs
- Owner must have sufficient JLTs
- Owner cannot be zero address*


```solidity
function retire(address from, address beneficiary, uint256 amount, bytes calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|JLT owner from which to burn tokens|
|`beneficiary`|`address`|Address to receive retirement acknowledgment. If none, assume msg.sender|
|`amount`|`uint256`|Number of JLTs to retire|
|`data`|`bytes`|Optional calldata to relay to retirement service via onERC1155Received|


### retirementCost

Cost of retiring JLTs from pool.


```solidity
function retirementCost(uint256 amount) external view returns (uint256 cost);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of JLTs to retire.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`cost`|`uint256`|Price of retiring in JLTs.|


## Events
### Retirement
emitted when tokens from a pool are retired

*must be accompanied by a token burn event*


```solidity
event Retirement(address indexed operator, address indexed beneficiary, uint256 quantity);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Initiator of retirement|
|`beneficiary`|`address`|Designate beneficiary of retirement|
|`quantity`|`uint256`|Number of JLT being retired|

