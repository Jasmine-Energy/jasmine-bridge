// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

// TODO: Override Ownable to point to JasminePoolFactory's owner
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OFTPermitAdapter } from "./extensions/OFTPermitAdapter.sol";
import { BytesLib } from "./utilities/Bytes.sol";
import { Create3 } from "@0xsequence/create3/contracts/Create3.sol";


contract JasmineBridge is OApp {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;

    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────

    /// TODO: docs
    event OFTAdapterCreated(address indexed underlying, address indexed adapter);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    error AdapterExists(address underlying, address adapter);

    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────

    mapping(address underlying => address oftAdapter) public adapters;

    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    constructor(address _endpoint, address _delegate) OApp(_endpoint, _delegate) Ownable(_delegate) {}

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Admin Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    function createAdapter(address underlying) external onlyOwner returns (address adapter) {
        if (adapters[underlying] != address(0)) revert AdapterExists(underlying, adapters[underlying]);

        adapter = Create3.create3(underlying.toBytes32(), encodeAdapterCreationCode(underlying));
        adapters[underlying] = adapter;

        emit OFTAdapterCreated(underlying, adapter);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  LayerZero Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        // data = abi.decode(payload, (string));
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Utility Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function predictAdapterAddress(address underlying) public view returns (address) {
        return Create3.addressOf(underlying.toBytes32());
    }

    function encodeAdapterCreationCode(address underlying) private view returns (bytes memory) {
        return abi.encodePacked(
            type(OFTPermitAdapter).creationCode,
            abi.encode(underlying, endpoint, address(this))
        );
    }
}
