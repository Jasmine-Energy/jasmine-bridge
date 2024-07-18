// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {IOFTDeployer} from "../interfaces/IOFTDeployer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IJasmineRetireablePool} from "../interfaces/IRetireablePool.sol";
import {BytesLib} from "../utilities/BytesLib.sol";
import {MessageLib} from "../utilities/MessageLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


/**
 * @title Omnichain Jasmine Liquidity Token (OJLT)
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice JLT implementing LayerZero's Omnichain Fungible Token (OFT) interface
 * allowing JLT to be bridged and retired between chains.
 * @custom:security-contact Kai Aldag<kai.aldag@jasmine.energy
 */
contract OJLT is OFT, ERC20Permit /*, IJasmineRetireablePool */ {

    using BytesLib for bytes32;
    using OptionsBuilder for bytes;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Fields
    //  ─────────────────────────────────────────────────────────────────────────────

    uint16 public retirementFeeBips = 0;
    uint128 public retireGasLimit = 200_000;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    error InvalidInput();

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
    //  Retireable Pool Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function quoteRetire() public view returns (MessagingFee memory fee) {
        fee = _quote(
            _getRootEid(),
            "",
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(retireGasLimit, 0),
            false // Pay in lz token
        );
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

        (uint256 amountSentLD, uint256 amountReceivedLD) =
            _debit(from, amount, _calculateMinRetireLD(amount), _getRootEid());
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(retireGasLimit, 0);
        SendParam memory sendParams = SendParam({
            dstEid: _getRootEid(),
            to: _getRootPeerBytes(),
            amountLD: amountSentLD,
            minAmountLD: amountReceivedLD,
            extraOptions: options,
            composeMsg: "",
            oftCmd: MessageLib._encodeRetirementMessage(beneficiary, amount, data)
        });

        MessagingFee memory fee = _quote(
            sendParams.dstEid,
            sendParams.composeMsg,
            options,
            false // Pay in lz token
        );

        // If msg.value is less than native, check quote for lz token, else revert
        if (msg.value < fee.nativeFee) {
            fee = _quote(sendParams.dstEid, sendParams.composeMsg, options, true);
            if (msg.value < fee.nativeFee) revert NotEnoughNative(msg.value);
        }

        // NOTE: See OFTMsgCodec.encode. As no composed message is included, simple encode the to
        // and amount.
        bytes memory message = abi.encodePacked(sendParams.to, _toSD(amountReceivedLD));

        // NOTE: Because we have no enforced options, we can simply pass the options as is.
        msgReceipt = _lzSend(sendParams.dstEid, message, options, fee, msg.sender);
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, sendParams.dstEid, from, amountSentLD, amountReceivedLD);
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

    function setRetirementFeeBips(uint16 _retirementFeeBips) external onlyOwner {
        if (_retirementFeeBips > 1000) revert InvalidInput();
        retirementFeeBips = _retirementFeeBips;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Internal Utilities
    //  ─────────────────────────────────────────────────────────────────────────────

    function _calculateMinRetireLD(uint256 amount) internal view returns (uint256 minAmountLD) {
        if (retirementFeeBips > 0) {
            minAmountLD = Math.mulDiv(amount, (10_000 - retirementFeeBips), 10_000);
        } else {
            minAmountLD = amount;
        }
    }

    function _payNative(uint256 _nativeFee) internal virtual override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

}
