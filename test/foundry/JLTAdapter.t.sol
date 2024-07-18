// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {IOAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {JasmineHubBridge} from "src/JasmineHubBridge.sol";
import {JasmineSpokeBridge} from "src/JasmineSpokeBridge.sol";
import {JasmineOFT} from "src/extensions/JasmineOFT.sol";
import {OFTPermitAdapter} from "src/extensions/OFTPermitAdapter.sol";
import {BytesLib} from "src/utilities/BytesLib.sol";

import {MockJLT} from "src/mocks/MockJLT.sol";

import "forge-std/console.sol";

/// @notice Unit test for JLTAdapter on origin chain using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract JLTAdapterTest is TestHelperOz5 {

    using OptionsBuilder for bytes;
    using BytesLib for address;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Fields
    //  ─────────────────────────────────────────────────────────────────────────────

    address owner;
    address user1;
    address user2;
    address user3;

    uint16 originEid = 1;
    uint16 destinationEid = 2;

    JasmineHubBridge hubBridge;
    JasmineSpokeBridge spokeBridge;

    MockJLT underlying;
    OFTPermitAdapter adapter;
    JasmineOFT ojlt;

    uint128 constant SEND_GAS_LIMIT = 150_000;

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Setup
    //  ─────────────────────────────────────────────────────────────────────────────

    function setUp() public virtual override {
        super.setUp();

        owner = makeAddr("OWNER");
        user1 = makeAddr("USER_1");
        user2 = makeAddr("USER_2");
        user3 = makeAddr("USER_3");

        setUpEndpoints(2, LibraryType.UltraLightNode);

        address[] memory sender = setupOApps(type(JasmineHubBridge).creationCode, 1, 1);
        address[] memory receiver = setupOApps(type(JasmineSpokeBridge).creationCode, 2, 1);
        hubBridge = JasmineHubBridge(payable(sender[0]));
        spokeBridge = JasmineSpokeBridge(payable(receiver[0]));

        underlying = new MockJLT();

        address predictedAdapter = hubBridge.predictAdapterAddress(address(underlying));
        address predictedOJLT = spokeBridge.predictOFTAddress(address(underlying));

        hubBridge.transferOwnership(owner);
        spokeBridge.transferOwnership(owner);

        vm.prank(user1);
        underlying.approve(address(predictedAdapter), type(uint256).max);
        vm.prank(user2);
        underlying.approve(address(predictedAdapter), type(uint256).max);
        vm.prank(user3);
        underlying.approve(address(predictedAdapter), type(uint256).max);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);

        vm.label(owner, "Owner");
        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        vm.label(user3, "User 3");
        vm.label(address(hubBridge), "Hub Bridge");
        vm.label(address(spokeBridge), "Spoke Bridge");
        vm.label(address(underlying), "Underlying (JLT)");
        vm.label(predictedAdapter, "JLT Adapter");
        vm.label(predictedOJLT, "OJLT");
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Utils
    //  ─────────────────────────────────────────────────────────────────────────────

    modifier configured() {
        _createAdapter();
        _createOJLT();
        _setPeer();
        _;
    }

    modifier adapterDeployed() {
        _createAdapter();
        _;
    }

    modifier ojltDeployed() {
        _createOJLT();
        _;
    }

    function _createAdapter() private {
        vm.prank(owner);
        adapter = OFTPermitAdapter(hubBridge.createAdapter(address(underlying)));
    }

    function _createOJLT() private {
        vm.startPrank(owner);
        ojlt = JasmineOFT(
            spokeBridge.createOFT(
                address(underlying), underlying.name(), underlying.symbol(), address(adapter).toBytes32()
            )
        );
        vm.stopPrank();
    }

    function _setPeer() private {
        vm.prank(owner);
        hubBridge.setAdapterPeer(address(adapter), destinationEid, address(ojlt).toBytes32());
    }

    function _mint(address to, uint256 amount) private returns (uint256) {
        return underlying.depositFrom(to, 42, amount);
    }

    function _mintAndBridge(address to, uint256 amount) private {
        _mint(to, amount);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(SEND_GAS_LIMIT, 0);
        SendParam memory params = SendParam(destinationEid, to.toBytes32(), amount, amount, options, "", "");
        MessagingFee memory fee = adapter.quoteSend(params, false);

        vm.prank(to);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
            adapter.send{value: fee.nativeFee}(params, fee, to);

        verifyPackets(destinationEid, address(ojlt));
    }

    //  ─────────────────────────────────────────────────────────────────────────────
    //  Tests
    //  ─────────────────────────────────────────────────────────────────────────────

    //  ─────────────────────────────  Setup Tests  ─────────────────────────────────  \\

    function test_setup() public {
        assertEq(hubBridge.owner(), owner);
        assertEq(spokeBridge.owner(), owner);

        assertEq(spokeBridge.getRootEid(), originEid);
    }

    function test_deployAdapter() public {
        address expected = hubBridge.predictAdapterAddress(address(underlying));

        vm.expectEmit(address(hubBridge));
        emit JasmineHubBridge.OFTAdapterCreated(address(underlying), expected);

        vm.prank(owner);
        hubBridge.createAdapter(address(underlying));

        assertEq(hubBridge.adapters(address(underlying)), expected);
    }

    function test_deployExistingAdapter() public adapterDeployed {
        vm.expectRevert(
            abi.encodeWithSelector(
                JasmineHubBridge.AdapterExists.selector,
                address(underlying),
                hubBridge.predictAdapterAddress(address(underlying))
            )
        );

        vm.prank(owner);
        hubBridge.createAdapter(address(underlying));
    }

    function test_setPeer() public adapterDeployed ojltDeployed {
        vm.expectEmit(address(adapter));
        emit IOAppCore.PeerSet(destinationEid, address(ojlt).toBytes32());

        vm.prank(owner);
        hubBridge.setAdapterPeer(address(adapter), destinationEid, address(ojlt).toBytes32());
    }

    //  ────────────────────────────────  Send Tests  ─────────────────────────────────  \\

    function test_send(uint256 amount) public configured {
        amount = bound(amount, 1, type(uint256).max / (10 ** 18));

        uint256 userBalanceBefore = underlying.balanceOf(user1);
        uint256 adapterBalanceBefore = underlying.balanceOf(address(adapter));

        uint256 jltAmount = _mint(user1, amount);
        console.log("User balance before: %s", underlying.balanceOf(user1));
        console.log("Amount to send: %s", jltAmount);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(SEND_GAS_LIMIT, 0);
        SendParam memory params =
            SendParam(destinationEid, user1.toBytes32(), jltAmount, jltAmount, options, "", "");
        MessagingFee memory fee = adapter.quoteSend(params, false);

        vm.prank(user1);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
            adapter.send{value: fee.nativeFee}(params, fee, user1);

        assertEq(userBalanceBefore, underlying.balanceOf(user1), "User Balance must decrease by amount send");
        assertEq(
            adapterBalanceBefore + jltAmount,
            underlying.balanceOf(address(adapter)),
            "Adapter should receive bridged JLT"
        );

        userBalanceBefore = ojlt.balanceOf(user1);

        console.log("User balance before: %s", ojlt.balanceOf(user1));

        // Execute delivery on destination chain
        verifyPackets(destinationEid, address(ojlt).toBytes32());

        console.log("User balance after: %s", ojlt.balanceOf(user1));
        assertEq(userBalanceBefore + jltAmount, ojlt.balanceOf(user1), "User should receive bridged JLT");
    }

    // function test_retire(uint256 amount) public {
    //     amount = bound(amount, 1, type(uint256).max / (10 ** 18));
    //     _mintAndBridge(user1, amount);
    // }

}