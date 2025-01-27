// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title Jasmine Retireable Pool Interface
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Extends pools with retirement functionality and events.
 * @custom:security-contact dev@jasmine.energy
 */
interface IJasmineRetireablePool {

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Events
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice emitted when tokens from a pool are retired
     * 
     * @dev must be accompanied by a token burn event
     * 
     * @param operator Initiator of retirement
     * @param beneficiary Designate beneficiary of retirement
     * @param quantity Number of JLT being retired
     */
    event Retirement(
        address indexed operator,
        address indexed beneficiary,
        uint256 quantity
    );

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Retirement Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Burns 'quantity' of tokens from 'owner' in the name of 'beneficiary'.
     * 
     * @dev Internally, calls are routed to Retirement Service to facilitate the retirement.
     * 
     * @dev Emits a {Retirement} event.
     * 
     * @dev Requirements:
     *     - msg.sender must be approved for owner's JLTs
     *     - Owner must have sufficient JLTs
     *     - Owner cannot be zero address
     * 
     * @param from JLT owner from which to burn tokens
     * @param beneficiary Address to receive retirement acknowledgment. If none, assume msg.sender
     * @param amount Number of JLTs to withdraw
     * @param data Optional calldata to relay to retirement service via onERC1155Received
     * 
     */
    function retire(
        address from, 
        address beneficiary, 
        uint256 amount, 
        bytes calldata data
    ) external;

    /**
     * @notice Cost of retiring JLTs from pool.
     * 
     * @param amount Amount of JLTs to retire.
     * 
     * @return cost Price of retiring in JLTs.
     */
    function retirementCost(uint256 amount) external view returns (uint256 cost);
}
