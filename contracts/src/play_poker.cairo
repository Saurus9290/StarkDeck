#[starknet::contract]
pub(crate) mod PlayPoker {
    use core::option::OptionTrait;
    use core::result::ResultTrait;
    use core::box::BoxTrait;
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use core::traits::TryInto;
    use alexandria_storage::list::ListTrait;
    use core::dict::Felt252DictTrait;
    use core::traits::Into;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address,
        contract_address_const, get_block_timestamp, get_block_number
    };
    use starkdeck_contracts::events::game_events::game_phase::{
        PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starkdeck_contracts::events::game_events::{
        GameStarted, PlayerLeft, PlayerJoined, PlayerFolded, Shuffled, HandDealt, PlayerCommitted,
        PlayerRevealed, BetPlaced, PotUpdated, PotDistributed, PhaseAdvanced
    };
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starkdeck_contracts::models::{GamePhase, Player, Hand, DeckCard, Block, HoleCards};
    use starkdeck_contracts::impls::{StoreFelt252Array, PartialOrdFelt};
    use starkdeck_contracts::constants::{NUM_CARDS, NUM_PLAYERS, NUM_BOARD_CARDS};
    use starkdeck_contracts::interface::{IPlayPoker};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        small_blind: u256,
        big_blind: u256,
        current_phase: GamePhase,
        players: LegacyMap<ContractAddress, Player>,
        player_addresses: LegacyMap<u256, ContractAddress>,
        total_players: u256,
        current_hand: Hand,
        shuffled_deck: Array<felt252>,
        current_bet: u256,
        pot: u256,
        token: IERC20Dispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        GameStarted: GameStarted,
        PlayerLeft: PlayerLeft,
        PlayerJoined: PlayerJoined,
        PlayerFolded: PlayerFolded,
        Shuffled: Shuffled,
        HandDealt: HandDealt,
        PhaseAdvanced: PhaseAdvanced,
        PlayerCommitted: PlayerCommitted,
        PlayerRevealed: PlayerRevealed,
        BetPlaced: BetPlaced,
        PotUpdated: PotUpdated,
        PotDistributed: PotDistributed,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        token: ContractAddress,
        _small_blind: felt252,
        _big_blind: felt252,
    ) {
        self.ownable.initializer(owner);
        self.small_blind.write(_small_blind.into());
        self.big_blind.write(_big_blind.into());
        self.token.write(IERC20Dispatcher { contract_address: token });
        self.total_players.write(0);
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    pub impl PlayPokerImpl of IPlayPoker<ContractState> {
        fn join_game(ref self: ContractState, amount: u256) {
            assert!(
                self.token.read().balance_of(get_caller_address()) >= amount,
                "Insufficient balance to join the game"
            );
            self.token.read().transfer_from(get_caller_address(), get_contract_address(), amount);
            let player = Player {
                balance: amount, address: get_caller_address(), is_playing: true, has_folded: false
            };
            let total_players = self.total_players.read();
            self.player_addresses.write(total_players, get_caller_address());
            self.players.write(player.address, player);
            self.total_players.write(total_players + 1);
            self.emit(PlayerJoined { player: get_caller_address() });
        }

        fn start_game(ref self: ContractState) {
            let total_players = self.total_players.read();
            assert!(total_players >= 2, "Minimum 2 players required to start the game");
            self.current_phase.write(GamePhase::PRE_FLOP(PRE_FLOP {}));
            self.emit(GameStarted {});
        }

        fn shuffle_deck(ref self: ContractState) {
            assert!(
                self.current_phase.read() == GamePhase::PRE_FLOP(PRE_FLOP {}),
                "Phase should be PRE_FLOP"
            );
            let mut deck: Array<felt252> = array![];
            let mut suite: u8 = 0;
            let mut rank: u8 = 0;
            let mut index: u32 = 0;
            while suite < 4 {
                while rank < 13 {
                    let deck_card = DeckCard { suite, rank, index: index.try_into().unwrap() };
                    let hash = PoseidonTrait::new().update_with(deck_card).finalize();
                    deck.append(hash);
                    rank += 1;
                    index += 1;
                };
                suite += 1;
                rank = 0;
            };

            index = 0;
            let mut shuffled_deck_dict: Felt252Dict<felt252> = Default::default();
            while index < NUM_CARDS {
                let block_timestamp = get_block_timestamp();
                let block_number = get_block_number();
                let block = Block { block_timestamp, block_number };
                let hash = PoseidonTrait::new().update_with(block).finalize();
                let swap_pos: u256 = hash.into() % (NUM_CARDS - index).into();
                let temp = *deck[swap_pos.try_into().unwrap()];
                shuffled_deck_dict.insert(index.into(), temp);
                index += 1;
            };

            let mut shuffled_deck: Array<felt252> = array![];

            index = 0;
            while index < NUM_CARDS {
                shuffled_deck.append(shuffled_deck_dict.get(index.into()));
                index += 1;
            };
            self.shuffled_deck.write(shuffled_deck);
            self.emit(Shuffled {});
        }

        fn deal_hand(ref self: ContractState) {
            let total_players = self.total_players.read();
            assert!(total_players >= 2, "Minimum 2 players required to start the game");
            let mut deck_index = 0;
            let mut current_hand = @self.current_hand.read();
            let shuffled_deck = @self.shuffled_deck.read();
            let mut i = 0;
            let mut j = 0;
            while i < 2 {
                while j < total_players {
                    let player_address = self.player_addresses.read(j);
                    let player = self.players.read(player_address);
                    if player.is_playing {
                        let mut hole_cards = current_hand
                            .hole_cards
                            .get(j.try_into().unwrap())
                            .unwrap()
                            .unwrap_or(HoleCards { card1: 0, card2: 0 });
                        if i == 0 {
                            hole_cards
                                .card1 =
                                    (*shuffled_deck
                                        .get(deck_index)
                                        .unwrap()
                                        .unbox()
                                        .try_into()
                                        .unwrap())
                                .into();
                        } else if i == 1 {
                            hole_cards
                                .card2 =
                                    (*shuffled_deck
                                        .get(deck_index)
                                        .unwrap()
                                        .unbox()
                                        .try_into()
                                        .unwrap())
                                .into();
                        };
                        deck_index += 1;
                    };
                    j += 1;
                };
                i += 1;
            };

            self.current_phase.write(GamePhase::FLOP(FLOP {}));
            self.emit(HandDealt {});
            self.emit(PhaseAdvanced { phase: GamePhase::FLOP(FLOP {}) });
        }

        fn get_player(self: @ContractState, player: ContractAddress) -> Player {
            self.players.read(player)
        }

        fn get_current_phase(self: @ContractState) -> GamePhase {
            self.current_phase.read()
        }

        fn get_shuffled_deck(self: @ContractState) -> Array<felt252> {
            self.shuffled_deck.read()
        }

        fn get_total_players(self: @ContractState) -> u256 {
            self.total_players.read()
        }
    }
}
