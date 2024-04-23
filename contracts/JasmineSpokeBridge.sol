// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

// TODO: Override Ownable to point to JasminePoolFactory's owner
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { JasmineOFT } from "./extensions/JasmineOFT.sol";
import { BytesLib } from "./utilities/BytesLib.sol";
import { Create3 } from "@0xsequence/create3/contracts/Create3.sol";
import { TransientBytesLib, TransientBytes } from "./utilities/TransientBytesLib.sol";


contract JasmineSpokeBridge is OApp {

    // ──────────────────────────────────────────────────────────────────────────────
    // Libraries
    // ──────────────────────────────────────────────────────────────────────────────

    using BytesLib for address;

    // ──────────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────────

    /// TODO: docs
    event OFTCreated(address indexed underlying, address indexed adapter);

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Custom Errors
    //  ─────────────────────────────────────────────────────────────────────────────

    error OFTExists(address underlying, address adapter);

    // ──────────────────────────────────────────────────────────────────────────────
    // Fields
    // ──────────────────────────────────────────────────────────────────────────────

    TransientBytes internal oftInitCode;

    mapping(address underlying => address oftAdapter) public ofts;

    // ──────────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────────

    constructor(address _endpoint, address _delegate) OApp(_endpoint, _delegate) Ownable(_delegate) {}

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Admin Functionality
    //  ─────────────────────────────────────────────────────────────────────────────

    function createOFT(address _underlying, string memory _name, string memory _symbol, uint32 _eid, bytes32 _peer) external onlyOwner {
        if (ofts[_underlying] != address(0)) revert OFTExists(_underlying, ofts[_underlying]);

        storeOFTInitData(_name, _symbol);
        address oft = Create3.create3(_underlying.toBytes32(), encodeOFTCreationCode());
        ofts[_underlying] = oft;

        if (_peer != bytes32(0)) JasmineOFT(oft).setPeer(_eid, _peer);

        emit OFTCreated(_underlying, oft);
    }

    function setOFTPeer(address _oft, uint32 _eid, bytes32 _peer) external onlyOwner {
        JasmineOFT(_oft).setPeer(_eid, _peer);
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

    function predictOFTAddress(address underlying) public view returns (address) {
        return Create3.addressOf(underlying.toBytes32());
    }

    function encodeOFTCreationCode() private view returns (bytes memory) {
        return abi.encodePacked(
            type(JasmineOFT).creationCode,
            abi.encode(address(this))
        );
    }

    function getOFTName() external view returns (string memory) {
        (string memory name, , ) = abi.decode(oftInitCode.get(), (string, string, address));
        return name;
    }

    function getOFTSymbol() external view returns (string memory) {
        (, string memory symbol, ) = abi.decode(oftInitCode.get(), (string, string, address));
        return symbol;
    }

    function getOFTLZEndpoint() external view returns (address) {
        (, , address lzEndpoint) = abi.decode(oftInitCode.get(), (string, string, address));
        return lzEndpoint;
    }

    function storeOFTInitData(string memory _name, string memory _symbol) internal {
        oftInitCode.set(abi.encode(_name, _symbol, endpoint));
    }
}
