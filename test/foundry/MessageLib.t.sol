// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {MessageLib} from "src/utilities/MessageLib.sol";

contract MessageLibTest is Test {

    function test_retireMessage() public {
        address benefiary = address(0x123);
        uint256 amount = 42;
        bytes memory reason = "";

        bytes memory message = MessageLib._encodeRetirementMessage(benefiary, amount, reason);

        console.logBytes(message);

        (bool isValid, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(message);
        assertTrue(isValid, "Message should be valid");
        assertEq(uint(messageType), uint(MessageLib.MessageType.RETIREMENT), "Message type should be RETIREMENT");

        (address decodedBenefiary, uint256 decodedAmount, bytes memory decodedReason) = MessageLib._decodeRetirementMessage(message);
        assertEq(decodedBenefiary, benefiary, "Message beneficiary should be correct");
        assertEq(decodedAmount, amount, "Message amount should be correct");
        assertEq(decodedReason, reason, "Message reason should be correct");
    }

    function test_retireWithReasonMessage() public {
        address benefiary = address(0x123);
        uint256 amount = 42;
        bytes memory reason = "Offset Jasmine's server usage";

        bytes memory message = MessageLib._encodeRetirementMessage(benefiary, amount, reason);

        console.logBytes(message);

        (bool isValid, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(message);
        assertTrue(isValid, "Message should be valid");
        assertEq(uint(messageType), uint(MessageLib.MessageType.RETIREMENT), "Message type should be RETIREMENT");

        (address decodedBenefiary, uint256 decodedAmount, bytes memory decodedReason) = MessageLib._decodeRetirementMessage(message);
        assertEq(decodedBenefiary, benefiary, "Message beneficiary should be correct");
        assertEq(decodedAmount, amount, "Message amount should be correct");
        assertEq(decodedReason, reason, "Message reason should be correct");
    }

    function test_transferMessage() public {
        address recipient = address(0x123);
        uint256 amount = 42;

        bytes memory message = MessageLib._encodeTransferMessage(recipient, amount);

        console.logBytes(message);

        (bool isValid, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(message);
        assertTrue(isValid, "Message should be valid");
        assertEq(uint(messageType), uint(MessageLib.MessageType.SEND), "Message type should be TRANSFER");

        (address decodedRecipient, uint256 decodedAmount) = MessageLib._decodeTransferMessage(message);
        assertEq(decodedRecipient, recipient, "Message recipient should be correct");
        assertEq(decodedAmount, amount, "Message amount should be correct");
    }

    function test_withdrawMessage() public {
        address recipient = address(0x123);
        uint256 amount = 42;

        bytes memory message = MessageLib._encodeWithdrawAnyMessage(recipient, amount);

        console.logBytes(message);

        (bool isValid, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(message);
        assertTrue(isValid, "Message should be valid");
        assertEq(uint(messageType), uint(MessageLib.MessageType.WITHDRAW_ANY), "Message type should be WITHDRAW_ANY");

        (address decodedRecipient, uint256 decodedAmount) = MessageLib._decodeWithdrawAnyMessage(message);
        assertEq(decodedRecipient, recipient, "Message recipient should be correct");
        assertEq(decodedAmount, amount, "Message amount should be correct");
    }
}
