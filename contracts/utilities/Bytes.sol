// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library BytesLib {
    
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)) << 96);
    }
}
