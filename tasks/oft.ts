import assert from 'assert'

import { task } from 'hardhat/config'

import { Options } from '@layerzerolabs/lz-v2-utilities'

import { explorerLink, hyperlink } from './utils'

import type { HardhatRuntimeEnvironment, HttpNetworkConfig, TaskArguments } from 'hardhat/types'

const logLayerZeroTx = (tx: string | { hash: string }, isTestnet: boolean) => {
    const txHash = typeof tx === 'string' ? tx : tx.hash
    return hyperlink(`https://${isTestnet ? 'testnet.' : ''}layerzeroscan.com/tx/${txHash}`, txHash)
}

// TODO: Assign task names to string constants

task('create:adapter', 'Creates a new OFT adapter on Hub bridge')
    .addPositionalParam('underlying', 'Address of the underlying token')
    .setAction(
        async (
            { underlying }: TaskArguments,
            { network, deployments, ethers, getNamedAccounts }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const ownerSigner = await ethers.getSigner(owner)

            if (network.name !== 'sepolia' && network.name !== 'polygon') {
                throw new Error('This task can only be run on Amoy or Polygon network')
            }
            const contractName = 'JasmineHubBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            const tx = await bridgeContract.createAdapter(underlying)
            const result = await tx.wait()
            const adapterAddress = result.events
                ?.find((e: { event: string }) => e.event === 'OFTAdapterCreated')
                ?.args?.at(1)
            console.log(
                `Adapter created: ${explorerLink(network, adapterAddress)} for: ${explorerLink(network, underlying)} at tx: ${explorerLink(network, result.transactionHash)}`
            )

            return adapterAddress
        }
    )

task('create:oft', 'Creates an OFT token on Spoke bridge')
    .addPositionalParam('underlying', 'Address of the underlying token')
    .setAction(
        async (
            { underlying }: TaskArguments,
            { network, deployments, ethers, getNamedAccounts, config }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const ownerSigner = await ethers.getSigner(owner)

            if (network.name !== 'baseSepolia' && network.name !== 'base') {
                throw new Error('This task can only be run on BaseSepolia network')
            }

            // Read token info from origin chain
            const hubNetwork = network.live ? 'polygon' : 'sepolia'
            const provider = new ethers.providers.JsonRpcProvider(
                (config.networks[hubNetwork] as HttpNetworkConfig).url
            )
            const underlyingContract = (await ethers.getContractAt('IERC20Metadata', underlying)).connect(provider)
            const name = await underlyingContract.name()
            const symbol = await underlyingContract.symbol()
            const decimals = await underlyingContract.decimals()
            console.log(`Token info: ${name} (${symbol}) with ${decimals} decimals`)
            const hubDeployment = require(`${config.paths.root}/deployments/${hubNetwork}/JasmineHubBridge.json`)
            console.log(`Hub deployment: ${hubDeployment.address}`)
            const hubBridgeContract = (await ethers.getContractAt('JasmineHubBridge', hubDeployment.address)).connect(
                provider
            )
            const adapter = await hubBridgeContract.adapters(underlying)
            console.log(`Adapter: ${adapter}`)
            const peer = ethers.utils.hexlify(ethers.utils.zeroPad(adapter, 32))

            const contractName = 'JasmineSpokeBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            const tx = await bridgeContract.createOFT(underlying, name, symbol, peer)
            const result = await tx.wait()
            const oftAddress = result.events?.find((e: { event: string }) => e.event === 'OFTCreated')?.args?.at(1)
            console.log(
                `OFT created: ${explorerLink(network, oftAddress)} for: ${explorerLink(network, underlying)} at tx: ${explorerLink(network, result.transactionHash)}`
            )

            return oftAddress
        }
    )

