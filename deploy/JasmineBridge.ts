import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

// TODO declare your contract name here
const hubContractName = 'JasmineHubBridge'
const spokeContractName = 'JasmineSpokeBridge'

const deploy: DeployFunction = async ({ getNamedAccounts, deployments, config, network }) => {
    const { deploy } = deployments
    const { deployer, owner } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')
    assert(owner, 'Missing named owner account')

    console.log(`Network: ${network.name}`)
    console.log(`Deployer: ${deployer}`)
    console.log(`Owner: ${owner}`)

    // This is an external deployment pulled in from @layerzerolabs/lz-evm-sdk-v2
    //
    // @layerzerolabs/toolbox-hardhat takes care of plugging in the external deployments
    // from @layerzerolabs packages based on the configuration in your hardhat config
    //
    // For this to work correctly, your network config must define an eid property
    // set to `EndpointId` as defined in @layerzerolabs/lz-definitions
    //
    // For example:
    //
    // networks: {
    //   fuji: {
    //     ...
    //     eid: EndpointId.AVALANCHE_V2_TESTNET
    //   }
    // }

    const endpointV2Deployment = await deployments.get('EndpointV2')

    let contractName: string
    const args: any[] = [
        endpointV2Deployment.address, // LayerZero's EndpointV2 address
        owner, // owner
    ]
    if (network.name === 'amoy') {
        contractName = hubContractName
    } else if (network.name === 'baseSepolia') {
        contractName = spokeContractName
        const rootEid = config.networks['baseSepolia'].eid
        assert(rootEid, 'Missing rootEid for baseSepolia network (root network: amoy)')
        args.push(rootEid)
    } else {
        throw new Error(`Unsupported network: ${network.name}`)
    }

    const { address } = await deploy(contractName, {
        from: deployer,
        args,
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${network.name}, address: ${address}`)
}

deploy.tags = ['Bridge']

export default deploy
