// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {BytesLib as SolByteLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

library MessageLib {

    using SolByteLib for bytes;

    // ──────────────────────────────────────────────────────────────────────────────
    // Errors
    // ──────────────────────────────────────────────────────────────────────────────

    error InvalidMessageType(bytes1 operationByte);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Types
    //  ─────────────────────────────────────────────────────────────────────────────

    enum MessageType {
        NO_OP, // NOTE: Unused. Here so enum starts at 1
        SEND, // NOTE: Both SEND types are used by LZ's OFT - and are 1 & 2 respectively
        SEND_AND_CALL,
        RETIREMENT,
        WITHDRAW_ANY,
        WITHDRAW_SPECIFIC
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Byte Encoding Constants
    //  ─────────────────────────────────────────────────────────────────────────────

    uint8 private constant MSG_TYPE_OFFSET = 0;
    uint8 private constant USER_OFFSET = 1;
    uint8 private constant AMOUNT_OFFSET = 21;
    uint8 private constant DATA_OFFSET = 53;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Encoding Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function encodeRetirementCommand(bytes memory data) internal pure returns (bytes memory command) {
        return abi.encodePacked(MessageType.RETIREMENT, data);
    }

    function _encodeTransferMessage(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.SEND, recipient, amount);
    }

    function _encodeRetirementMessage(
        address beneficiary,
        uint256 amount,
        bytes memory data
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.RETIREMENT, beneficiary, amount, data);
    }

    function _encodeWithdrawAnyMessage(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.WITHDRAW_ANY, recipient, amount);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Decoding Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function _decodeMessageType(bytes memory message)
        internal
        pure
        returns (bool isValidType, MessageType messageType)
    {
        isValidType = uint8(type(MessageType).max) >= uint8(message[MSG_TYPE_OFFSET]);
        if (isValidType) messageType = MessageType(uint8(message[MSG_TYPE_OFFSET]));
        if (messageType == MessageType.NO_OP) isValidType = false;
    }

    function _decodeTransferMessage(bytes memory message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = message.toAddress(USER_OFFSET);
        amount = message.toUint256(AMOUNT_OFFSET);
    }

    function _decodeRetirementMessage(bytes memory message)
        internal
        pure
        returns (address beneficiary, uint256 amount, bytes memory data)
    {
        beneficiary = message.toAddress(USER_OFFSET);
        amount = message.toUint256(AMOUNT_OFFSET);
        if (message.length > DATA_OFFSET) data = message.slice(DATA_OFFSET, message.length - DATA_OFFSET);
        else data = "";
    }

    function _decodeWithdrawAnyMessage(bytes memory message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = message.toAddress(USER_OFFSET);
        amount = message.toUint256(AMOUNT_OFFSET);
    }

    function decodeRetireCommandReason(bytes memory message)
        internal
        pure
        returns (bytes memory reasonData)
    {
        if (message.length > 1) reasonData = message.slice(1, message.length - 1);
        else reasonData = "";
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    function hasCommand(SendParam memory params) internal pure returns (bool) {
        return params.oftCmd.length > 0;
    }

}
