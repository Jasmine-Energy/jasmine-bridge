// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import {OApp, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OAppReceiver} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Create3} from "@0xsequence/create3/contracts/Create3.sol";

import {JLTAdapter} from "./tokens/JLTAdapter.sol";
import {BytesLib} from "./utilities/BytesLib.sol";

/**
 * @title Jasmine Hub Bridge
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Responsible for deploying new JLT adapters which enable JLT to be bridged
 * to and from other networks
 * @custom:security-contact dev@jasmine.energy
 */
contract JasmineHubBridge is OApp {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;

    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Emitted when a new adapter is deployed for a given JLT
     *
     * @param underlying Address of the JLT for which an adapter was created
     * @param adapter Address of the new JLT adapter which can bridge JLT
     */
    event JLTAdapterCreated(address indexed underlying, address indexed adapter);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Reverted when trying to deploy a JLTAdapter which already exists
     * @param underlying The JLT contract for which deployment was attempted
     * @param adapter The existing JLTAdapter contract
     */
    error AdapterExists(address underlying, address adapter);

    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Maps a JLT address to its corresponding JLTAdapter
    mapping(address underlying => address oftAdapter) public adapters;

    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @param _endpoint LZ endpoint (V2) to use when construction JLTAdapters
     * @param _delegate Owner address capable of deploying new adapters and updating
     * LZ configurations
     */
    constructor(address _endpoint, address _delegate) OApp(_endpoint, _delegate) Ownable(_delegate) {}

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Admin Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Allows owner to deploy a new JLT adapter deterministically
     * @dev Creating an adapter does not configure its peers. This must be done seperately
     *
     * @param underlying JLT address for which to create a JLTAdapter
     *
     * @return adapter Address of the newly deploy JLTAdapter
     */
    function createAdapter(address underlying) external onlyOwner returns (address adapter) {
        if (adapters[underlying] != address(0)) {
            revert AdapterExists(underlying, adapters[underlying]);
        }

        adapter = Create3.create3(underlying.toBytes32(), encodeAdapterCreationCode(underlying));
        adapters[underlying] = adapter;

        emit JLTAdapterCreated(underlying, adapter);
    }

    /**
     * @notice Allows owner to set an existing JLTAdapters peer on a new network,
     * functionally allowing JLTs to be bridged to the new network
     *
     * @param _adapter Address of the existing JLTAdapter on which to add new peer
     * @param _eid LZ endpoint ID of the new chain containing the peer
     * @param _peer Address of the peer on the destination chain, encoded as bytes32
     */
    function setAdapterPeer(address _adapter, uint32 _eid, bytes32 _peer) external onlyOwner {
        JLTAdapter(_adapter).setPeer(_eid, _peer);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  OApp Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @inheritdoc OAppReceiver
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        // no-op
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Utility Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deterministically computes the expected JLTAdapter address for a given
     * JLT. Note, the adapter is not guaranteed to exist.
     *
     * @param underlying Address of the JLT to derive adapter address
     *
     * @return adapter Expected or existing address of the `underlying`'s adapter
     */
    function predictAdapterAddress(address underlying) public view returns (address adapter) {
        return Create3.addressOf(underlying.toBytes32());
    }

    /**
     * @dev Encodes the JLTAdapter's creation code to be used by CREATE3. Note, address
     * of this contract, owner field, must explicitly be provided due as msg.sender is
     * the CREATE3 factory during adapter construction
     *
     * @param underlying Address of the JLT for which to encode creation code
     *
     * @return creationCode Deployable bytecode for the new JLTAdapter with constructor
     * arguments preconfigured
     */
    function encodeAdapterCreationCode(address underlying) private view returns (bytes memory creationCode) {
        return
            abi.encodePacked(type(JLTAdapter).creationCode, abi.encode(underlying, endpoint, address(this)));
    }

}
