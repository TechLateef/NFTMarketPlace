// scripts/deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployScriptBase} from "forge-std/Script.sol";
import {NFTMarket} from "../src/contracts/NftMarket.sol";  // Import your contract;

contract DeployNFTMarket is DeployScriptBase {
    function run() public {
        // Ensure you have an Ethereum wallet and set your private key in the environment variables
        address deployer = vm.addr(vm.envUint("SEPOLIA_PRIVATE_KEY"));
        
        // Create the contract instance
        NFTMarket nftMarket = new NFTMarket();
        
        
        // Log the deployed contract address
        console.log("NFTMarket deployed to:", address(nftMarket));
    }
}
