// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {IJasminePool} from "../interfaces/jasmine/IJasminePool.sol";

/// @dev Internal Mock JLT for testing
contract MockJLT is IJasminePool, ERC20Permit {

    constructor() ERC20("Jasmine Liquidity Token", "JLT") ERC20Permit("Jasmine Liquidity Token") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function deposit(uint256, uint256 quantity) external override returns (uint256 jltQuantity) {
        _mint(msg.sender, quantity);
        return quantity;
    }

    function depositFrom(
        address from,
        uint256,
        uint256 quantity
    ) external override returns (uint256 jltQuantity) {
        _mint(from, quantity);
        return quantity;
    }

    function depositBatch(
        address,
        uint256[] calldata tokenIds,
        uint256[] calldata quantities
    ) external override returns (uint256 jltQuantity) {
        uint256 totalQuantity;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalQuantity += quantities[i];
        }
        _mint(msg.sender, totalQuantity);
        return totalQuantity;
    }

    function withdraw(
        address,
        uint256 quantity,
        bytes calldata
    ) external override returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        _burn(msg.sender, quantity);
        return (tokenIds, amounts);
    }

    function withdrawFrom(
        address spender,
        address,
        uint256 quantity,
        bytes calldata
    ) external override returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        _burn(spender, quantity);
        return (tokenIds, amounts);
    }

    function withdrawSpecific(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override {
        // no-op
    }

    function withdrawalCost(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external view override returns (uint256 cost) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            cost += amounts[i];
        }
    }

    function withdrawalCost(uint256 amount) external view override returns (uint256 cost) {
        return amount;
    }

    function meetsPolicy(uint256) external view override returns (bool isEligible) {
        return true;
    }

    function policyForVersion(uint8) external view override returns (bytes memory policy) {
        return abi.encodePacked("NO_POLICY");
    }

    function retire(address from, address beneficiary, uint256 amount, bytes calldata) external {
        emit Retirement(from, beneficiary, amount);

        _burn(from, amount);
    }

    function retirementCost(uint256 amount) external view override returns (uint256 cost) {
        return amount;
    }

}
