<h1 align="center">Jasmine Bridge</h1>

[![test](https://github.com/Jasmine-Energy/jasmine-bridge/actions/workflows/test.yml/badge.svg)](https://github.com/Jasmine-Energy/jasmine-bridge/actions/workflows/test.yml)
[![GitBook - Documentation](https://img.shields.io/badge/GitBook-Documentation-orange?logo=gitbook&logoColor=white)](https://docs.jasmine.energy/)
[![Chat](https://img.shields.io/discord/1012757430779789403)](https://discord.gg/bcGUebezJb)
[![License: BUSL 1.1](https://img.shields.io/badge/License-BUSL%201.1-blue.svg)](./LICENSE)
[![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)
[![hardhat](https://hardhat.org/buidler-plugin-badge.svg)](https://hardhat.org)

This repository contains the (work in progress) set of smart contracts enabling Jasmine Liquidity Tokens (JLT) to be bridged between EVM networks. The project makes use of Layer Zero's OFT standard to enabling cross-chain transfers.

> :warning: **Under Construction**: These contract have no been audited and are not yet live! We expect to finish development in July 2024. Stay tuned!

# contracts

- [❱ interfaces](contracts/interfaces/README.md)
  - [❱ jasmine](contracts/interfaces/jasmine/README.md)
    - [IJasmineEATBackedPool](contracts/interfaces/jasmine/IEATBackedPool.sol/interface.IJasmineEATBackedPool.md)
    - [IJasminePool](contracts/interfaces/jasmine/IJasminePool.sol/interface.IJasminePool.md)
    - [IJasmineQualifiedPool](contracts/interfaces/jasmine/IQualifiedPool.sol/interface.IJasmineQualifiedPool.md)
    - [IJasmineRetireablePool](contracts/interfaces/jasmine/IRetireablePool.sol/interface.IJasmineRetireablePool.md)
  - [IOJLTDeployer](contracts/interfaces/IOJLTDeployer.sol/interface.IOJLTDeployer.md)
  - [IRetireableOJLT](contracts/interfaces/IRetireableOJLT.sol/interface.IRetireableOJLT.md)
- [❱ mocks](contracts/mocks/README.md)
  - [MockJLT](contracts/mocks/MockJLT.sol/contract.MockJLT.md)
- [❱ tokens](contracts/tokens/README.md)
  - [JLTAdapter](contracts/tokens/JLTAdapter.sol/contract.JLTAdapter.md)
  - [OJLT](contracts/tokens/OJLT.sol/contract.OJLT.md)
- [❱ utilities](contracts/utilities/README.md)
  - [BytesLib](contracts/utilities/BytesLib.sol/library.BytesLib.md)
  - [MessageLib](contracts/utilities/MessageLib.sol/library.MessageLib.md)
  - [TransientBytes](contracts/utilities/TransientBytesLib.sol/struct.TransientBytes.md)
  - [TransientBytesLib](contracts/utilities/TransientBytesLib.sol/library.TransientBytesLib.md)
- [JasmineHubBridge](contracts/HubBridge.sol/contract.JasmineHubBridge.md)
- [JasmineSpokeBridge](contracts/SpokeBridge.sol/contract.JasmineSpokeBridge.md)

## Architecture

On the origin network, Polygon for production and Sepolia for staging, the Jasmine Hub Bridge is deployed, allowing Layer Zero OFT Adapters to be deployed per JLT contract. The OFT Adapter uses a lock-unlock pattern where JLT are held by the adapter when bridged to a spoke network.

JLT adapters have a set of peers on external networks which can receive cross-chain mint requests from the origin chain's adapter. Once minted, JLT function as they do on the origin chain, allowing retirements to occur on any chain the spoke bridge is deployed to. The one exception is that individual EAT may not be withdrawn directly; the JLT must return to the origin chain before EAT can be withdrawn.

## Usage

1. Install dependencies: `yarn`
2. Replace `.env.example` with `.env` and set a mnemonic

### Bridging JLT to Spoke Bridge

JLT can be transferred in one of two methods, using ERC-2612 signed approvals or via ERC-20 allowances for the adapter contract.

1. Allowance Signatures (ERC-2612)

All JLT contract implement ERC-2612 signature allowances, enabling off-chain signature to be generated authorizing their usage. We've made a variant of the Layer Zero standard `OFTAdapter` which supports this style of approval, allowing approval and bridging to occur in a single transaction. See [`JLTAdapter`](./contracts/extensions/JLTAdapter.sol) for implementation.

_TODO: Document process_

2. Allowance Transaction (ERC-20)

Alternatively, the `JLTAdapter` supports standard ERC-20 allowances to be used for cross-chain bridging. To do so, you may use our convenient hardhat tasks.

You may use our hardhat task `token:approve` to conviently set the adapters allowance. For the JLT-B24 token on sepolia, you may do: `npx hardhat token:approve 0x8da50f4136B49Aa1d6D8cC35c7b0D9B2fA742Ad8 0xb6Bf3224abaDf4Eb56e5C5Fca465F620D2d7d7a2 --max --network sepolia` to authorize the adapter.

Lastly, you can bridge for JLT from sepolia to Base sepolia using `oft:send`.

### Sending JLT to Hub Bridge

JLT may be sent back to the origin network using `oft:send`.

### Retiring from Spoke Bridge

> **Note:** This functionality is still under development

To execute a retirement from an external network, a quote must first be fetched. This can be done via calling `quoteRetire` on the `OJLT` contract. The quote will return the amount of native token that must be provided to the `retire` function to pay bridging fees.
