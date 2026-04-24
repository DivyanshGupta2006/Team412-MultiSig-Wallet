pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract DeployMultiSigWallet is Script {
    function run() external returns (MultiSigWallet) {
        address owner1 = vm.envAddress("OWNER1");
        address owner2 = vm.envAddress("OWNER2");
        address owner3 = vm.envAddress("OWNER3");

        uint256 requiredApprovals = vm.envOr("REQUIRED_APPROVALS", uint256(2));

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, requiredApprovals);
        vm.stopBroadcast();

        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Owners:", owner1, owner2, owner3);
        console.log("Required approvals:", requiredApprovals);

        return wallet;
    }
}
