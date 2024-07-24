# MockJLT
[Git Source](https://github.com/Jasmine-Energy/jasmine-bridge/blob/3a51f99772e94ac516640d29ff82946799979f9c/contracts/mocks/MockJLT.sol)

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
function deposit(uint256, uint256 quantity) external override returns (uint256 jltQuantity);
```

### depositFrom


```solidity
function depositFrom(
    address from,
    uint256,
    uint256 quantity
) external override returns (uint256 jltQuantity);
```

### depositBatch


```solidity
function depositBatch(
    address,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
) external override returns (uint256 jltQuantity);
```

### withdraw


```solidity
function withdraw(
    address,
    uint256 quantity,
    bytes calldata
) external override returns (uint256[] memory tokenIds, uint256[] memory amounts);
```

### withdrawFrom


```solidity
function withdrawFrom(
    address spender,
    address,
    uint256 quantity,
    bytes calldata
) external override returns (uint256[] memory tokenIds, uint256[] memory amounts);
```

### withdrawSpecific


```solidity
function withdrawSpecific(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
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
function meetsPolicy(uint256) external view override returns (bool isEligible);
```

### policyForVersion


```solidity
function policyForVersion(uint8) external view override returns (bytes memory policy);
```

### retire


```solidity
function retire(address from, address beneficiary, uint256 amount, bytes calldata) external;
```

### retirementCost


```solidity
function retirementCost(uint256 amount) external view override returns (uint256 cost);
```

