
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title A simple Raffle Contract
 * @author Oke Abdulquadri
 * @notice This contract is for creating a sample raffle
 * @dev Implement Chainlink VRFv2
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNoOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMWORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //require(msg.sender >= i_entrance, "Not enough ETH sent!")
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNoOpen();
        }
    }

    function performUpkeep(bytes memory /**performData */) external {
        // check to see if enough time has passed
       (bool upkeepNeeded, ) = checkUpkeep("");
       if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
       }
        s_raffleState = RaffleState.CALCULATING;
         i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUMWORDS
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(winner);
    }

    function checkUpkeep(bytes memory) 
        public 
        view 
        returns (bool upkeepNeed, bytes memory /**performData */) 
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeed = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeed, hex"");
    }

    /** Getter function */

    function getEntranceFee() external view returns (uint256) {}
}
