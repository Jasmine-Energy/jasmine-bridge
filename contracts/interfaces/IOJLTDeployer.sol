// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OJLTDeployer Interface
 * @author Kai Aldag<kai.aldag@jasmine.energy>
 * @notice Interface for data sharing OFT constructor arguments.
 */
interface IOJLTDeployer {

    /// @notice Gets address of the LayerZero endpoint (V2) contract
    function getLZEndpoint() external view returns (address endpoint);

    /// @notice Gets the origin chain's LayerZero endpoint ID
    function getOriginEid() external view returns (uint32 eid);

    /// @notice Gets the OJLT's (ERC-20) token name
    function getOJLTName() external view returns (string memory name);

    /// @notice Gets the OJLT's (ERC-20) token symbol
    function getOJLTSymbol() external view returns (string memory symbol);

    /// @notice Gets the OJLT's root peer on the origin chain
    function getOJLTRootPeer() external view returns (bytes32 rootPeer);

}
