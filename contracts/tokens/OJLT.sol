// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {OAppSender} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IOFTDeployer} from "../interfaces/IOFTDeployer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {BytesLib} from "../utilities/BytesLib.sol";
import {MessageLib} from "../utilities/MessageLib.sol";


/**
 * @title Omnichain Jasmine Liquidity Token (OJLT)
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice JLT implementing LayerZero's Omnichain Fungible Token (OFT) interface
 * allowing JLT to be bridged and retired between chains.
 * @custom:security-contact Kai Aldag<kai.aldag@jasmine.energy
 */
contract OJLT is OFT, ERC20Permit /*, IJasmineRetireablePool */ {

    using BytesLib for address;
    using BytesLib for bytes32;
    using OptionsBuilder for bytes;
    using MessageLib for SendParam;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Fields
    //  ─────────────────────────────────────────────────────────────────────────────

    uint128 public retireGasLimit = 200_000;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    error InvalidInput();

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Events
    //  ─────────────────────────────────────────────────────────────────────────────

    event Retire(address indexed from, address indexed beneficiary, uint256 amount);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Setup
    //  ─────────────────────────────────────────────────────────────────────────────

    constructor(address owner)
        OFT(
            IOFTDeployer(owner).getOFTName(),
            IOFTDeployer(owner).getOFTSymbol(),
            IOFTDeployer(owner).getOFTLZEndpoint(),
            owner
        )
        ERC20Permit(IOFTDeployer(owner).getOFTName())
        Ownable(owner)
    {
        _setPeer(IOFTDeployer(owner).getRootEid(), IOFTDeployer(owner).getRootPeer());
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
            // QUESTION: Consider enforcing params' compose field is empty - as it cannot be used when a command is present.

            (bool isValid, MessageLib.MessageType messageType) = MessageLib._decodeMessageType(_sendParam.oftCmd);
            if (!isValid) revert MessageLib.InvalidMessageType(_sendParam.oftCmd[0]);

            if (messageType == MessageLib.MessageType.RETIREMENT) {
                bytes memory reasonData = MessageLib.decodeRetireCommandReason(_sendParam.oftCmd);
                message = MessageLib._encodeRetirementMessage(_sendParam.to.toAddress(), _toSD(_amountLD), reasonData);
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
        if (isValidCmd && messageType == MessageLib.MessageType.RETIREMENT) {
            (address beneficiary, uint256 amount, bytes memory data) = MessageLib._decodeRetirementMessage(_message);
            emit Retire(msg.sender, beneficiary, amount);
        }

        return super._lzSend(_dstEid, _message, _options, _fee, _refundAddress);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Retireable Pool Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function quoteRetire(uint256 reasonLength) public view returns (uint256 nativeFee) {
        bytes memory message = MessageLib._encodeRetirementMessage(address(0), 1, new bytes(reasonLength));
        bytes memory options = _buildDefaultGasOptions();

        nativeFee = _quote(
            _getRootEid(),
            message,
            options,
            false // Pay in lz token
        ).nativeFee;
    }

    /**
     * @notice Retire JLT by burning
     * @dev This request initiate a LayerZero message to execute a retirement
     *
     * @param from Owner of the JLT
     * @param beneficiary Address to receive beneficiary claim for retirement
     * @param amount Amount of JLT to retire
     * @param data Optional calldata to relay to retirement service via onERC1155Received
     */
    function retire(
        address from,
        address beneficiary,
        uint256 amount,
        bytes calldata data
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        if (from != msg.sender) _spendAllowance(from, msg.sender, amount);
        _debit(
            from,
            amount,
            amount,
            _getRootEid()
        );

        bytes memory message = MessageLib._encodeRetirementMessage(beneficiary, _toSD(amount), data);
        bytes memory options = _buildDefaultGasOptions();
        MessagingFee memory fee = MessagingFee(msg.value, 0);

        msgReceipt = _lzSend(_getRootEid(), message, options, fee, msg.sender);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Getters
    //  ─────────────────────────────────────────────────────────────────────────────

    function getRootPeer() external view returns (address rootPeer) {
        return _getRootPeerBytes().toAddress();
    }

    function _getRootPeerBytes() internal view returns (bytes32 rootPeer) {
        return _getPeerOrRevert(IOFTDeployer(owner()).getRootEid());
    }

    function _getRootEid() internal view returns (uint32 rootEid) {
        return IOFTDeployer(owner()).getRootEid();
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Owner Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    function setRetireGasLimit(uint128 _retireGasLimit) external onlyOwner {
        retireGasLimit = _retireGasLimit;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Internal Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @dev Builds retirement send params to be send by LZ
    function _buildRetireParams(address beneficiary, uint256 amount, bytes memory data)
        internal
        view
        returns (SendParam memory params)
    {
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
