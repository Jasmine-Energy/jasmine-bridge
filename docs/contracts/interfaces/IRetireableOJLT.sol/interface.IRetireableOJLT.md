# IRetireableOJLT
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/interfaces/IRetireableOJLT.sol)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Defines OJLT that can be retired


## Functions
### retire

Burns 'quantity' of tokens from 'owner' in the name of 'beneficiary'.

*Executes retirement on origin chain using LZ message*

*Emits a [Retirement](/contracts/interfaces/IRetireableOJLT.sol/interface.IRetireableOJLT.md#retirement) event.*

*Requirements:
- msg.sender must be approved for owner's JLTs
- Owner must have sufficient JLTs
- Owner cannot be zero address*


```solidity
function retire(
    address from,
    address beneficiary,
    uint256 amount,
    bytes calldata data
) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|JLT owner from which to burn tokens|
|`beneficiary`|`address`|Address to receive retirement acknowledgment. If none, assume msg.sender|
|`amount`|`uint256`|Number of JLTs to withdraw|
|`data`|`bytes`|Optional calldata to relay to retirement service via onERC1155Received|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`msgReceipt`|`MessagingReceipt`|LayerZero message receipt containing identifiers and metadata|
|`oftReceipt`|`OFTReceipt`|LayerZero OFT receipt regarding the send|


## Events
### Retirement
Emitted when omnichain JLT (OJLT) are burned and sent to origin chain
for retirement

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

