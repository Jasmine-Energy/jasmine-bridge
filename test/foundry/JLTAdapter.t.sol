// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {IOAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRetireableOJLT} from "src/interfaces/IRetireableOJLT.sol";
// import {IJasmineRetireablePool as IRetireablePool} from "src/interfaces/jasmine/IRetireablePool.sol";

import {JasmineHubBridge} from "src/HubBridge.sol";
import {JasmineSpokeBridge} from "src/SpokeBridge.sol";
import {OJLT} from "src/tokens/OJLT.sol";
import {JLTAdapter} from "src/tokens/JLTAdapter.sol";
import {BytesLib} from "src/utilities/BytesLib.sol";
import {MessageLib} from "src/utilities/MessageLib.sol";

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
    JLTAdapter adapter;
    OJLT ojlt;

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
        address predictedOJLT = spokeBridge.predictOJLTAddress(address(underlying));

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
        adapter = JLTAdapter(hubBridge.createAdapter(address(underlying)));
    }

    function _createOJLT() private {
        vm.startPrank(owner);
        ojlt = OJLT(
            spokeBridge.createOJLT(
                address(underlying), address(adapter), underlying.name(), underlying.symbol()
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

        assertEq(spokeBridge.getOriginEid(), originEid);
    }

    function test_deployAdapter() public {
        address expected = hubBridge.predictAdapterAddress(address(underlying));

        vm.expectEmit(address(hubBridge));
        emit JasmineHubBridge.JLTAdapterCreated(address(underlying), expected);

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

    function test_deployOJLT() public adapterDeployed {
        address expected = spokeBridge.predictOJLTAddress(address(underlying));

        vm.expectEmit(address(spokeBridge));
        emit JasmineSpokeBridge.OJLTCreated(address(underlying), expected);

        vm.startPrank(owner);
        address deployedOJLT = spokeBridge.createOJLT(
            address(underlying), address(adapter), underlying.name(), underlying.symbol()
        );
        vm.stopPrank();

        assertEq(deployedOJLT, expected, "Address should match predicted address");
        assertEq(
            OJLT(deployedOJLT).peers(originEid),
            address(adapter).toBytes32(),
            "OJLT should have origin peer set"
        );
    }

    //  ────────────────────────────  Conversion Tests  ───────────────────────────────  \\

    function test_localDecimals() public configured {
        assertEq(adapter.decimalConversionRate(), 1);
        assertEq(ojlt.decimalConversionRate(), 1);

        assertEq(underlying.decimals(), 6);
        assertEq(ojlt.decimals(), 6);
    }

    //  ────────────────────────────────  Send Tests  ─────────────────────────────────  \\

    function test_send(uint256 amount) public configured {
        // NOTE: LZ encodes amount to 64 bits of precision. Amount must be less than 2^64 - 1.
        // TODO: Add check in both adapter and OJLT to ensure amount is less than 2^64 - 1.
        amount = bound(amount, 1, type(uint64).max - 1);

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
        assertEq(
            oftReceipt.amountSentLD,
            oftReceipt.amountReceivedLD,
            "Sent and received amounts should be equal in receipt"
        );

        userBalanceBefore = ojlt.balanceOf(user1);

        console.log("User balance before: %s", ojlt.balanceOf(user1));

        // Execute delivery on destination chain
        verifyPackets(destinationEid, address(ojlt).toBytes32());

        console.log("User balance after: %s", ojlt.balanceOf(user1));
        assertEq(userBalanceBefore + jltAmount, ojlt.balanceOf(user1), "User should receive bridged JLT");
    }

    function test_retireViaSend(uint256 amount) public configured {
        amount = bound(amount, 1, type(uint64).max - 1);
        _mintAndBridge(user1, amount);

        bytes memory reasonData = "";
        uint256 userBalanceBefore = ojlt.balanceOf(user1);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(SEND_GAS_LIMIT, 0);
        bytes memory retireCommand = MessageLib.encodeRetirementCommand(reasonData);

        SendParam memory params =
            SendParam(originEid, user1.toBytes32(), amount, amount, options, "", retireCommand);
        MessagingFee memory fee = ojlt.quoteSend(params, false);

        vm.expectEmit(address(ojlt));
        emit IERC20.Transfer(user1, address(0), amount);
        vm.expectEmit(address(ojlt));
        emit IRetireableOJLT.Retirement(user1, user1, amount);

        vm.prank(user1);
        ojlt.send{value: fee.nativeFee}(params, fee, user1);

        // NOTE: These aren't working as expected due to verify packets numerous steps
        // vm.expectEmit(address(underlying));
        // emit IERC20.Transfer(address(adapter), address(0), amount);
        // vm.expectEmit(address(underlying));
        // emit IRetireablePool.Retirement(address(adapter), user1, amount);

        // Execute delivery on destination chain
        verifyPackets(originEid, address(adapter).toBytes32());
    }

    function test_retire(uint256 amount) public configured {
        amount = bound(amount, 1, type(uint64).max - 1);
        _mintAndBridge(user1, amount);

        bytes memory reasonData = "";

        uint256 retireFee = ojlt.quoteRetire(reasonData.length);

        vm.expectEmit(address(ojlt));
        emit IERC20.Transfer(user1, address(0), amount);
        vm.expectEmit(address(ojlt));
        emit IRetireableOJLT.Retirement(user1, user1, amount);

        vm.prank(user1);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
            ojlt.retire{value: retireFee}(user1, user1, amount, reasonData);

        // vm.expectEmit(address(underlying));
        // emit IERC20.Transfer(address(adapter), address(0), amount);
        // vm.expectEmit(address(underlying));
        // emit IRetireablePool.Retirement(address(adapter), user1, amount);

        // Execute delivery on destination chain
        verifyPackets(originEid, address(adapter).toBytes32());
    }

    //  ────────────────────────────────  Owner Tests  ─────────────────────────────────  \\

    function test_setGasLimit(uint128 gasLimit) public configured {
        vm.prank(owner);
        spokeBridge.setDefaultRetireGasLimit(address(ojlt), gasLimit);

        assertEq(ojlt.retireGasLimit(), gasLimit);
    }

}
