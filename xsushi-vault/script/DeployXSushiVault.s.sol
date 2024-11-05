// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/XSushiVault.sol";

contract DeployXSushiVault is Script {
    address public constant SUSHI_ADDRESS = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant XSUSHI_ADDRESS = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public constant SUSHI_BAR_ADDRESS = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F;

    function run() external {
        vm.startBroadcast();

        // Deploy the XSushiVault contract with the necessary parameters
        XSushiVault xSushiVault = new XSushiVault(
            SUSHI_ADDRESS,
            XSUSHI_ADDRESS,
            SUSHI_BAR_ADDRESS,
            SUSHISWAP_ROUTER_ADDRESS
        );

        // Log the address of the deployed contract
        console.log("XSushiVault deployed at:", address(xSushiVault));

        vm.stopBroadcast();
    }
}
