# JLTAdapter
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/41a89a99de073bdfa320a66b9536780475689209/contracts/tokens/JLTAdapter.sol)

**Inherits:**
OFTAdapter, Multicall

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Modified OFTAdapter (from LayerZero) enabling ERC-2612 allowance signatures
as well as custom cross-chain retirement logic.


## Functions
### constructor

*Constructor for the OFTAdapter contract.*


```solidity
constructor(
    address _token,
    address _lzEndpoint,
    address _delegate
) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the ERC-20 token to be adapted.|
|`_lzEndpoint`|`address`|The LayerZero endpoint address.|
|`_delegate`|`address`|The delegate capable of making OApp configurations inside of the endpoint.|


### permitInnerToken

*Permits this contract to spend the holder's inner token. This is designed*


```solidity
function permitInnerToken(
    address holder,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external;
```

### _lzReceive

*Internal function to handle the receive on the LayerZero endpoint.*


```solidity
function _lzReceive(
    Origin calldata _origin,
    bytes32 _guid,
    bytes calldata payload,
    address _executor,
    bytes calldata _extraData
) internal override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_origin`|`Origin`|The origin information. - srcEid: The source chain endpoint ID. - sender: The sender address from the src chain. - nonce: The nonce of the LayerZero message.|
|`_guid`|`bytes32`|The unique identifier for the received LayerZero message.|
|`payload`|`bytes`||
|`_executor`|`address`||
|`_extraData`|`bytes`||


### _executeLzMessage

*If payload from _lzReceive requires custom business logic (ie. retirement
or EAT withdraws), this function will parse and handle execution.*


```solidity
function _executeLzMessage(bytes calldata message) internal;
```

### _retireJLT

*Executes a JLT retirement using custodied assets with given fields*


```solidity
function _retireJLT(address beneficiary, uint256 amount, bytes memory data) internal;
```

### _withdrawAny

*Executes an EAT withdrawal using custodied JLT*


```solidity
function _withdrawAny(address recipient, uint256 amount) internal;
```

