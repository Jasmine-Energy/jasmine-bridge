# JasmineSpokeBridge
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/41a89a99de073bdfa320a66b9536780475689209/contracts/SpokeBridge.sol)

**Inherits:**
OApp, [IOJLTDeployer](/contracts/interfaces/IOJLTDeployer.sol/interface.IOJLTDeployer.md)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Responsible for deploying new omnichain JLT (OJLT) contracts on destination
networks. OJLT can be sent and received between chains, and do JLT specific operations
such as cross-chain retirements and EAT withdrawals.


## State Variables
### ojlts
Maps a JLT address (from origin chain) to its corresponding OJLT address


```solidity
mapping(address underlying => address ojlt) public ojlts;
```


### _ojltInitCode
*During construction, arguments are allocated to transient storage rather
than the stack, allowing for more data to be used. This field is used solely
during construction to access these parameters.*


```solidity
TransientBytes internal _ojltInitCode;
```


### _originEid
*LZ endpoint ID of the origin chain - which holds to underlying JLT*


```solidity
uint32 private immutable _originEid;
```


## Functions
### constructor


```solidity
constructor(
    address endpoint_,
    address delegate_,
    uint32 originEid_
) OApp(endpoint_, delegate_) Ownable(delegate_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`endpoint_`|`address`|LZ endpoint (V2) to use when construction OJLTs|
|`delegate_`|`address`|Owner address capable of deploying new OJLTs and updating LZ configurations|
|`originEid_`|`uint32`|LZ endpoint ID of the origin chain|


### createOJLT

Allows owner to deploy new OJLT


```solidity
function createOJLT(
    address _underlying,
    address _peer,
    string memory _name,
    string memory _symbol
) external onlyOwner returns (address oft);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_underlying`|`address`|Address of the underlying JLT on the origin chain|
|`_peer`|`address`|Address of the corresponding JLTAdapter on the origin chain|
|`_name`|`string`|ERC-20 token name of the new OJLT. Should match underlying's name|
|`_symbol`|`string`|ERC-20 token symbol of the new OJLT. Should match underlying's symbol|


### setOJLTPeer

Allows owner to set a new LZ peer for an OJLT


```solidity
function setOJLTPeer(address _ojlt, uint32 _eid, bytes32 _peer) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ojlt`|`address`|Address of the existing OJLT for which to set peer|
|`_eid`|`uint32`|LZ endpoint ID of the peer|
|`_peer`|`bytes32`|Address of the peer contract as bytes32 (to support non-EVM networks)|


### setDefaultRetireGasLimit

Allows owner to update an OJLT's default retirement gas limit


```solidity
function setDefaultRetireGasLimit(address _ojlt, uint128 _gasLimit) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ojlt`|`address`|Address of the deployed OJLT for which to update retirement gas limit|
|`_gasLimit`|`uint128`|New gas default limit for retirements|


### getOJLTName

*Used to set new OJLT's token name during construction*


```solidity
function getOJLTName() external view returns (string memory name);
```

### getOJLTSymbol

*Used to set new OJLT's token symbol during construction*


```solidity
function getOJLTSymbol() external view returns (string memory symbol);
```

### getLZEndpoint

*Used to set new OJLT's LZ endpoint (V2) address*


```solidity
function getLZEndpoint() external view returns (address endpoint);
```

### getOriginEid

*Used to set new OJLT's LZ endpoint ID for the origin chain*


```solidity
function getOriginEid() external view returns (uint32 eid);
```

### getOJLTRootPeer

*Used to set new OJLT's origin chain peer*


```solidity
function getOJLTRootPeer() external view returns (bytes32 rootPeer);
```

### _storeOJLTInitData

*Stores OJLT's constructor arugments to transient storage for later retrieval*


```solidity
function _storeOJLTInitData(string memory _name, string memory _symbol, bytes32 _rootPeer) internal;
```

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

### predictOJLTAddress

Deterministically computes the expected OJLT address for a given
JLT. Note, the OJLT is not guaranteed to exist.


```solidity
function predictOJLTAddress(address underlying) public view returns (address ojlt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address on origin network of the JLT to derive OJLT address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ojlt`|`address`|Expected or existing address of the OJLT contract|


### _encodeOJLTCreationCode

*Encodes the OJLT's creation code to be used by CREATE3. Note, address
of this contract, owner field, must explicitly be provided due as msg.sender is
the CREATE3 factory during adapter construction*


```solidity
function _encodeOJLTCreationCode() private view returns (bytes memory creationCode);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`creationCode`|`bytes`|Deployable bytecode for the new OJLT with constructor arguments preconfigured|


## Events
### OJLTCreated
Emitted when a new OJLT is deployed, allowing the underlying JLT
to be bridged to this network


```solidity
event OJLTCreated(address indexed underlying, address indexed ojlt);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address of the underlying JLT on the origin chain|
|`ojlt`|`address`|Address of the newly deployed OJLT|

## Errors
### OJLTExists
Reverted when trying to deploy an OJLT which already exists


```solidity
error OJLTExists(address underlying, address ojlt);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`underlying`|`address`|Address of the underlying JLT on the origin chain|
|`ojlt`|`address`|Address of the existing OJLT contract|

