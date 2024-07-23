# MockJLT
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/41a89a99de073bdfa320a66b9536780475689209/contracts/mocks/MockJLT.sol)

**Inherits:**
[IJasminePool](/contracts/interfaces/jasmine/IJasminePool.sol/interface.IJasminePool.md), ERC20Permit

*Internal Mock JLT for testing*


## Functions
### constructor


```solidity
constructor() ERC20("Jasmine Liquidity Token", "JLT") ERC20Permit("Jasmine Liquidity Token");
```

### decimals


```solidity
function decimals() public pure override returns (uint8);
```

### deposit


```solidity
function deposit(uint256 tokenId, uint256 quantity) external override returns (uint256 jltQuantity);
```

### depositFrom


```solidity
function depositFrom(
    address from,
    uint256 tokenId,
    uint256 quantity
) external override returns (uint256 jltQuantity);
```

### depositBatch


```solidity
function depositBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
) external override returns (uint256 jltQuantity);
```

### withdraw


```solidity
function withdraw(
    address recipient,
    uint256 quantity,
    bytes calldata data
) external override returns (uint256[] memory tokenIds, uint256[] memory amounts);
```

### withdrawFrom


```solidity
function withdrawFrom(
    address spender,
    address recipient,
    uint256 quantity,
    bytes calldata data
) external override returns (uint256[] memory tokenIds, uint256[] memory amounts);
```

### withdrawSpecific


```solidity
function withdrawSpecific(
    address spender,
    address recipient,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities,
    bytes calldata data
) external override;
```

### withdrawalCost


```solidity
function withdrawalCost(
    uint256[] memory tokenIds,
    uint256[] memory amounts
) external view override returns (uint256 cost);
```

### withdrawalCost


```solidity
function withdrawalCost(uint256 amount) external view override returns (uint256 cost);
```

### meetsPolicy


```solidity
function meetsPolicy(uint256 tokenId) external view override returns (bool isEligible);
```

### policyForVersion


```solidity
function policyForVersion(uint8 metadataVersion) external view override returns (bytes memory policy);
```

### retire


```solidity
function retire(address from, address beneficiary, uint256 amount, bytes calldata data) external;
```

### retirementCost


```solidity
function retirementCost(uint256 amount) external view override returns (uint256 cost);
```

