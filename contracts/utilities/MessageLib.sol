// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import {BytesLib as SolByteLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

library MessageLib {

    using SolByteLib for bytes;

    // ──────────────────────────────────────────────────────────────────────────────
    // Errors
    // ──────────────────────────────────────────────────────────────────────────────

    error InvalidMessageType(bytes1 operationByte);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Constants
    //  ─────────────────────────────────────────────────────────────────────────────

    enum MessageType {
        TRANSFER,
        RETIREMENT,
        WITHDRAW_ANY,
        WITHDRAW_SPECIFIC
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Encoding Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function _encodeTransferMessage(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.TRANSFER, recipient, amount);
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
        isValidType = uint8(type(MessageType).max) >= uint8(message[0]);
        if (isValidType) messageType = MessageType(uint8(message[0]));
    }

    function _decodeTransferMessage(bytes memory message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = message.toAddress(1);
        amount = message.toUint256(21);
    }

    function _decodeRetirementMessage(bytes memory message)
        internal
        pure
        returns (address beneficiary, uint256 amount, bytes memory data)
    {
        beneficiary = message.toAddress(1);
        amount = message.toUint256(21);
        if (message.length > 53) data = message.slice(53, message.length - 53);
        else data = "";
    }

    function _decodeWithdrawAnyMessage(bytes memory message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = message.toAddress(1);
        amount = message.toUint256(21);
    }

}
