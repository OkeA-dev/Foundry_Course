//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from './HelpConfig.s.sol';
import {CreateSubscription} from "../script/Interaction.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //local -> deploy mock, get local config
        //sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0 ) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.entranceFee,
            config.interval,
            config.callbackGasLimit,
            config.vrfCoordinator
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
