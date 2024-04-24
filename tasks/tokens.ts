import { task } from 'hardhat/config'

import type { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types'

task('token:name', 'Prints the name of the token')
    .addPositionalParam('address', 'Address of the token')
    .setAction(async ({ address }: TaskArguments, { ethers, network }: HardhatRuntimeEnvironment) => {
        console.log(`Network: ${network.name}`)
        console.log(network)
        const token = await ethers.getContractAt('IERC20Metadata', address)
        const name = await token.name()
        console.log(`Token name: ${name}`)

        return name
    })

task('token:symbol', 'Prints the symbol of the token')
    .addPositionalParam('address', 'Address of the token')
    .setAction(async ({ address }: TaskArguments, { ethers }: HardhatRuntimeEnvironment) => {
        const token = await ethers.getContractAt('IERC20Metadata', address)
        const symbol = await token.symbol()
        console.log(`Token symbol: ${symbol}`)

        return symbol
    })

task('token:decimals', 'Prints the decimals of the token')
    .addPositionalParam('address', 'Address of the token')
    .setAction(async ({ address }: TaskArguments, { ethers }: HardhatRuntimeEnvironment) => {
        const token = await ethers.getContractAt('IERC20Metadata', address)
        const decimals = await token.decimals()
        console.log(`Token decimals: ${decimals}`)

        return decimals
    })

task('token:approve', 'Approve spending of tokens')
    .addPositionalParam('token', 'Address of the token')
    .addPositionalParam('spender', 'Address of the spender')
    .addPositionalParam('amount', 'Amount to approve in formatted using token decimals')
    .addOptionalParam('from', 'Address of the signer')
    .setAction(
        async (
            { token, spender, amount, from }: TaskArguments,
            { ethers, getNamedAccounts }: HardhatRuntimeEnvironment
        ) => {
            if (!from) {
                from = (await getNamedAccounts()).owner
            }
            const signer = await ethers.getSigner(from)
            const tokenContract = await ethers.getContractAt('IERC20Metadata', token, signer)
            const decimals = await tokenContract.decimals()
            amount *= 10 ** decimals
            const tx = await tokenContract.approve(spender, amount)
            console.log(`Approved ${amount} tokens to ${spender} with tx hash: ${tx.hash}`)
        }
    )
