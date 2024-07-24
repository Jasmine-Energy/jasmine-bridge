# IJasmineQualifiedPool
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/interfaces/jasmine/IQualifiedPool.sol)

**Author:**
Kai Aldag<kai.aldag@jasmine.energy>

Interface for any pool that has a deposit policy
which constrains deposits.


## Functions
### meetsPolicy

Checks if a given Jasmine EAT token meets the pool's deposit policy


```solidity
function meetsPolicy(uint256 tokenId) external view returns (bool isEligible);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|Token to check pool eligibility for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isEligible`|`bool`|True if token meets policy and may be deposited. False otherwise.|


### policyForVersion

Get a pool's deposit policy for a given metadata version


```solidity
function policyForVersion(uint8 metadataVersion) external view returns (bytes memory policy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataVersion`|`uint8`|Version of metadata to return policy for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`policy`|`bytes`|Deposit policy for given metadata version|


## Errors
### Unqualified
*Emitted if a token does not meet pool's deposit policy*


```solidity
error Unqualified(uint256 tokenId);
```

