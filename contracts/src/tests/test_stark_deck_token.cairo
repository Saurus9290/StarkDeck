mod tests {
    use openzeppelin::access::ownable::interface::OwnableABI;
    use openzeppelin::token::erc20::interface::ERC20ABI;
    use starkdeck_contracts::stark_deck_token::StarkDeckToken;
    use starkdeck_contracts::stark_deck_token::StarkDeckToken::{ContractState, ExternalTrait};
    use starknet::{SyscallResultTrait, syscalls::deploy_syscall};
    use openzeppelin::utils::serde::SerializedAppend;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{contract_address_const, get_contract_address};
    use starknet::testing;

    fn contract_state() -> ContractState {
        let mut contract = StarkDeckToken::contract_state_for_testing();
        StarkDeckToken::constructor(ref contract, contract_address_const::<1>());
        contract
    }

    #[test]
    fn test_mint() {
        let mut contract = contract_state();
        testing::set_caller_address(contract_address_const::<1>());
        contract.mint(contract_address_const::<2>(), 1000);
        assert_eq!(contract.balance_of(contract_address_const::<2>()), 1000, "balance of owner");
    }

    #[test]
    fn test_owner() {
        let mut contract = contract_state();
        testing::set_caller_address(contract_address_const::<1>());
        assert_eq!(contract.owner(), contract_address_const::<1>(), "Owner must be 1");
    }

    #[test]
    fn test_symbol() {
        let mut contract = contract_state();
        assert_eq!(contract.symbol(), "SDT", "Symbol must be SDT");
    }
}
