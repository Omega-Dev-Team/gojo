use core::traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::deposit::deposit_utils::{create_deposit, cancel_deposit, CreateDepositParams};
use satoru::utils::span32::{Span32, Array32Trait, DefaultSpan32};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::deposit::deposit::{Deposit, DefaultDeposit};
use satoru::market::market::{Market};
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::role::role;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};

#[starknet::interface]
trait IMockDataStore<TContractState> {
    fn set_deposit(ref self: TContractState, key: felt252, deposit: Deposit);
    fn get_deposit(self: @TContractState, key: felt252) -> Deposit;
    fn remove_deposit(ref self: TContractState, key: felt252, account: ContractAddress);
    fn get_market(self: @TContractState, market_token: ContractAddress) -> Market;
}

#[starknet::contract]
mod mock_data_store {
    use starknet::{ContractAddress, contract_address_const};
    use satoru::deposit::deposit::{Deposit, DefaultDeposit};
    use satoru::market::market::Market;

    #[storage]
    struct Storage {
        deposits: LegacyMap::<felt252, Deposit>,
    }

    #[external(v0)]
    impl DataStore of super::IMockDataStore<ContractState> {
        fn set_deposit(ref self: ContractState, key: felt252, deposit: Deposit) {
            self.deposits.write(key, deposit);
        }

        fn get_deposit(self: @ContractState, key: felt252) -> Deposit {
            self.deposits.read(key)
        }

        fn remove_deposit(ref self: ContractState, key: felt252, account: ContractAddress) {
            self.deposits.write(key, DefaultDeposit::default());
        }

        fn get_market(self: @ContractState, market_token: ContractAddress) -> Market {
            Market {
                market_token,
                index_token: market_token,
                long_token: market_token,
                short_token: market_token,
            }
        }
    }
}

#[starknet::interface]
trait IMockEventEmitter<TContractState> {
    fn emit_deposit_created(ref self: TContractState, key: felt252, deposit: Deposit);
    fn emit_deposit_cancelled(ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>);
}

#[starknet::contract]
mod mock_event_emitter {
    use satoru::deposit::deposit::Deposit;
    use array::SpanTrait;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl EventEmitter of super::IMockEventEmitter<ContractState> {
        fn emit_deposit_created(ref self: ContractState, key: felt252, deposit: Deposit) {}
        fn emit_deposit_cancelled(ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>) {}
    }
}

#[starknet::interface]
trait IMockDepositVault<TContractState> {
    fn record_transfer_in(ref self: TContractState, token: ContractAddress) -> u256;
    fn transfer_out(
        ref self: TContractState,
        sender: ContractAddress,
        token: ContractAddress,
        receiver: ContractAddress,
        amount: u256
    );
}

#[starknet::contract]
mod mock_deposit_vault {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl DepositVault of super::IMockDepositVault<ContractState> {
        fn record_transfer_in(ref self: ContractState, token: ContractAddress) -> u256 {
            1000_u256
        }

        fn transfer_out(
            ref self: ContractState,
            sender: ContractAddress,
            token: ContractAddress,
            receiver: ContractAddress,
            amount: u256
        ) {}
    }
}

fn deploy_mock_contracts() -> (IDataStoreDispatcher, IEventEmitterDispatcher, IDepositVaultDispatcher) {
    // Deploy mock contracts
    let data_store = declare('mock_data_store');
    let mut calldata = ArrayTrait::new();
    let data_store_address = data_store.deploy(@calldata).unwrap();

    let event_emitter = declare('mock_event_emitter');
    let event_emitter_address = event_emitter.deploy(@calldata).unwrap();

    let deposit_vault = declare('mock_deposit_vault');
    let deposit_vault_address = deposit_vault.deploy(@calldata).unwrap();

    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    (data_store, event_emitter, deposit_vault)
}

#[test]
#[available_gas(2000000000)]
fn test_create_deposit() {
    let (data_store, event_emitter, deposit_vault) = deploy_mock_contracts();

    let account = contract_address_const::<1>();
    let receiver = contract_address_const::<2>();
    let callback = contract_address_const::<3>();
    let market = contract_address_const::<4>();
    
    let mut long_path = ArrayTrait::new();
    long_path.append(contract_address_const::<5>());
    
    let mut short_path = ArrayTrait::new();
    short_path.append(contract_address_const::<6>());

    let params = CreateDepositParams {
        receiver,
        callback_contract: callback,
        ui_fee_receiver: contract_address_const::<0>(),
        market,
        initial_long_token: contract_address_const::<7>(),
        initial_short_token: contract_address_const::<8>(),
        long_token_swap_path: Array32Trait::span32(@long_path),
        short_token_swap_path: Array32Trait::span32(@short_path),
        min_market_tokens: 100,
        execution_fee: 10,
        callback_gas_limit: 1000000,
    };

    // Impersonate caller account with required role
    start_prank(data_store.contract_address, account);
    
    let key = create_deposit(data_store, event_emitter, deposit_vault, account, params);
    
    stop_prank(data_store.contract_address);

    let deposit = data_store.get_deposit(key);
    assert(deposit.receiver == receiver, 'Invalid receiver');
    assert(deposit.market == market, 'Invalid market');
}

#[test]
#[available_gas(2000000000)]
fn test_cancel_deposit() {
    let (data_store, event_emitter, deposit_vault) = deploy_mock_contracts();

    let key = 123;
    let keeper = contract_address_const::<1>();
    let starting_gas = 100000;
    let reason = 'test_cancel';
    let mut reason_bytes = ArrayTrait::new();
    reason_bytes.append('test');

    // Impersonate caller account with required role
    start_prank(data_store.contract_address, keeper);

    cancel_deposit(
        data_store,
        event_emitter,
        deposit_vault,
        key,
        keeper,
        starting_gas,
        reason,
        reason_bytes
    );

    stop_prank(data_store.contract_address);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('EMPTY_DEPOSIT_AMOUNTS',))]
fn test_create_deposit_zero_amounts() {
    let (data_store, event_emitter, deposit_vault) = deploy_mock_contracts();

    let params = CreateDepositParams {
        receiver: contract_address_const::<1>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<2>(),
        initial_long_token: contract_address_const::<0>(),
        initial_short_token: contract_address_const::<0>(),
        long_token_swap_path: Array32Trait::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::span32(@ArrayTrait::new()),
        min_market_tokens: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    let account = contract_address_const::<1>();
    start_prank(data_store.contract_address, account);

    create_deposit(
        data_store,
        event_emitter,
        deposit_vault,
        account,
        params
    );

    stop_prank(data_store.contract_address);
}
