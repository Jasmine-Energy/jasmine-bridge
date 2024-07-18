// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {JasmineHubBridge} from "src/JasmineHubBridge.sol";
import {JasmineSpokeBridge} from "src/JasmineSpokeBridge.sol";
import {JasmineOFT} from "src/extensions/JasmineOFT.sol";
import {OFTPermitAdapter} from "src/extensions/OFTPermitAdapter.sol";

import "forge-std/console.sol";

/// @notice Unit test for OJLT contract on destination chain using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract OJLTTest is TestHelperOz5 {}
