// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

/**
 * @title IOFTDeployer
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Interface for data sharing OFT constructor arguments.
 */
interface IOFTDeployer {
    function getOFTName() external view returns (string memory);

    function getOFTSymbol() external view returns (string memory);

    function getOFTLZEndpoint() external view returns (address);

    function getRootEid() external view returns (uint32);

    function getRootPeer() external view returns (bytes32);
}
