// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import {OFTAdapter} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {OApp, MessagingFee, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {MessageLib} from "../utilities/MessageLib.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IJasminePool} from "../interfaces/jasmine/IJasminePool.sol";
import {JasmineErrors} from "@jasmine-energy/pools-contracts/contracts/interfaces/errors/JasmineErrors.sol";


/**
 * @title JLT Adapter
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Modified OFTAdapter (from LayerZero) enabling ERC-2612 allowance signatures
 * as well as custom cross-chain retirement logic.
 * @custom:security-contact Kai Aldag<kai.aldag@jasmine.energy
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

    /**
     * @dev
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        // NOTE: If extra data provided, parse and execute operation
        if (_extraData.length != 0) {
            _executeLzMessage(_extraData);
            // QUESTION: Emit here or in _executeLzMessage?
            emit OFTReceived(
                _guid, _origin.srcEid, payload.sendTo().bytes32ToAddress(), _toLD(payload.amountSD())
            );
        } else {
            super._lzReceive(_origin, _guid, payload, _executor, _extraData);
        }
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Internal Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    //  ─────────────────────────────  Message Parsing  ─────────────────────────────  \\

    function _executeLzMessage(bytes calldata message) internal {
        (bool isValid, MessageLib.MessageType operation) = message._decodeMessageType();
        if (!isValid) revert MessageLib.InvalidMessageType(message[0]);

        if (operation == MessageLib.MessageType.TRANSFER) {
            // TODO: Implement
        } else if (operation == MessageLib.MessageType.RETIREMENT) {
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

    function _retireJLT(address beneficiary, uint256 amount, bytes memory data) internal {
        IJasminePool(address(innerToken)).retire(address(this), beneficiary, amount, data);
    }

    function _transferJLT(address recipient, uint256 amount) internal {
        // TODO: Transfer JLT
    }

    function _withdrawJLT(address recipient, uint256 amount) internal {
        // TODO: Withdraw JLT
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Overrides
    //  ─────────────────────────────────────────────────────────────────────────────

    // function _debit(
    //     address _from,
    //     uint256 _amountLD,
    //     uint256 _minAmountLD,
    //     uint32 _dstEid
    // ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {

    // }

    function _debitView(
        uint256 _amountLD,
        uint256,
        uint32
    ) internal view virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        return (_amountLD, _amountLD);
    }

}
