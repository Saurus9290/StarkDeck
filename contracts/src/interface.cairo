use starknet::ContractAddress;
use starkdeck_contracts::models::{Player, GamePhase, Hand};

#[starknet::interface]
pub trait IPlayPoker<TContractState> {
    fn join_game(ref self: TContractState, amount: u256);
    fn start_game(ref self: TContractState);
    fn shuffle_deck(ref self: TContractState);
    fn deal_hand(ref self: TContractState);
    fn get_player(self: @TContractState, player: ContractAddress) -> Player;
    fn get_current_phase(self: @TContractState) -> GamePhase;
    fn get_shuffled_deck(self: @TContractState) -> Array<felt252>;
    fn get_total_players(self: @TContractState) -> u256;
}
