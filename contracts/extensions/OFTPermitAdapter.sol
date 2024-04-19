// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;


//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

//  ─────────────────────────────────────────────────────────────────────────────
//  Custom Errors
//  ─────────────────────────────────────────────────────────────────────────────

/**
 * @title OFTPermitAdapter
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Extension of OFTAdapter that allows ERC-2612 permit allowance to be used for OFT deposits.
 * @custom:security-contact Kai Aldag<kai.aldag@jasmine.energy
 */
contract OFTPermitAdapter is OFTAdapter, Multicall {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────


    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────


    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────


    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @dev Constructor for the OFTAdapter contract.
     * @param _token The address of the ERC-20 token to be adapted.
     * @param _lzEndpoint The LayerZero endpoint address.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    ) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate) {}

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Permit Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @dev Permits this contract to spend the holder's inner token. This is designed 
    // to be called prior to `send()` using a multicall to bypass the pre-approval tx requirement.
    function permitInnerToken(
        address holder,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(address(innerToken)).permit(holder, address(this), value, deadline, v, r, s);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Overrides
    // ──────────────────────────────────────────────────────────────────────────────

    /// @inheritdoc OFTAdapter
    function approvalRequired() external pure override virtual returns (bool) {
        return false;
    }
}