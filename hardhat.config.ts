// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@layerzerolabs/toolbox-hardhat'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

import './tasks'

const MNEMONIC = process.env.MNEMONIC
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY
const POLYSCAN_API_KEY = process.env.POLYSCAN_API_KEY

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
        sepolia: {
            chainId: 11155111,
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: process.env.RPC_URL_SEPOLIA || 'https://rpc.sepolia.org/',
            accounts,
            live: false,
            companionNetworks: {
                spoke: 'baseSepolia',
            },
        },
        amoy: {
            chainId: 80002,
            eid: EndpointId.AMOY_V2_TESTNET,
            url: process.env.RPC_URL_AMOY || 'https://rpc.ankr.com/polygon_amoy',
            accounts,
            live: false,
            companionNetworks: {
                spoke: 'baseSepolia',
            },
        },
        baseSepolia: {
            chainId: 84532,
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: process.env.RPC_URL_BASESEP || 'https://sepolia.base.org',
            accounts,
            live: false,
            companionNetworks: {
                hub: 'sepolia',
            },
        },
        polygon: {
            eid: EndpointId.POLYGON_V2_MAINNET,
            url: process.env.RPC_URL_POLYGON || 'https://rpc.ankr.com/polygon',
            accounts,
            live: true,
            companionNetworks: {
                spoke: 'base',
            },
        },
        base: {
            eid: EndpointId.BASE_V2_MAINNET,
            url: process.env.RPC_URL_BASE || 'https://rpc.base.org',
            accounts,
            live: true,
            companionNetworks: {
                hub: 'polygon',
            },
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
    etherscan: {
        apiKey: {
            base: BASESCAN_API_KEY ?? '',
            baseSepolia: BASESCAN_API_KEY ?? '',
            polygon: POLYSCAN_API_KEY ?? '',
            amoy: POLYSCAN_API_KEY ?? '',
            sepolia: ETHERSCAN_API_KEY ?? '',
        },
        customChains: [
            {
                network: 'amoy',
                chainId: 80002,
                urls: {
                    apiURL: 'https://api-amoy.polygonscan.com/api',
                    browserURL: 'https://amoy.polygonscan.com',
                },
            },
        ],
    },
    sourcify: {
        enabled: true,
    },
}

export default config
