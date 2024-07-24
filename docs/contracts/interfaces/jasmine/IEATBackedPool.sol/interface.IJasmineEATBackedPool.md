# IJasmineEATBackedPool
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/interfaces/jasmine/IEATBackedPool.sol)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Contains functionality and events for pools which issue JLTs for EATs
deposits and permit withdrawals of EATs.

*Due to linearization issues, ERC-20 and ERC-1155 Receiver are not enforced
conformances - but likely should be.*


## Functions
### deposit

Used to deposit EATs into the pool to receive JLTs.

*Requirements:
- Pool must be an approved operator of from address*


```solidity
function deposit(uint256 tokenId, uint256 quantity) external returns (uint256 jltQuantity);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|EAT token ID to deposit|
|`quantity`|`uint256`|Number of EATs for given tokenId to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`jltQuantity`|`uint256`|Number of JLTs issued for deposit Emits a [Deposit](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#deposit) event.|


### depositFrom

Used to deposit EATs from another account into the pool to receive JLTs.

*Requirements:
- Pool must be an approved operator of from address
- msg.sender must be approved for the user's tokens*


```solidity
function depositFrom(
    address from,
    uint256 tokenId,
    uint256 quantity
) external returns (uint256 jltQuantity);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Address from which to transfer EATs to pool|
|`tokenId`|`uint256`|EAT token ID to deposit|
|`quantity`|`uint256`|Number of EATs for given tokenId to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`jltQuantity`|`uint256`|Number of JLTs issued for deposit Emits a [Deposit](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#deposit) event.|


### depositBatch

Used to deposit numerous EATs of different IDs
into the pool to receive JLTs.

*Requirements:
- Pool must be an approved operator of from address
- Lenght of tokenIds and quantities must match*


```solidity
function depositBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
) external returns (uint256 jltQuantity);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Address from which to transfer EATs to pool|
|`tokenIds`|`uint256[]`|EAT token IDs to deposit|
|`quantities`|`uint256[]`|Number of EATs for tokenId at same index to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`jltQuantity`|`uint256`|Number of JLTs issued for deposit Emits a [Deposit](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#deposit) event.|


### withdraw

Withdraw EATs from pool by burning 'quantity' of JLTs from 'owner'.

*Pool will automatically select EATs to withdraw. Defer to [withdrawSpecific](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#withdrawspecific)
if selecting specific EATs to withdraw is important.*

*Requirements:
- msg.sender must have sufficient JLTs
- If recipient is a contract, it must implement onERC1155Received &
onERC1155BatchReceived*


```solidity
function withdraw(
    address recipient,
    uint256 quantity,
    bytes calldata data
) external returns (uint256[] memory tokenIds, uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|Address to receive withdrawn EATs|
|`quantity`|`uint256`|Number of JLTs to withdraw|
|`data`|`bytes`|Optional calldata to relay to recipient via onERC1155Received|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenIds`|`uint256[]`|Token IDs withdrawn from the pool|
|`amounts`|`uint256[]`|Number of tokens withdraw, per ID, from the pool Emits a [Withdraw](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#withdraw) event.|


### withdrawFrom

Withdraw EATs from pool by burning 'quantity' of JLTs from 'owner'.

*Pool will automatically select EATs to withdraw. Defer to [withdrawSpecific](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#withdrawspecific)
if selecting specific EATs to withdraw is important.*

*Requirements:
- msg.sender must be approved for owner's JLTs
- Owner must have sufficient JLTs
- If recipient is a contract, it must implement onERC1155Received &
onERC1155BatchReceived*


```solidity
function withdrawFrom(
    address spender,
    address recipient,
    uint256 quantity,
    bytes calldata data
) external returns (uint256[] memory tokenIds, uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|JLT owner from which to burn tokens|
|`recipient`|`address`|Address to receive withdrawn EATs|
|`quantity`|`uint256`|Number of JLTs to withdraw|
|`data`|`bytes`|Optional calldata to relay to recipient via onERC1155Received|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenIds`|`uint256[]`|Token IDs withdrawn from the pool|
|`amounts`|`uint256[]`|Number of tokens withdraw, per ID, from the pool Emits a [Withdraw](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#withdraw) event.|


### withdrawSpecific

Withdraw specific EATs from pool by burning the sum of 'quantities' in JLTs from
'owner'.

*Requirements:
- msg.sender must be approved for owner's JLTs
- Length of tokenIds and quantities must match
- Owner must have more JLTs than sum of quantities
- If recipient is a contract, it must implement onERC1155Received &
onERC1155BatchReceived
- Owner and Recipient cannot be zero address*


```solidity
function withdrawSpecific(
    address spender,
    address recipient,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities,
    bytes calldata data
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|JLT owner from which to burn tokens|
|`recipient`|`address`|Address to receive withdrawn EATs|
|`tokenIds`|`uint256[]`|EAT token IDs to withdraw from pool|
|`quantities`|`uint256[]`|Number of EATs for tokenId at same index to deposit|
|`data`|`bytes`|Optional calldata to relay to recipient via onERC1155Received Emits a [Withdraw](/contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md#withdraw) event.|


### withdrawalCost

Cost of withdrawing specified amounts of tokens from pool.


```solidity
function withdrawalCost(
    uint256[] memory tokenIds,
    uint256[] memory amounts
) external view returns (uint256 cost);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIds`|`uint256[]`|IDs of EATs to withdaw|
|`amounts`|`uint256[]`|Amounts of EATs to withdaw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`cost`|`uint256`|Price of withdrawing EATs in JLTs|


### withdrawalCost

Cost of withdrawing amount of tokens from pool where pool
selects the tokens to withdraw.


```solidity
function withdrawalCost(uint256 amount) external view returns (uint256 cost);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Number of EATs to withdraw.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`cost`|`uint256`|Price of withdrawing EATs in JLTs|


## Events
### Deposit
*Emitted whenever EATs are deposited to the contract*


```solidity
event Deposit(address indexed operator, address indexed owner, uint256 quantity);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Initiator of the deposit|
|`owner`|`address`|Token holder depositting to contract|
|`quantity`|`uint256`|Number of EATs deposited. Note: JLTs issued are 1-1 with EATs|

### Withdraw
*Emitted whenever EATs are withdrawn from the contract*


```solidity
event Withdraw(address indexed sender, address indexed receiver, uint256 quantity);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|Initiator of the deposit|
|`receiver`|`address`|Token holder depositting to contract|
|`quantity`|`uint256`|Number of EATs withdrawn.|

