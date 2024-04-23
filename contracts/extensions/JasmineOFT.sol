// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

interface IOFTData {
    function getOFTName() external view returns (string memory);

    function getOFTSymbol() external view returns (string memory);

    function getOFTLZEndpoint() external view returns (address);
}

contract JasmineOFT is OFT, ERC20Permit {
    constructor(
        address owner
    )
        OFT(IOFTData(owner).getOFTName(), IOFTData(owner).getOFTSymbol(), IOFTData(owner).getOFTLZEndpoint(), owner)
        ERC20Permit(IOFTData(owner).getOFTName())
        Ownable(owner)
    {}
}
