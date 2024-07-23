// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {OAppSender} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IOAppMsgInspector} from
    "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {IOJLTDeployer} from "../interfaces/IOJLTDeployer.sol";
import {IRetireableOJLT} from "../interfaces/IRetireableOJLT.sol";
import {BytesLib} from "../utilities/BytesLib.sol";
import {MessageLib} from "../utilities/MessageLib.sol";

/**
 * @title Omnichain Jasmine Liquidity Token (OJLT)
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice JLT implementing LayerZero's Omnichain Fungible Token (OFT) interface
 * allowing JLT to be bridged and retired between chains.
 * @custom:security-contact dev@jasmine.energy
 */
contract OJLT is OFT, ERC20Permit, IRetireableOJLT {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;
    using BytesLib for bytes32;
    using OptionsBuilder for bytes;
    using MessageLib for SendParam;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Fields
    //  ─────────────────────────────────────────────────────────────────────────────

    uint128 public retireGasLimit = 200_000;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Events
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when owner updates the default retirement gas limit
    event RetireGasLimitUpdated(uint256 newLimit, uint256 oldLimit);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Setup
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @param owner Address permitted to take privileged actions. Should be SpokeBridge
     * as OFT's name, symbol and endpoint are retrieved from owner address.
     *
     * @dev Origin chain's corresponding peer is set during construction
     */
    constructor(address owner)
        OFT(
            IOJLTDeployer(owner).getOJLTName(),
            IOJLTDeployer(owner).getOJLTSymbol(),
            IOJLTDeployer(owner).getLZEndpoint(),
            owner
        )
        ERC20Permit(IOJLTDeployer(owner).getOJLTName())
        Ownable(owner)
    {
        _setPeer(IOJLTDeployer(owner).getOriginEid(), IOJLTDeployer(owner).getOJLTRootPeer());
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  OFT Overrides
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @inheritdoc OFTCore
    function _buildMsgAndOptions(
        SendParam calldata _sendParam,
        uint256 _amountLD
    ) internal view virtual override returns (bytes memory message, bytes memory options) {
        if (_sendParam.hasCommand()) {
            // QUESTION: Consider enforcing params' compose field is empty - as it cannot be used when a
            // command is present.

            (bool isValid, MessageLib.MessageType messageType) =
                MessageLib._decodeMessageType(_sendParam.oftCmd);
            if (!isValid) revert MessageLib.InvalidMessageType(_sendParam.oftCmd[0]);

            if (messageType == MessageLib.MessageType.RETIREMENT) {
                bytes memory reasonData = MessageLib.decodeRetireCommandReason(_sendParam.oftCmd);
                message = MessageLib._encodeRetirementMessage(
                    _sendParam.to.toAddress(), _toSD(_amountLD), reasonData
                );
            } else {
                // TODO: Implement withdrawal commands
                revert MessageLib.InvalidMessageType(_sendParam.oftCmd[0]);
            }
            options = combineOptions(_sendParam.dstEid, SEND, _sendParam.extraOptions);
            if (msgInspector != address(0)) IOAppMsgInspector(msgInspector).inspect(message, options);
        } else {
            (message, options) = super._buildMsgAndOptions(_sendParam, _amountLD);
        }
    }

    /// @inheritdoc OAppSender
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual override returns (MessagingReceipt memory receipt) {
        (bool isValidCmd, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(_message);
        // QUESTION: Consider reverting if isValidCmd is false
        if (isValidCmd && messageType == MessageLib.MessageType.RETIREMENT) {
            (address beneficiary, uint256 amount,) =
                MessageLib._decodeRetirementMessage(_message);
            emit Retirement(msg.sender, beneficiary, amount);
        }

        return super._lzSend(_dstEid, _message, _options, _fee, _refundAddress);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Retireable Pool Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Gets the native fee to send when calling `retire`
     * @dev Only computes the native token cost, does not support paying in LZ token
     *
     * @param reasonLength The length of the reason string attached to the retirement
     * measured in bytes
     *
     * @return nativeFee The amount of native token to pay when calling retire
     * measured in wei
     */
    function quoteRetire(uint256 reasonLength) public view returns (uint256 nativeFee) {
        bytes memory message = MessageLib._encodeRetirementMessage(address(0), 1, new bytes(reasonLength));
        bytes memory options = _buildDefaultGasOptions();

        nativeFee = _quote(_getOriginEid(), message, options, false).nativeFee;
    }

    /// @inheritdoc IRetireableOJLT
    function retire(
        address from,
        address beneficiary,
        uint256 amount,
        bytes calldata data
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        if (from != msg.sender) _spendAllowance(from, msg.sender, amount);
        _debit(from, amount, amount, _getOriginEid());

        if (beneficiary == address(0)) beneficiary = msg.sender;

        bytes memory message = MessageLib._encodeRetirementMessage(beneficiary, _toSD(amount), data);
        bytes memory options = _buildDefaultGasOptions();
        MessagingFee memory fee = MessagingFee(msg.value, 0);

        msgReceipt = _lzSend(_getOriginEid(), message, options, fee, msg.sender);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Getters
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @notice Address of the JLTAdapter on origin chain
    function getRootPeer() external view returns (address rootPeer) {
        return _getRootPeerBytes().toAddress();
    }

    /// @dev Internal utility that gets JLTAdapter (on origin chain) as bytes32
    function _getRootPeerBytes() internal view returns (bytes32 rootPeer) {
        return _getPeerOrRevert(IOJLTDeployer(owner()).getOriginEid());
    }

    /// @dev The LZ origin chain's endpoint ID
    function _getOriginEid() internal view returns (uint32 originEid) {
        return IOJLTDeployer(owner()).getOriginEid();
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Owner Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Allows owner to update the default retire gas limit
     * @param _retireGasLimit New default retire gas limit on origin chain
     */
    function setRetireGasLimit(uint128 _retireGasLimit) external onlyOwner {
        emit RetireGasLimitUpdated(retireGasLimit, _retireGasLimit);

        retireGasLimit = _retireGasLimit;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Internal Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @dev Builds retirement send params to be send by LZ
    function _buildRetireParams(
        address beneficiary,
        uint256 amount,
        bytes memory data
    ) internal view returns (SendParam memory params) {
        bytes memory retireCommand = MessageLib.encodeRetirementCommand(data);
        params = SendParam({
            dstEid: 0,
            to: beneficiary.toBytes32(),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: _buildDefaultGasOptions(),
            composeMsg: "",
            oftCmd: retireCommand
        });
    }

    /// @dev Builds default gas options for LZ operations on origin chain
    function _buildDefaultGasOptions() internal view returns (bytes memory options) {
        // TODO: Define as constant internal property
        options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(retireGasLimit, 0);
    }

}