task('adapter:get', 'Gets an OFT adapter')
    .addPositionalParam('underlying', 'Address of the underlying token')
    .setAction(
        async (
            { underlying }: TaskArguments,
            { network, deployments, ethers, getNamedAccounts }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const ownerSigner = await ethers.getSigner(owner)

            if (network.name !== 'sepolia' && network.name !== 'polygon') {
                throw new Error('This task can only be run on Amoy or Polygon network')
            }
            const contractName = 'JasmineHubBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            const adapter = await bridgeContract.adapters(underlying)
            console.log(`Adapter: ${explorerLink(network, adapter)}`)
        }
    )

task('adapter:peer:set', 'Sets an OFT adapters peer')
    .addPositionalParam('adapter', 'Address of the adapter')
    .addPositionalParam('peer', 'Address of the peer')
    .addPositionalParam('destination', 'Network name of the peer')
    .setAction(
        async (
            { adapter, peer, destination }: TaskArguments,
            { network: currentNetwork, deployments, ethers, getNamedAccounts, config }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const ownerSigner = await ethers.getSigner(owner)

            if (currentNetwork.name !== 'sepolia' && currentNetwork.name !== 'polygon') {
                throw new Error('This task can only be run on Polygon networks')
            }

            const contractName = 'JasmineHubBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            const eid = config.networks[destination].eid
            // TODO: Validate peer is valid address
            const peerAddress = ethers.utils.hexlify(ethers.utils.zeroPad(peer, 32))

            const tx = await bridgeContract.setAdapterPeer(adapter, eid, peerAddress)
            const result = await tx.wait()
            console.log(
                `Added peer: ${peer} (on network: ${destination}) to adapter: ${explorerLink(currentNetwork, adapter)} (on network: ${currentNetwork.name}) at tx: ${explorerLink(currentNetwork, result.transactionHash)}`
            )
        }
    )

task('oft:quote:send', 'Send OFTs to another chain')
    .addPositionalParam('oft', 'Address of the OFT token')
    .addPositionalParam('amount', 'Amount to send in formatted using token decimals')
    .addOptionalParam('to', 'Recipient on destination chain')
    .addOptionalParam('destination', 'Network name of the peer')
    .addOptionalParam('sender', 'Address of the sender')
    .setAction(
        async (
            { oft, amount, destination, to, sender }: TaskArguments,
            { network: currentNetwork, ethers, getNamedAccounts, config }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const signer = await ethers.getSigner(sender ? sender : owner)

            let contractName: string
            if (currentNetwork.name === 'polygon' || currentNetwork.name === 'sepolia') {
                contractName = 'JLTAdapter'
                if (!destination) {
                    destination = config.networks[currentNetwork.name].companionNetworks?.spoke
                    assert(destination, 'Missing spoke network')
                }
            } else if (currentNetwork.name === 'base' || currentNetwork.name === 'baseSepolia') {
                contractName = 'OJLT'
                if (!destination) {
                    destination = config.networks[currentNetwork.name].companionNetworks?.hub
                    assert(destination, 'Missing hub network')
                }
            } else {
                throw new Error('This task can only be run on Polygon network')
            }

            const oftContract = await ethers.getContractAt(contractName, oft, signer)
            const decimals = contractName === 'OJLT' ? await oftContract.decimals() : 6
            amount *= 10 ** decimals

            assert(config.networks[destination].eid, 'Missing eid for destination network')
            const eid = config.networks[destination].eid
            if (!eid) {
                throw new Error('Missing eid for destination network')
            }

            const toAddress = ethers.utils.hexlify(ethers.utils.zeroPad(to ? to : signer.address, 32))

            const options = Options.newOptions().addExecutorLzReceiveOption(250_000, 0).toHex().toString()
            const params = [eid, toAddress, amount, amount, options, [], []]
            const quote = await oftContract.quoteSend(params, false)
            console.log('Native fee:', quote[0])

            return {
                params,
                quote,
            }
        }
    )

