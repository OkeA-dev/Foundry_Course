////SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelpConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


contract CreateSubscription is  Script {
    function createSubscriptionUsingConfig() public  returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);

        return (subId, vrfCoordinator);

    }

    function createSubscription (address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on this block.chainId: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription id: ", subId);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }
    function run() public {}
}

contract FundSubscription is CodeConstants, Script {
    uint256 public constant FUND_AMOUNT = 0.01 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator,subscriptionId,linkToken);

    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription");
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID) {
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }

    }
    function run() public {
        fundSubscriptionUsingConfig();
    }


}

