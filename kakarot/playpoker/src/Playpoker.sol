// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./verifier.sol";

contract Playpoker is Ownable, Verifier {
    //using SafeMath for uint256;

    uint public smallBlind; 
    uint public bigBlind;

    uint256 constant NUM_CARDS = 52;
    uint256 constant NUM_PLAYERS = 10;
    uint256 constant NUM_BOARD_CARDS = 5;

    enum GamePhase { PreFlop, Flop, Turn, River, Showdown }
    GamePhase public currentPhase;

    struct Player {
        address addr;
        uint balance;
        bool isPlaying;
        bool hasFolded;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    struct Hand {
        bytes32[2][] holeCards;
        bytes32[5] communityCards;
        mapping(address => bytes32) playerCommitments;
        mapping(address => bool) revealed;
        mapping(address => bytes32[2]) revealedHands;
        mapping(address => bool) isValidProof;
        mapping(address => uint256) handStrength;
    }

    Hand private currentHand;
    bytes32[NUM_CARDS] public shuffledDeck;
    uint256 public currentBet;
    uint256 public pot;

    event GameStarted();
    event PlayerLeft(address indexed player);
    event PlayerJoined(address indexed player);
    event PlayerFolded(address indexed player);
    event Shuffled();
    event HandDealt();
    event PhaseAdvanced(GamePhase phase);
    event PlayerCommitted(address indexed player);
    event PlayerRevealed(address indexed player, bytes32[2] hand);
    event BetPlaced(address indexed player, uint256 amount);
    event PotUpdated(uint256 amount);
    event PotDistributed(uint256 potAmount, address[] winners, uint256 numWinners);

    modifier onlyPlayer() {
        bool isPlayer = false;
        for (uint i = 0; i < playerAddresses.length; i++) {
            if (players[playerAddresses[i]].addr == msg.sender && players[playerAddresses[i]].isPlaying) {
                isPlayer = true;
                break;
            }
        }
        require(isPlayer, "Not a player in the game");
        _;
    }


    modifier atPhase(GamePhase phase) {
        require(currentPhase == phase, "Function cannot be called at this phase");
        _;
    }

    constructor(uint _smallBlind, uint _bigBlind, address initialOwner) Ownable(initialOwner) {
        smallBlind = _smallBlind;
        bigBlind = _bigBlind;
    }

    function joinGame() external payable {
        require(msg.value >= bigBlind, "Insufficient buy-in amount");
        players[msg.sender] = Player(msg.sender, msg.value, true, false);
        playerAddresses.push(msg.sender);
        emit PlayerJoined(msg.sender);
    }

    function startGame() external onlyOwner {
        require(playerAddresses.length >= 2, "Not enough players to start the game");
        currentPhase = GamePhase.PreFlop;
        emit GameStarted();
    }

    function leaveGame() external onlyPlayer {
        for (uint i = 0; i < playerAddresses.length; i++) {
            if (playerAddresses[i] == msg.sender) {
                payable(msg.sender).transfer(players[msg.sender].balance);
                players[msg.sender].isPlaying = false;
                emit PlayerLeft(msg.sender);
                break;
            }
        }
    }

    function shuffleDeck() external onlyOwner atPhase(GamePhase.PreFlop) {
        bytes32[NUM_CARDS] memory deck;
        uint256 index = 0;

        for (uint256 suit = 0; suit < 4; suit++) {
            for (uint256 value = 0; value < 13; value++) {
                deck[index] = keccak256(abi.encodePacked(suit, value, index));
                index++;
            }
        }

        for (uint256 i = NUM_CARDS - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (i + 1);
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
        shuffledDeck = deck;
        emit Shuffled();
    }



    function dealHand() external onlyOwner atPhase(GamePhase.PreFlop) {
        require(playerAddresses.length >= 2, "Not enough players to deal hand");

        uint256 deckIndex = 0;
        currentHand.holeCards = new bytes32[2][](NUM_PLAYERS);

        // Deal hole cards to each player in a round-robin fashion
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < NUM_PLAYERS; j++) {
                address playerAddr = playerAddresses[j];
                if (players[playerAddr].isPlaying) {
                    currentHand.holeCards[j][i] = shuffledDeck[deckIndex];
                    deckIndex++;
                }
            }
        }
        // Advance to the next phase (Flop)
        currentPhase = GamePhase.Flop;
        emit HandDealt();
        emit PhaseAdvanced(currentPhase);
    }

    function dealCommunityCards() internal onlyOwner {
        uint256 holeCardsDealt = playerAddresses.length * 2;
        uint256 deckIndex = holeCardsDealt;

        if (currentPhase == GamePhase.Flop) {
            // Deal the Flop
            currentHand.communityCards[0] = shuffledDeck[deckIndex];
            currentHand.communityCards[1] = shuffledDeck[deckIndex + 1];
            currentHand.communityCards[2] = shuffledDeck[deckIndex + 2];
            currentPhase = GamePhase.Turn;
        } else if (currentPhase == GamePhase.Turn) {
            // Deal the Turn
            currentHand.communityCards[3] = shuffledDeck[deckIndex + 3];
            currentPhase = GamePhase.River;
        } else if (currentPhase == GamePhase.River) {
            // Deal the River
            currentHand.communityCards[4] = shuffledDeck[deckIndex + 4];
            currentPhase = GamePhase.Showdown;
        }

        emit PhaseAdvanced(currentPhase);
    }

    function commitHand(bytes32 commitment) external onlyPlayer atPhase(GamePhase.PreFlop) {
        currentHand.playerCommitments[msg.sender] = commitment;
        emit PlayerCommitted(msg.sender);
    }


    function revealHand(bytes32[2] memory hand, Proof memory proof, uint256[19] memory publicInputs) external onlyPlayer atPhase(GamePhase.Showdown) {
        // Verify the proof using zk
        bool isValidProof = verifyTx(proof, publicInputs);
        require(isValidProof, "Invalid ZK proof");

        bytes32 commitment = keccak256(abi.encodePacked(hand));
        require(commitment == currentHand.playerCommitments[msg.sender], "Hand does not match commitment");

        //uint256 handStrength = uint256(proof.input[proof.input.length - 1]);
        uint256 handStrength = publicInputs[publicInputs.length - 1];

        currentHand.revealed[msg.sender] = true;
        currentHand.revealedHands[msg.sender] = hand;
        currentHand.isValidProof[msg.sender] = isValidProof;
        currentHand.handStrength[msg.sender] = handStrength;
        emit PlayerRevealed(msg.sender, hand);
    }

    function placeBet(uint256 amount) external onlyPlayer {
        require(amount >= currentBet, "Bet amount must be at least the current bet");
        Player storage player = players[msg.sender];
        require(player.balance >= amount, "Insufficient balance to place bet");

        player.balance -= amount;
        pot += amount;
        currentBet = amount;

        emit BetPlaced(msg.sender, amount);
        emit PotUpdated(pot);
    }

    function fold() external onlyPlayer {
        Player storage player = players[msg.sender];
        player.hasFolded = true;
        emit PlayerFolded(msg.sender);
    }

    function nextRound() external onlyOwner {
        if (currentPhase == GamePhase.Flop) {
            dealCommunityCards();
        } else if (currentPhase == GamePhase.Turn) {
            dealCommunityCards();
        } else if (currentPhase == GamePhase.River) {
            dealCommunityCards();
        }
    }

    function endHand() external onlyOwner atPhase(GamePhase.Showdown) {        
        address[] memory winners;
        uint256 bestHandValue = 0;
        uint256 numWinners = 0;
        
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            Player storage player = players[playerAddr];
            if (player.isPlaying && !player.hasFolded && currentHand.revealed[playerAddr] && currentHand.isValidProof[playerAddr]) {
                uint256 handValue = currentHand.handStrength[playerAddr];
                if (handValue > bestHandValue) {
                    bestHandValue = handValue;
                    delete winners;
                    winners[0] = playerAddr;
                    numWinners = 1;
                } else if (handValue == bestHandValue) {
                    address[] memory newWinners = new address[](numWinners + 1);
                    for (uint256 j = 0; j < numWinners; j++) {
                        newWinners[j] = winners[j];
                    }
                    newWinners[numWinners] = playerAddr;
                    winners = newWinners;
                    numWinners++;
                }
            }
        }

        if (numWinners == 1) {
            players[winners[0]].balance += pot;
        } else {
            uint256 splitPot = pot / numWinners;
            for (uint256 i = 0; i < numWinners; i++) {
                players[winners[i]].balance += splitPot;
            }
        }
        emit PotDistributed(pot, winners, numWinners);

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            Player storage player = players[playerAddr];
            player.hasFolded = false;
        }

        pot = 0;
        currentBet = 0;
        currentPhase = GamePhase.PreFlop;
    }

    function getPlayerHand(address player) external view returns (bytes32[2] memory) {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            if (playerAddresses[i] == player) {
                return currentHand.holeCards[i];
            }
        }
        revert("Player not found");
    }

    function decodeCard(bytes32 card) internal pure returns (uint8 rank, uint8 suit) {
        rank = uint8(uint256(card) % 13); // Rank is 0-12
        suit = uint8(uint256(card) / 13); // Suit is 0-3
        return (rank, suit);
    }

}