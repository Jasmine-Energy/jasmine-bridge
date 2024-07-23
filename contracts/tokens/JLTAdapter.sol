// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import {OFTAdapter} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {MessageLib} from "../utilities/MessageLib.sol";
import {IJasminePool} from "../interfaces/jasmine/IJasminePool.sol";

/**
 * @title JLT Adapter
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Modified OFTAdapter (from LayerZero) enabling ERC-2612 allowance signatures
 * as well as custom cross-chain retirement logic.
 * @custom:security-contact dev@jasmine.energy
 */
contract JLTAdapter is OFTAdapter, Multicall {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using MessageLib for bytes;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

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

    //  ─────────────────────────────────────────────────────────────────────────────
    //  LayerZero Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @inheritdoc OFTCore
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        (bool isValid, MessageLib.MessageType operation) = payload._decodeMessageType();
        if (!isValid) revert MessageLib.InvalidMessageType(payload[0]);

        if (operation == MessageLib.MessageType.SEND || operation == MessageLib.MessageType.SEND_AND_CALL) {
            super._lzReceive(_origin, _guid, payload, _executor, _extraData);
        } else if (operation == MessageLib.MessageType.RETIREMENT) {
            (address beneficiary, uint256 amount, bytes memory data) = payload._decodeRetirementMessage();
            _retireJLT(beneficiary, amount, data);
        } else {
            revert MessageLib.InvalidMessageType(payload[0]);
        }
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Internal Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    //  ─────────────────────────────  Message Parsing  ─────────────────────────────  \\

    /**
     * @dev If payload from _lzReceive requires custom business logic (ie. retirement
     * or EAT withdraws), this function will parse and handle execution.
     */
    function _executeLzMessage(bytes calldata message) internal {
        (bool isValid, MessageLib.MessageType operation) = message._decodeMessageType();
        if (!isValid) revert MessageLib.InvalidMessageType(message[0]);

        if (operation == MessageLib.MessageType.RETIREMENT) {
            (address beneficiary, uint256 amount, bytes memory data) = message._decodeRetirementMessage();
            _retireJLT(beneficiary, amount, data);
        } else if (operation == MessageLib.MessageType.WITHDRAW_ANY) {
            // TODO: Implement
        } else if (operation == MessageLib.MessageType.WITHDRAW_SPECIFIC) {
            // TODO: Implement
        } else {
            revert MessageLib.InvalidMessageType(message[0]);
        }
    }

    //  ────────────────────────────  JLT Interactions  ─────────────────────────────  \\

    /// @dev Executes a JLT retirement using custodied assets with given fields
    function _retireJLT(address beneficiary, uint256 amount, bytes memory data) internal {
        IJasminePool(address(innerToken)).retire(address(this), beneficiary, amount, data);
    }

    /// @dev Executes an EAT withdrawal using custodied JLT
    function _withdrawAny(address recipient, uint256 amount) internal {
        // TODO: Withdraw JLT
    }

}
