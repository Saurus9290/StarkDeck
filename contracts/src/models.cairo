use starknet::ContractAddress;
use starkdeck_contracts::events::game_events::game_phase::{PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN};
use starkdeck_contracts::impls::{StoreHoleCardsArray, StoreCommunityCardsArray};
use alexandria_storage::list::{List, ListTrait};

#[derive(Drop, Serde, Copy, PartialEq, starknet::Event, starknet::Store)]
pub enum GamePhase {
    PRE_FLOP: PRE_FLOP,
    FLOP: FLOP,
    TURN: TURN,
    RIVER: RIVER,
    SHOWDOWN: SHOWDOWN
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct Player {
    pub address: ContractAddress,
    pub balance: u256,
    pub is_playing: bool,
    pub has_folded: bool,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct HoleCards {
    pub card1: u256,
    pub card2: u256,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct CommunityCards {
    pub card1: u256,
    pub card2: u256,
    pub card3: u256,
    pub card4: u256,
    pub card5: u256,
}

#[derive(Drop, starknet::Store)]
pub struct Hand {
    pub hole_cards: List<HoleCards>,
    pub community_cards: List<CommunityCards>,
    pub player_commitments: PlayerCommittments,
    pub revealed: Revealed,
    pub revealed_hands: RevealedHands,
    pub is_valid_proof: IsValidProof,
    pub hand_strength: HandStrength,
    pub index: u256,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct PlayerCommittments {
    player_address: ContractAddress,
    committment: u256,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct Revealed {
    player_address: ContractAddress,
    revealed: bool,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct RevealedHands {
    player_address: ContractAddress,
    pub card1: u256,
    pub card2: u256,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct IsValidProof {
    player_address: ContractAddress,
    is_valid: bool,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct HandStrength {
    player_address: ContractAddress,
    strength: u256,
}

#[derive(Drop, Hash)]
pub struct DeckCard {
    pub suite: u8,
    pub rank: u8,
    pub index: u8
}

#[derive(Drop, Hash)]
pub struct Block {
    pub block_timestamp: u64,
    pub block_number: u64,
}
