// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

/**
 * @title DeployMultiSigWallet
 * @notice Foundry deployment script for the MultiSigWallet contract.
 *
 * @dev Usage (local Anvil):
 *   forge script script/deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
 *
 * @dev Usage (Sepolia testnet):
 *   forge script script/deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
 *
 * @dev Configure owners and threshold via environment variables:
 *   OWNER1, OWNER2, OWNER3      — wallet owner addresses
 *   REQUIRED_APPROVALS           — approval threshold (default: 2)
 */
contract DeployMultiSigWallet is Script {
    function run() external returns (MultiSigWallet) {
        // ── Read owner addresses from environment ──
        address owner1 = vm.envAddress("OWNER1");
        address owner2 = vm.envAddress("OWNER2");
        address owner3 = vm.envAddress("OWNER3");

        uint256 requiredApprovals = vm.envOr("REQUIRED_APPROVALS", uint256(2));

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // ── Deploy ──
        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, requiredApprovals);
        vm.stopBroadcast();

        // ── Log deployment info ──
        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Owners:", owner1, owner2, owner3);
        console.log("Required approvals:", requiredApprovals);

        return wallet;
    }
}
