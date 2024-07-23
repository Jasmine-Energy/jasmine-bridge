# OJLT
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/41a89a99de073bdfa320a66b9536780475689209/contracts/tokens/OJLT.sol)

**Inherits:**
OFT, ERC20Permit, [IRetireableOJLT](/contracts/interfaces/IRetireableOJLT.sol/interface.IRetireableOJLT.md)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

JLT implementing LayerZero's Omnichain Fungible Token (OFT) interface
allowing JLT to be bridged and retired between chains.


## State Variables
### retireGasLimit

```solidity
uint128 public retireGasLimit = 200_000;
```


## Functions
### constructor

*Origin chain's corresponding peer is set during construction*


```solidity
constructor(address owner)
    OFT(
        IOJLTDeployer(owner).getOJLTName(),
        IOJLTDeployer(owner).getOJLTSymbol(),
        IOJLTDeployer(owner).getLZEndpoint(),
        owner
    )
    ERC20Permit(IOJLTDeployer(owner).getOJLTName())
    Ownable(owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Address permitted to take privileged actions. Should be SpokeBridge as OFT's name, symbol and endpoint are retrieved from owner address.|


### _buildMsgAndOptions

*Internal function to build the message and options.*


```solidity
function _buildMsgAndOptions(
    SendParam calldata _sendParam,
    uint256 _amountLD
) internal view virtual override returns (bytes memory message, bytes memory options);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sendParam`|`SendParam`|The parameters for the send() operation.|
|`_amountLD`|`uint256`|The amount in local decimals.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`message`|`bytes`|The encoded message.|
|`options`|`bytes`|The encoded options.|


### _lzSend

*Internal function to interact with the LayerZero EndpointV2.send() for sending a message.*


```solidity
function _lzSend(
    uint32 _dstEid,
    bytes memory _message,
    bytes memory _options,
    MessagingFee memory _fee,
    address _refundAddress
) internal virtual override returns (MessagingReceipt memory receipt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_dstEid`|`uint32`|The destination endpoint ID.|
|`_message`|`bytes`|The message payload.|
|`_options`|`bytes`|Additional options for the message.|
|`_fee`|`MessagingFee`|The calculated LayerZero fee for the message. - nativeFee: The native fee. - lzTokenFee: The lzToken fee.|
|`_refundAddress`|`address`|The address to receive any excess fee values sent to the endpoint.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`receipt`|`MessagingReceipt`|The receipt for the sent message. - guid: The unique identifier for the sent message. - nonce: The nonce of the sent message. - fee: The LayerZero fee incurred for the message.|


### quoteRetire

Gets the native fee to send when calling `retire`

*Only computes the native token cost, does not support paying in LZ token*


```solidity
function quoteRetire(uint256 reasonLength) public view returns (uint256 nativeFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reasonLength`|`uint256`|The length of the reason string attached to the retirement measured in bytes|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nativeFee`|`uint256`|The amount of native token to pay when calling retire measured in wei|


### retire

Burns 'quantity' of tokens from 'owner' in the name of 'beneficiary'.

*Executes retirement on origin chain using LZ message*


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


### getRootPeer

Address of the JLTAdapter on origin chain


```solidity
function getRootPeer() external view returns (address rootPeer);
```

### _getRootPeerBytes

*Internal utility that gets JLTAdapter (on origin chain) as bytes32*


```solidity
function _getRootPeerBytes() internal view returns (bytes32 rootPeer);
```

### _getOriginEid

*The LZ origin chain's endpoint ID*


```solidity
function _getOriginEid() internal view returns (uint32 originEid);
```

### decimals

*Returns the decimals places of the token.*


```solidity
function decimals() public pure override returns (uint8);
```

### setRetireGasLimit

Allows owner to update the default retire gas limit


```solidity
function setRetireGasLimit(uint128 _retireGasLimit) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_retireGasLimit`|`uint128`|New default retire gas limit on origin chain|


### _buildRetireParams

*Builds retirement send params to be send by LZ*


```solidity
function _buildRetireParams(
    address beneficiary,
    uint256 amount,
    bytes memory data
) internal view returns (SendParam memory params);
```

### _buildDefaultGasOptions

*Builds default gas options for LZ operations on origin chain*


```solidity
function _buildDefaultGasOptions() internal view returns (bytes memory options);
```

## Events
### RetireGasLimitUpdated
Emitted when owner updates the default retirement gas limit


```solidity
event RetireGasLimitUpdated(uint256 newLimit, uint256 oldLimit);
```

