import { task } from 'hardhat/config'

import type { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types'

task('create:adapter', 'Creates a new OFT adapter on Hub bridge')
    .addPositionalParam('address', 'Address of the underlying token')
    .setAction(
        async (
            { address }: TaskArguments,
            { network, deployments, ethers, getNamedAccounts }: HardhatRuntimeEnvironment
        ) => {
            const { owner } = await getNamedAccounts()
            const ownerSigner = await ethers.getSigner(owner)

            if (network.name !== 'amoy' && network.name !== 'polygon') {
                throw new Error('This task can only be run on Amoy or Polygon network')
            }
            const contractName = 'JasmineHubBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            const tx = await bridgeContract.createAdapter(address)
            const result = await tx.wait()
            const adapterAddress = result.events
                ?.find((e: { event: string }) => e.event === 'OFTAdapterCreated')
                ?.args?.at(1)
            console.log(`Adapter created: ${adapterAddress} for: ${address} at tx: ${result.transactionHash}`)
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
            const hubNetwork = network.live ? 'polygon' : 'amoy'
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
            const eid = config.networks[hubNetwork].eid
            const peer = ethers.utils.hexlify(ethers.utils.zeroPad(adapter, 32))

            const contractName = 'JasmineSpokeBridge'

            const bridgeDeployment = await deployments.get(contractName)
            const bridgeContract = await ethers.getContractAt(contractName, bridgeDeployment.address, ownerSigner)

            // const tx = await bridgeContract.createOFT(underlying, name, symbol, 0, ethers.constants.HashZero)
            const tx = await bridgeContract.createOFT(underlying, name, symbol, eid, peer)
            const result = await tx.wait()
            const oftAddress = result.events?.find((e: { event: string }) => e.event === 'OFTCreated')?.args?.at(1)
            console.log(`OFT created: ${oftAddress} for: ${underlying} at tx: ${result.transactionHash}`)
        }
    )
