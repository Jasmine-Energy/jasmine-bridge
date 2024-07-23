// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

// TODO: Override Ownable to point to JasminePoolFactory's owner
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OApp, MessagingFee, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {IOFTDeployer} from "./interfaces/IOFTDeployer.sol";
import {OJLT} from "./tokens/OJLT.sol";
import {BytesLib} from "./utilities/BytesLib.sol";
import {Create3} from "@0xsequence/create3/contracts/Create3.sol";
import {TransientBytesLib, TransientBytes} from "./utilities/TransientBytesLib.sol";

contract JasmineSpokeBridge is OApp, IOFTDeployer {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;

    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────

    // TODO: docs
    event OFTCreated(address indexed underlying, address indexed oft);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    error OFTExists(address underlying, address oft);

    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────

    TransientBytes internal oftInitCode;

    mapping(address underlying => address oft) public ofts;

    /// @notice LayerZero endpoint ID of the root chain
    uint32 private immutable rootEid;

    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    constructor(
        address _endpoint,
        address _delegate,
        uint32 _rootEid
    ) OApp(_endpoint, _delegate) Ownable(_delegate) {
        rootEid = _rootEid;
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Admin Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    // TODO: Add decimals to OFT creation
    function createOFT(
        address _underlying,
        string memory _name,
        string memory _symbol,
        bytes32 _peer
    ) external onlyOwner returns (address oft) {
        if (ofts[_underlying] != address(0)) revert OFTExists(_underlying, ofts[_underlying]);

        _storeOFTInitData(_name, _symbol, _peer);
        oft = Create3.create3(_underlying.toBytes32(), _encodeOFTCreationCode());
        ofts[_underlying] = oft;

        emit OFTCreated(_underlying, oft);
    }

    function setOFTPeer(address _oft, uint32 _eid, bytes32 _peer) external onlyOwner {
        OJLT(_oft).setPeer(_eid, _peer);
    }

    function setDefaultRetireGasLimit(address ojlt, uint128 _gasLimit) external onlyOwner {
        OJLT(ojlt).setRetireGasLimit(_gasLimit);
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
    //  IOFTDeployer Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    //  ─────────────────────────────────  Getters  ─────────────────────────────────  \\

    function getOFTName() external view returns (string memory) {
        (string memory name,,,) = abi.decode(oftInitCode.get(), (string, string, address, bytes32));
        return name;
    }

    function getOFTSymbol() external view returns (string memory) {
        (, string memory symbol,,) = abi.decode(oftInitCode.get(), (string, string, address, bytes32));
        return symbol;
    }

    function getOFTLZEndpoint() external view returns (address) {
        (,, address lzEndpoint,) = abi.decode(oftInitCode.get(), (string, string, address, bytes32));
        return lzEndpoint;
    }

    function getRootPeer() external view returns (bytes32) {
        (,,, bytes32 rootPeer) = abi.decode(oftInitCode.get(), (string, string, address, bytes32));
        return rootPeer;
    }

    function getRootEid() external view returns (uint32) {
        return rootEid;
    }

    //  ─────────────────────────────────  Setters  ─────────────────────────────────  \\

    function _storeOFTInitData(string memory _name, string memory _symbol, bytes32 _rootPeer) internal {
        oftInitCode.set(abi.encode(_name, _symbol, endpoint, _rootPeer));
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Utility Functions
    //  ─────────────────────────────────────────────────────────────────────────────

    function predictOFTAddress(address underlying) public view returns (address) {
        return Create3.addressOf(underlying.toBytes32());
    }

    function _encodeOFTCreationCode() private view returns (bytes memory) {
        return abi.encodePacked(type(OJLT).creationCode, abi.encode(address(this)));
    }

}