task('oft:send', 'Send OFTs to another chain')
    .addPositionalParam('oft', 'Address of the OFT token')
    .addPositionalParam('amount', 'Amount to send in formatted using token decimals')
    .addOptionalParam('to', 'Address to receive the OFTs')
    .addOptionalParam('destination', 'Network name of the peer')
    .addOptionalParam('sender', 'Address of the sender')
    .setAction(
        async (
            { oft, amount, to, destination, sender }: TaskArguments,
            { network: currentNetwork, run, ethers, config, getNamedAccounts }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const signer = await ethers.getSigner(sender ? sender : owner)

            let contractName: string
            if (currentNetwork.name === 'polygon' || currentNetwork.name === 'sepolia') {
                contractName = 'JLTAdapter'
                if (!destination) {
                    destination = config.networks[currentNetwork.name].companionNetworks?.spoke
                    assert(destination, 'Missing spoke network')
                }
            } else if (currentNetwork.name === 'base' || currentNetwork.name === 'baseSepolia') {
                contractName = 'OJLT'
                if (!destination) {
                    destination = config.networks[currentNetwork.name].companionNetworks?.hub
                    assert(destination, 'Missing hub network')
                }
            } else {
                throw new Error('This task can only be run on Polygon network')
            }

            const oftContract = await ethers.getContractAt(contractName, oft, signer)
            const { params, quote } = await run('oft:quote:send', { oft, amount, to, destination, sender })

            const sendTx = await oftContract.send(params, quote, to ? to : signer.address, { value: quote[0] })
            console.log(`Sent OFTs to at tx: ${logLayerZeroTx(sendTx, !currentNetwork.live)}`)
        }
    )

task('oft:quote:retire', 'Get quote for retiring OFT')
    .addPositionalParam('oft', 'Address of the OFT token')
    .addPositionalParam('length', 'Length of reason string', '0')
    .setAction(async ({ oft, length }: TaskArguments, { ethers, getNamedAccounts }: HardhatRuntimeEnvironment) => {
        const { owner } = await getNamedAccounts()
        const signer = await ethers.getSigner(owner)

        const contractName = 'OJLT'
        const oftContract = await ethers.getContractAt(contractName, oft, signer)

        // TODO: Include data length
        const quote = await oftContract.quoteRetire(parseInt(length))
        console.log('Native fee:', quote)

        return quote
    })

task('oft:retire', 'Retire OFT')
    .addPositionalParam('oft', 'Address of the OFT token')
    .addPositionalParam('amount', 'Amount to retire in formatted using token decimals')
    .addOptionalParam('beneficiary', 'Address of the retirement beneficiary')
    .addOptionalParam('data', 'Data to include in the retirement')
    .addOptionalParam('from', 'Address of the sender')
    .setAction(
        async (
            { oft, amount, beneficiary, from, data }: TaskArguments,
            { ethers, getNamedAccounts, network }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const signer = await ethers.getSigner(from ? from : owner)

            const contractName = 'OJLT'
            const oftContract = await ethers.getContractAt(contractName, oft, signer)
            const decimals = await oftContract.decimals()
            amount *= 10 ** decimals

            const nativeFee = await oftContract.quoteRetire(data ? data.length : 0)

            const retireTx = await oftContract.retire(
                signer.address,
                beneficiary ?? signer.address,
                amount,
                data ?? [],
                {
                    value: nativeFee,
                }
            )
            console.log(`Retired OFTs at tx: ${explorerLink(network, retireTx.hash)}`)
        }
    )

task('create', 'Creates an OFT adapter and OFT token then links')
    .addPositionalParam('underlying', 'Address of the underlying token')
    .setAction(async ({ underlying }: TaskArguments, { network, run }: HardhatRuntimeEnvironment) => {
        const adapter = await run('create:adapter', { underlying })
        const oft = await run('create:oft', { underlying })
        await run('adapter:peer:set', { adapter, peer: oft, destination: network.companionNetworks.spoke })
    })
