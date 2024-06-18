// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        vm.startBoardcast();
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBoardcast();
    }
}
