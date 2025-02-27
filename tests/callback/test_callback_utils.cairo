use starknet::{ContractAddress, contract_address_const, contract_address_try_from_felt252};
use snforge_std::{start_prank, stop_prank};
use satoru::utils::span32::{Span32, Array32Trait};
use alexandria_data_structures::array_ext::SpanTraitExt;
use core::traits::TryInto;
use alexandria_data_structures::array_ext::ArrayTraitExt;
use satoru::utils::i256::i256;
use satoru::callback::callback_utils::{
    validate_callback_gas_limit, set_saved_callback_contract, get_saved_callback_contract,
    after_deposit_execution, after_deposit_cancellation, after_withdrawal_execution,
    after_withdrawal_cancellation, after_order_execution, after_order_cancellation,
    after_order_frozen, is_valid_callback_contract
};
use satoru::callback::error::CallbackError;
use satoru::callback::mocks::{ICallbackMockDispatcher, ICallbackMockDispatcherTrait, deploy_callback_mock};
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::order::order::{Order, OrderType, DecreasePositionSwapType};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_utils::{LogData, LogDataTrait};
use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
use satoru::test_utils::tests_lib::{setup, teardown};
use core::box::BoxTrait;
use core::array::ArrayTrait;
use core::traits::Into;
use core::panic_with_felt252;
use core::panic;
use core::byte_array::ByteArray;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::callback::order_callback_receiver::interface::{
    IOrderCallbackReceiverDispatcher, IOrderCallbackReceiverDispatcherTrait
};
use satoru::callback::deposit_callback_receiver::interface::{
    IDepositCallbackReceiverDispatcher, IDepositCallbackReceiverDispatcherTrait
};
use satoru::callback::withdrawal_callback_receiver::interface::{
    IWithdrawalCallbackReceiverDispatcher, IWithdrawalCallbackReceiverDispatcherTrait
};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use integer::U256TryIntoFelt252;

// Constants for testing
const ACCOUNT: felt252 = 123;
const MARKET: felt252 = 456;
const CALLBACK_GAS_LIMIT: u256 = 100000;

// Helper function to create a test deposit
fn create_test_deposit(callback_contract: ContractAddress) -> Deposit {
    Deposit {
        key: 0,
        account: contract_address_const::<'ACCOUNT'>(),
        receiver: contract_address_const::<'ACCOUNT'>(),
        callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<'MARKET'>(),
        initial_long_token: contract_address_const::<0>(),
        initial_short_token: contract_address_const::<0>(),
        initial_long_token_amount: 0,
        initial_short_token_amount: 0,
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        min_market_tokens: 0,
        execution_fee: 0,
        callback_gas_limit: CALLBACK_GAS_LIMIT,
        updated_at_block: 0
    }
}

// Helper function to create a test withdrawal
fn create_test_withdrawal(callback_contract: ContractAddress) -> Withdrawal {
    Withdrawal {
        key: 0,
        account: contract_address_const::<'ACCOUNT'>(),
        receiver: contract_address_const::<'ACCOUNT'>(),
        callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<'MARKET'>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        market_token_amount: 0,
        min_long_token_amount: 0,
        min_short_token_amount: 0,
        execution_fee: 0,
        callback_gas_limit: CALLBACK_GAS_LIMIT,
        // starting_gas: 0,
        // ui_fee_receiver_gas_limit: 0,
        updated_at_block: 0
    }
}

// Helper function to create a test order
fn create_test_order(callback_contract: ContractAddress) -> Order {
    Order {
        key: 0,
        account: contract_address_const::<'ACCOUNT'>(),
        receiver: contract_address_const::<'ACCOUNT'>(),
        callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<'MARKET'>(),
        initial_collateral_token: contract_address_const::<0>(),
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: CALLBACK_GAS_LIMIT,
        min_output_amount: 0,
        order_type: OrderType::MarketSwap,
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
        is_long: false,
        updated_at_block: 0,
        is_frozen: false
    }
}

fn create_log_data(event_emitter_addr: ContractAddress) -> LogData {
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_addr };
    LogData {
        data: @array![],
        emitter: event_emitter,
        address_dict: SerializableFelt252DictTrait::<ContractAddress>::new(),
        uint_dict: SerializableFelt252DictTrait::<u256>::new(),
        int_dict: SerializableFelt252DictTrait::<i256>::new(),
        bool_dict: SerializableFelt252DictTrait::<bool>::new(),
        felt252_dict: SerializableFelt252DictTrait::<felt252>::new(),
        string_dict: SerializableFelt252DictTrait::<felt252>::new(),
    }
}

