// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

//  ─────────────────────────────────────────────────────────────────────────────
//  Imports
//  ─────────────────────────────────────────────────────────────────────────────

import {OApp, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OAppReceiver} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Create3} from "@0xsequence/create3/contracts/Create3.sol";

import {IOJLTDeployer} from "./interfaces/IOJLTDeployer.sol";
import {OJLT} from "./tokens/OJLT.sol";
import {BytesLib} from "./utilities/BytesLib.sol";
import {TransientBytes} from "./utilities/TransientBytesLib.sol";

/**
 * @title Jasmine Spoke Bridge
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Responsible for deploying new omnichain JLT (OJLT) contracts on destination
 * networks. OJLT can be sent and received between chains, and do JLT specific operations
 * such as cross-chain retirements and EAT withdrawals.
 * @custom:security-contact dev@jasmine.energy
 */
contract JasmineSpokeBridge is OApp, IOJLTDeployer {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;

    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Emitted when a new OJLT is deployed, allowing the underlying JLT
     * to be bridged to this network
     *
     * @param underlying Address of the underlying JLT on the origin chain
     * @param ojlt Address of the newly deployed OJLT
     */
    event OJLTCreated(address indexed underlying, address indexed ojlt);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Reverted when trying to deploy an OJLT which already exists
     *
     * @param underlying Address of the underlying JLT on the origin chain
     * @param ojlt Address of the existing OJLT contract
     */
    error OJLTExists(address underlying, address ojlt);

    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Maps a JLT address (from origin chain) to its corresponding OJLT address
    mapping(address underlying => address ojlt) public ojlts;

    /**
     * @dev During construction, arguments are allocated to transient storage rather
     * than the stack, allowing for more data to be used. This field is used solely
     * during construction to access these parameters.
     */
    TransientBytes internal _ojltInitCode;

    /// @dev LZ endpoint ID of the origin chain - which holds to underlying JLT
    uint32 private immutable _originEid;

    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @param endpoint_ LZ endpoint (V2) to use when construction OJLTs
     * @param delegate_ Owner address capable of deploying new OJLTs and updating
     * LZ configurations
     * @param originEid_ LZ endpoint ID of the origin chain
     */
    constructor(
        address endpoint_,
        address delegate_,
        uint32 originEid_
    ) OApp(endpoint_, delegate_) Ownable(delegate_) {
        _originEid = originEid_;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Admin Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Allows owner to deploy new OJLT
     *
     * @param _underlying Address of the underlying JLT on the origin chain
     * @param _peer Address of the corresponding JLTAdapter on the origin chain
     * @param _name ERC-20 token name of the new OJLT. Should match underlying's name
     * @param _symbol ERC-20 token symbol of the new OJLT. Should match underlying's symbol
     */
    function createOJLT(
        address _underlying,
        address _peer,
        string memory _name,
        string memory _symbol
    ) external onlyOwner returns (address oft) {
        if (ojlts[_underlying] != address(0)) revert OJLTExists(_underlying, ojlts[_underlying]);

        _storeOJLTInitData(_name, _symbol, _peer.toBytes32());
        oft = Create3.create3(_underlying.toBytes32(), _encodeOJLTCreationCode());
        ojlts[_underlying] = oft;

        emit OJLTCreated(_underlying, oft);
    }

    /**
     * @notice Allows owner to set a new LZ peer for an OJLT
     *
     * @param _ojlt Address of the existing OJLT for which to set peer
     * @param _eid LZ endpoint ID of the peer
     * @param _peer Address of the peer contract as bytes32 (to support non-EVM networks)
     */
    function setOJLTPeer(address _ojlt, uint32 _eid, bytes32 _peer) external onlyOwner {
        OJLT(_ojlt).setPeer(_eid, _peer);
    }

    /**
     * @notice Allows owner to update an OJLT's default retirement gas limit
     *
     * @param _ojlt Address of the deployed OJLT for which to update retirement gas limit
     * @param _gasLimit New gas default limit for retirements
     */
    function setDefaultRetireGasLimit(address _ojlt, uint128 _gasLimit) external onlyOwner {
        OJLT(_ojlt).setRetireGasLimit(_gasLimit);
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  IOJLTDeployer Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    /// @dev Used to set new OJLT's token name during construction
    function getOJLTName() external view returns (string memory name) {
        (string memory name,,,) = abi.decode(_ojltInitCode.get(), (string, string, address, bytes32));
        return name;
    }

    /// @dev Used to set new OJLT's token symbol during construction
    function getOJLTSymbol() external view returns (string memory symbol) {
        (, string memory symbol,,) = abi.decode(_ojltInitCode.get(), (string, string, address, bytes32));
        return symbol;
    }

    /// @dev Used to set new OJLT's LZ endpoint (V2) address
    function getLZEndpoint() external view returns (address endpoint) {
        (,, address lzEndpoint,) = abi.decode(_ojltInitCode.get(), (string, string, address, bytes32));
        return lzEndpoint;
    }

    /// @dev Used to set new OJLT's LZ endpoint ID for the origin chain
    function getOriginEid() external view returns (uint32 eid) {
        return _originEid;
    }

    /// @dev Used to set new OJLT's origin chain peer
    function getOJLTRootPeer() external view returns (bytes32 rootPeer) {
        (,,, bytes32 rootPeer) = abi.decode(_ojltInitCode.get(), (string, string, address, bytes32));
        return rootPeer;
    }

    //  ─────────────────────────────────  Setters  ─────────────────────────────────  \\

    /// @dev Stores OJLT's constructor arugments to transient storage for later retrieval
    function _storeOJLTInitData(string memory _name, string memory _symbol, bytes32 _rootPeer) internal {
        _ojltInitCode.set(abi.encode(_name, _symbol, endpoint, _rootPeer));
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
     * @notice Deterministically computes the expected OJLT address for a given
     * JLT. Note, the OJLT is not guaranteed to exist.
     *
     * @param underlying Address on origin network of the JLT to derive OJLT address
     *
     * @return ojlt Expected or existing address of the OJLT contract
     */
    function predictOJLTAddress(address underlying) public view returns (address ojlt) {
        return Create3.addressOf(underlying.toBytes32());
    }

    /**
     * @dev Encodes the OJLT's creation code to be used by CREATE3. Note, address
     * of this contract, owner field, must explicitly be provided due as msg.sender is
     * the CREATE3 factory during adapter construction
     *
     * @return creationCode Deployable bytecode for the new OJLT with constructor
     * arguments preconfigured
     */
    function _encodeOJLTCreationCode() private view returns (bytes memory creationCode) {
        return abi.encodePacked(type(OJLT).creationCode, abi.encode(address(this)));
    }

}
