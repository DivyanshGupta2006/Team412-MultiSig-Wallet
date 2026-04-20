// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

/**
 * @title DeployMultiSigWallet
 * @notice Foundry deployment script for the MultiSigWallet contract.
 * @dev Usage:
 *      forge script script/deploy.s.sol:DeployMultiSigWallet \
 *          --rpc-url <RPC_URL> --broadcast --private-key <DEPLOYER_KEY>
 *
 *      Override defaults with environment variables:
 *          OWNER1, OWNER2, OWNER3 — owner addresses
 *          REQUIRED_APPROVALS   — quorum threshold (default: 2)
 */
contract DeployMultiSigWallet is Script {
    function run() external returns (MultiSigWallet) {
        // --- Configuration ---
        // Default: 3 owners, 2 required approvals (2-of-3)
        // Override via env vars for production deployments.

        address owner1 = vm.envOr("OWNER1", address(0x1));
        address owner2 = vm.envOr("OWNER2", address(0x2));
        address owner3 = vm.envOr("OWNER3", address(0x3));
        uint256 requiredApprovals = vm.envOr("REQUIRED_APPROVALS", uint256(2));

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // --- Deploy ---
        vm.startBroadcast();

        MultiSigWallet wallet = new MultiSigWallet(owners, requiredApprovals);

        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Owners:", owner1, owner2, owner3);
        console.log("Required approvals:", requiredApprovals);

        vm.stopBroadcast();

        return wallet;
    }
}