#[test]
fn test_validate_callback_gas_limit_valid() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let data_store = IDataStoreDispatcher { contract_address: data_store_addr };
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };

    // Set max callback gas limit
    let max_limit: u256 = 200000;
    data_store.set_u256(keys::max_callback_gas_limit(), max_limit);

    // Test valid gas limit
    validate_callback_gas_limit(data_store, CALLBACK_GAS_LIMIT);

    teardown(world, market_factory);
}

#[test]
#[should_panic(expected: ('MAX_CALLBACK_GAS_LIMIT_EXCEEDED',))]
fn test_validate_callback_gas_limit_exceeded() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let data_store = IDataStoreDispatcher { contract_address: data_store_addr };
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };

    // Set max callback gas limit
    let max_limit: u256 = 200000;
    data_store.set_u256(keys::max_callback_gas_limit(), max_limit);

    // Test exceeding gas limit - this should panic
    let excessive_limit: u256 = 250000;
    validate_callback_gas_limit(data_store, excessive_limit);

    // This line should not be reached
    teardown(world, market_factory);
}

#[test]
fn test_saved_callback_contract() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let data_store = IDataStoreDispatcher { contract_address: data_store_addr };
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    let callback_mock = deploy_callback_mock();
    
    // Test account and market
    let account = contract_address_try_from_felt252(ACCOUNT).unwrap();
    let market = contract_address_try_from_felt252(MARKET).unwrap();
    
    // Test set and get
    set_saved_callback_contract(data_store, account, market, callback_mock.contract_address);
    let saved_contract = get_saved_callback_contract(data_store, account, market);
    
    assert(saved_contract == callback_mock.contract_address, 'Wrong saved contract');
    
    teardown(world, market_factory);
}

#[test]
fn test_deposit_callbacks() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    let callback_mock = deploy_callback_mock();
    
    // Create test deposit with mock callback
    let deposit = create_test_deposit(callback_mock.contract_address);
    
    // Test initial counter
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data
    let mut log_data = create_log_data(event_emitter_addr);

    // Test execution callback
    after_deposit_execution(123, deposit, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase');

    // Test cancellation callback
    after_deposit_cancellation(123, deposit, log_data);
    assert(callback_mock.get_counter() == 3, 'Counter should increase again');

    teardown(world, market_factory);
}

#[test]
fn test_withdrawal_callbacks() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    let callback_mock = deploy_callback_mock();
    
    // Create test withdrawal with the provided mock callback address
    let withdrawal = create_test_withdrawal(callback_mock.contract_address);
    
    // Test initial counter (should be 1 as per the mock contract's constructor)
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data
    let mut log_data = create_log_data(event_emitter_addr);

    // Test execution callback
    after_withdrawal_execution(123, withdrawal, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase to 2');
    
    // Test cancellation callback
    after_withdrawal_cancellation(123, withdrawal, log_data);
    assert(callback_mock.get_counter() == 3, 'Counter should increase to 3');

    teardown(world, market_factory);
}

#[test]
fn test_order_callbacks() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    let callback_mock = deploy_callback_mock();
    
    // Create test order with mock callback
    let order = create_test_order(callback_mock.contract_address);
    
    // Test initial counter
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data
    let mut log_data = create_log_data(event_emitter_addr);

    // Test execution callback
    after_order_execution(123, order, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase');

    // Test cancellation callback
    after_order_cancellation(123, order, log_data);
    assert(callback_mock.get_counter() == 3, 'Counter should increase again');

    // Test frozen callback
    after_order_frozen(123, order, log_data);
    assert(callback_mock.get_counter() == 4, 'Counter should increase again');

    teardown(world, market_factory);
}

#[test]
fn test_invalid_callback_contracts() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    
    // Test with zero address callbacks
    // These should all return early without error
    let mut log_data = create_log_data(event_emitter_addr);
    
    let deposit = create_test_deposit(contract_address_const::<0>());
    let withdrawal = create_test_withdrawal(contract_address_const::<0>());
    let order = create_test_order(contract_address_const::<0>());
    
    // These should all return early due to invalid callback contract
    after_deposit_execution(123, deposit, log_data);
    after_deposit_cancellation(123, deposit, log_data);
    after_withdrawal_execution(123, withdrawal, log_data);
    after_withdrawal_cancellation(123, withdrawal, log_data);
    after_order_execution(123, order, log_data);
    after_order_cancellation(123, order, log_data);
    after_order_frozen(123, order, log_data);

    // If we reach here without panics, the test passes
    teardown(world, market_factory);
}

#[test]
fn test_is_valid_callback_contract() {
    // Test with valid address
    let valid_address = contract_address_const::<'VALID_ADDRESS'>();
    assert(is_valid_callback_contract(valid_address) == true, 'Should be valid');
    
    // Test with zero address
    let zero_address = contract_address_const::<0>();
    assert(is_valid_callback_contract(zero_address) == false, 'Should be invalid');
    // No teardown needed as we didn't call setup()
}