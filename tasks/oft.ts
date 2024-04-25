import assert from 'assert'

import { task } from 'hardhat/config'

import { Options } from '@layerzerolabs/lz-v2-utilities'

import type { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types'

const hyperlink = (url: string, text: string) => {
    const OSC = '\u001B]'
    const BEL = '\u0007'
    const SEP = ';'

    return [OSC, '8', SEP, SEP, url || text, BEL, text, OSC, '8', SEP, SEP, BEL].join('')
}

const logLayerZeroTx = (tx: any, isTestnet: boolean) => {
    return hyperlink(`https://${isTestnet ? 'testnet.' : ''}layerzeroscan.com/tx/${tx.hash}`, tx.hash)
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
            console.log(`Adapter created: ${adapterAddress} for: ${underlying} at tx: ${result.transactionHash}`)

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
                // @ts-ignore
                config.networks[hubNetwork].url
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

            // const tx = await bridgeContract.createOFT(underlying, name, symbol, 0, ethers.constants.HashZero)
            const tx = await bridgeContract.createOFT(underlying, name, symbol, peer)
            const result = await tx.wait()
            const oftAddress = result.events?.find((e: { event: string }) => e.event === 'OFTCreated')?.args?.at(1)
            console.log(`OFT created: ${oftAddress} for: ${underlying} at tx: ${result.transactionHash}`)

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
            console.log(`Adapter: ${adapter}`)
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
                `Added peer: ${peer} (on network: ${destination}) to adapter: ${adapter} (on network: ${currentNetwork.name}) at tx: ${result.transactionHash}`
            )
        }
    )

task('oft:quote:send', 'Send OFTs to another chain')
    .addPositionalParam('oft', 'Address of the OFT token')
    .addPositionalParam('amount', 'Amount to send in formatted using token decimals')
    .addOptionalParam('peer', 'Address of the peer')
    .addOptionalParam('destination', 'Network name of the peer')
    .addOptionalParam('sender', 'Address of the sender')
    .setAction(
        async (
            { oft, amount, peer, destination, sender }: TaskArguments,
            { network: currentNetwork, ethers, getNamedAccounts, config }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const signer = await ethers.getSigner(sender ? sender : owner)

            if (currentNetwork.name !== 'polygon' && currentNetwork.name !== 'sepolia') {
                throw new Error('This task can only be run on Polygon network')
            }

            const contractName = 'OFTPermitAdapter'
            const oftContract = await ethers.getContractAt(contractName, oft, signer)
            const decimals = 6 //await oftContract.decimals()
            amount *= 10 ** decimals

            // TODO: Refactor
            if (!destination) {
                destination = config.networks[currentNetwork.name].companionNetworks?.spoke
                assert(destination, 'Missing spoke network')
            }
            assert(config.networks[destination].eid, 'Missing eid for destination network')
            const eid = config.networks[destination].eid!

            if (!peer) {
                const spokeDeployment = require(
                    `${config.paths.root}/deployments/${destination}/JasmineSpokeBridge.json`
                )
                const spokeBridgeContract = await ethers.getContractAt(
                    'JasmineSpokeBridge',
                    spokeDeployment.address,
                    signer
                )
                peer = await spokeBridgeContract.ofts(oft)
            }
            const peerAddress = ethers.utils.hexlify(ethers.utils.zeroPad(peer, 32))

            const options = Options.newOptions().addExecutorLzReceiveOption(75_000, 0).toHex().toString()
            const params = [eid, peerAddress, amount, amount, options, [], []]
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
    .addOptionalParam('peer', 'Address of the peer')
    .addOptionalParam('destination', 'Network name of the peer')
    .addOptionalParam('sender', 'Address of the sender')
    .setAction(
        async (
            { oft, amount, peer, destination, sender }: TaskArguments,
            {
                network: currentNetwork,
                run,
                ethers,
                config,
                getNamedAccounts,
                companionNetworks,
            }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const signer = await ethers.getSigner(sender ? sender : owner)

            if (currentNetwork.name !== 'polygon' && currentNetwork.name !== 'sepolia') {
                throw new Error('This task can only be run on Polygon network')
            }

            const contractName = 'OFTPermitAdapter'
            const oftContract = await ethers.getContractAt(contractName, oft, signer)

            // TODO: Refactor
            if (!destination) {
                destination = config.networks[currentNetwork.name].companionNetworks?.spoke
                assert(destination, 'Missing spoke network')
            }

            if (!peer) {
                const destinationProvider = companionNetworks['spoke'].provider
                peer = await destinationProvider.send('function ofts(address) returns (address)', [oft])
                // currentNetwork.companionNetworks['spoke']
                // const spokeBridgeContract = await ethers.getContractAt(
                //     'JasmineSpokeBridge',
                //     spokeDeployment.address,
                //     new ethers.providers.
                // )
                // peer = await spokeBridgeContract.ofts(oft)
            }

            const { params, quote } = await run('oft:quote:send', { oft, amount, peer, destination, sender })

            const sendTx = await oftContract.send(params, quote, signer.address, { value: quote[0] })
            console.log(`Sent OFTs to ${peer} at tx: ${logLayerZeroTx(sendTx, currentNetwork.live)}`)
        }
    )

task('create', 'Creates an OFT adapter and OFT token then links')
    .addPositionalParam('underlying', 'Address of the underlying token')
    .setAction(async ({ underlying }: TaskArguments, { network, run }: HardhatRuntimeEnvironment) => {
        const adapter = await run('create:adapter', { underlying })
        const oft = await run('create:oft', { underlying })
        await run('adapter:peer:set', { adapter, peer: oft, destination: network.companionNetworks.spoke })
    })
