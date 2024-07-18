// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library MessageLib {

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
        bytes calldata data
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.RETIREMENT, beneficiary, amount, data);
    }

    function _encodeWithdrawAnyMessage(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes memory message) {
        return abi.encodePacked(MessageType.WITHDRAW_ANY, recipient, amount);
    }

    // function _encodeWithdrawSpecificMessage(address recipient, uint256 amount, uint256[] calldata
    // tokenIds) internal pure returns (bytes memory message) {
    //     return abi.encodePacked(MessageType.WITHDRAW_SPECIFIC, recipient, amount, tokenIds);
    // }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Decoding Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function _decodeMessageType(bytes calldata message)
        internal
        pure
        returns (bool isValidType, MessageType messageType)
    {
        isValidType = uint8(type(MessageType).max) >= uint8(message[0]);
        if (isValidType) messageType = MessageType(uint8(message[0]));
    }

    function _decodeTransferMessage(bytes calldata message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = abi.decode(message[1:33], (address));
        amount = abi.decode(message[33:], (uint256));
    }

    function _decodeRetirementMessage(bytes calldata message)
        internal
        pure
        returns (address beneficiary, uint256 amount, bytes memory data)
    {
        beneficiary = abi.decode(message[1:33], (address));
        amount = abi.decode(message[33:65], (uint256));
        data = abi.decode(message[65:], (bytes));
    }

    function _decodeWithdrawAnyMessage(bytes calldata message)
        internal
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = abi.decode(message[1:33], (address));
        amount = abi.decode(message[33:], (uint256));
    }

}
