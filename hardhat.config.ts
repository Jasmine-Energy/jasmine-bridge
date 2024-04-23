// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

import './tasks'

const MNEMONIC = process.env.MNEMONIC
const PRIVATE_KEY = process.env.PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.24',
                settings: {
                    evmVersion: 'cancun',
                    viaIR: true,
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        amoy: {
            chainId: 80002,
            eid: EndpointId.AMOY_V2_TESTNET,
            url: process.env.RPC_URL_AMOY || 'https://rpc.ankr.com/polygon_amoy',
            accounts,
            live: false,
        },
        baseSepolia: {
            chainId: 84532,
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: process.env.RPC_URL_BASESEP || 'https://sepolia.base.org',
            accounts,
            live: false,
        },
        sepolia: {
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: process.env.RPC_URL_SEPOLIA || 'https://rpc.sepolia.org/',
            accounts,
            live: false,
        },
        fuji: {
            eid: EndpointId.AVALANCHE_V2_TESTNET,
            url: process.env.RPC_URL_FUJI || 'https://rpc.ankr.com/avalanche_fuji',
            accounts,
            live: false,
        },
        mumbai: {
            eid: EndpointId.POLYGON_V2_TESTNET,
            url: process.env.RPC_URL_MUMBAI || 'https://rpc.ankr.com/polygon_mumbai',
            accounts,
            live: false,
        },
        polygon: {
            eid: EndpointId.POLYGON_V2_MAINNET,
            url: process.env.RPC_URL_POLYGON || 'https://rpc.ankr.com/polygon',
            accounts,
            live: true,
        },
        base: {
            eid: EndpointId.BASE_V2_MAINNET,
            url: process.env.RPC_URL_BASE || 'https://rpc.base.org',
            accounts,
            live: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        owner: {
            default: 1,
        },
    },
}

export default config
