// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Playpoker.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        Playpoker playpoker = new Playpoker(10000000000000000, 20000000000000000, 0x986208D332d69108C759a0a7e7A337a0BEF95e6b);

        vm.stopBroadcast();
    }
}