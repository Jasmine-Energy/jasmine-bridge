# JasmineHubBridge
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/HubBridge.sol)

**Inherits:**
OApp

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Responsible for deploying new JLT adapters which enable JLT to be bridged
to and from other networks


## State Variables
### adapters
Maps a JLT address to its corresponding JLTAdapter


```solidity
mapping(address underlying => address oftAdapter) public adapters;
```


## Functions
### constructor


```solidity
constructor(address _endpoint, address _delegate) OApp(_endpoint, _delegate) Ownable(_delegate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_endpoint`|`address`|LZ endpoint (V2) to use when construction JLTAdapters|
|`_delegate`|`address`|Owner address capable of deploying new adapters and updating LZ configurations|


### createAdapter

Allows owner to deploy a new JLT adapter deterministically

*Creating an adapter does not configure its peers. This must be done seperately*


```solidity
function createAdapter(address underlying) external onlyOwner returns (address adapter);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|JLT address for which to create a JLTAdapter|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`adapter`|`address`|Address of the newly deploy JLTAdapter|


### setAdapterPeer

Allows owner to set an existing JLTAdapters peer on a new network,
functionally allowing JLTs to be bridged to the new network


```solidity
function setAdapterPeer(address _adapter, uint32 _eid, bytes32 _peer) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_adapter`|`address`|Address of the existing JLTAdapter on which to add new peer|
|`_eid`|`uint32`|LZ endpoint ID of the new chain containing the peer|
|`_peer`|`bytes32`|Address of the peer on the destination chain, encoded as bytes32|


### _lzReceive

*Internal function to implement lzReceive logic without needing to copy the basic parameter validation.*


```solidity
function _lzReceive(
    Origin calldata _origin,
    bytes32 _guid,
    bytes calldata payload,
    address _executor,
    bytes calldata _extraData
) internal override;
```

### predictAdapterAddress

Deterministically computes the expected JLTAdapter address for a given
JLT. Note, the adapter is not guaranteed to exist.


```solidity
function predictAdapterAddress(address underlying) public view returns (address adapter);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address of the JLT to derive adapter address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`adapter`|`address`|Expected or existing address of the `underlying`'s adapter|


### encodeAdapterCreationCode

*Encodes the JLTAdapter's creation code to be used by CREATE3. Note, address
of this contract, owner field, must explicitly be provided due as msg.sender is
the CREATE3 factory during adapter construction*


```solidity
function encodeAdapterCreationCode(address underlying) private view returns (bytes memory creationCode);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address of the JLT for which to encode creation code|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`creationCode`|`bytes`|Deployable bytecode for the new JLTAdapter with constructor arguments preconfigured|


## Events
### JLTAdapterCreated
Emitted when a new adapter is deployed for a given JLT


```solidity
event JLTAdapterCreated(address indexed underlying, address indexed adapter);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address of the JLT for which an adapter was created|
|`adapter`|`address`|Address of the new JLT adapter which can bridge JLT|

## Errors
### AdapterExists
Reverted when trying to deploy a JLTAdapter which already exists


```solidity
error AdapterExists(address underlying, address adapter);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|The JLT contract for which deployment was attempted|
|`adapter`|`address`|The existing JLTAdapter contract|

