mod test {
    use core::traits::Into;
    use starkdeck_contracts::play_poker::PlayPoker;
    use starkdeck_contracts::interface::{IPlayPokerDispatcher, IPlayPokerDispatcherTrait};
    use openzeppelin::token::erc20::ERC20Component::InternalTrait;
    use starknet::{SyscallResultTrait, syscalls::deploy_syscall};
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, contract_address_const
    };
    use starknet::testing;
    use openzeppelin::utils::serde::SerializedAppend;
    use openzeppelin::access::ownable::interface::OwnableABI;
    use openzeppelin::token::erc20::interface::ERC20ABI;
    use starkdeck_contracts::stark_deck_token::StarkDeckToken;
    use starkdeck_contracts::stark_deck_token::StarkDeckToken::{ContractState, ExternalTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    const TOKEN_CONTRACT_ADDRESS: felt252 = 5;
    const CONTRACT_ADDRESS: felt252 = 6;
    const CALLER_ADDRESS: felt252 = 1;
    const OWNER_ADDRESS: felt252 = 1;

    #[test]
    #[available_gas(2_000_000_000)]
    fn it_deploys() {
        let owner = get_caller_address();
        let _token_contract = deploy_token_contract();
        let small_blind: u256 = 1;
        let big_blind: u256 = 2;
        let token = contract_address_const::<TOKEN_CONTRACT_ADDRESS>();
        let _contract = deploy_play_poker(owner, small_blind, big_blind, token);
    }

    #[test]
    #[should_panic] // cannot be tested here, needs a node
    #[available_gas(2_000_000_000)]
    fn it_joins_game() {
        let owner = get_caller_address();
        let small_blind: u256 = 1;
        let big_blind: u256 = 2;
        let token = deploy_token_contract();
        let contract = deploy_play_poker(owner, small_blind, big_blind, token.contract_address);
        contract.join_game(big_blind);
    }

    #[test]
    #[should_panic]
    #[available_gas(2_000_000_000)]
    fn it_fails_to_join_game_with_incorrect_amount() {
        let owner = get_caller_address();
        let small_blind: u256 = 1;
        let big_blind: u256 = 2;
        let token = contract_address_const::<TOKEN_CONTRACT_ADDRESS>();
        let contract = deploy_play_poker(owner, small_blind, big_blind, token);
        contract.join_game(big_blind + 1);
    }

    #[test]
    #[available_gas(2_000_000_000)]
    fn it_shuffles_deck() {
        let owner = get_caller_address();
        let small_blind: u256 = 1;
        let big_blind: u256 = 2;
        let token = contract_address_const::<TOKEN_CONTRACT_ADDRESS>();
        let contract = deploy_play_poker(owner, small_blind, big_blind, token);
        contract.shuffle_deck();
        let shuffled_deck = contract.get_shuffled_deck();
        assert_eq!(shuffled_deck.len(), 52);
    }

    #[test]
    #[should_panic] // cannot be tested here, needs a node
    #[available_gas(2_000_000_000)]
    fn it_joins_game_by_transferring_tokens() {
        testing::set_contract_address(contract_address_const::<TOKEN_CONTRACT_ADDRESS>());
        let owner = get_caller_address();
        let small_blind: u256 = 1;
        let big_blind: u256 = 2;
        let _token_contract = deploy_token_contract();
        let contract = deploy_play_poker(
            owner, small_blind, big_blind, _token_contract.contract_address
        );
        contract.join_game(1);
    }

    fn deploy_play_poker(
        owner: ContractAddress, small_blind: u256, big_blind: u256, token: ContractAddress
    ) -> IPlayPokerDispatcher {
        let mut calldata = array![];
        calldata.append_serde(owner);
        calldata.append_serde(small_blind);
        calldata.append_serde(big_blind);
        calldata.append_serde(token);
        let (contract_address, _) = deploy_syscall(
            PlayPoker::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap_syscall();

        IPlayPokerDispatcher { contract_address }
    }

    fn _deploy_token_contract() -> ContractState {
        let mut contract = StarkDeckToken::contract_state_for_testing();
        StarkDeckToken::constructor(ref contract, contract_address_const::<OWNER_ADDRESS>());
        testing::set_contract_address(contract_address_const::<TOKEN_CONTRACT_ADDRESS>());
        contract
    }

    fn deploy_token_contract() -> IERC20Dispatcher {
        let mut calldata = array![];
        calldata.append_serde(contract_address_const::<OWNER_ADDRESS>());
        let (contract_address, _) = deploy_syscall(
            StarkDeckToken::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap_syscall();

        IERC20Dispatcher { contract_address }
    }
}
