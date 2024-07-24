# IOJLTDeployer
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/interfaces/IOJLTDeployer.sol)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Interface for data sharing OFT constructor arguments.


## Functions
### getLZEndpoint

Gets address of the LayerZero endpoint (V2) contract


```solidity
function getLZEndpoint() external view returns (address endpoint);
```

### getOriginEid

Gets the origin chain's LayerZero endpoint ID


```solidity
function getOriginEid() external view returns (uint32 eid);
```

### getOJLTName

Gets the OJLT's (ERC-20) token name


```solidity
function getOJLTName() external view returns (string memory name);
```

### getOJLTSymbol

Gets the OJLT's (ERC-20) token symbol


```solidity
function getOJLTSymbol() external view returns (string memory symbol);
```

### getOJLTRootPeer

Gets the OJLT's root peer on the origin chain


```solidity
function getOJLTRootPeer() external view returns (bytes32 rootPeer);
```

