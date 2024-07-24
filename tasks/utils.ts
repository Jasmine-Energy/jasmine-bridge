import type { Network } from 'hardhat/types'

export const hyperlink = (url: string, text: string) => {
    const OSC = '\u001B]'
    const BEL = '\u0007'
    const SEP = ';'

    return [OSC, '8', SEP, SEP, url || text, BEL, text, OSC, '8', SEP, SEP, BEL].join('')
}

export const explorerLink = (network: Network, hashOrAddress: string) => {
    const route = hashOrAddress.length === 42 ? 'address' : 'tx'
    let url = ''
    switch (network.config.chainId) {
        case 1:
            url = `https://etherscan.io/${route}/${hashOrAddress}`
            break
        case 137:
            url = `https://polygonscan.com/${route}/${hashOrAddress}`
            break
        case 8453:
            url = `https://basescan.org/${route}/${hashOrAddress}`
            break
        case 11155111:
            url = `https://sepolia.etherscan.io/${route}/${hashOrAddress}`
            break
        case 80002:
            // TODO: Add amoy explorer
            return hashOrAddress
        case 84532:
            url = `https://sepolia.basescan.org/${route}/${hashOrAddress}`
            break
        default:
            return hashOrAddress
    }

    return hyperlink(url, hashOrAddress)
}
