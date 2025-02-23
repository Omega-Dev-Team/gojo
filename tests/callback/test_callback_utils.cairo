use starknet::{ContractAddress, contract_address_const, contract_address_try_from_felt252};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};
use satoru::utils::span32::{Span32, Array32Trait};
use alexandria_data_structures::array_ext::SpanTraitExt;
use core::traits::TryInto;
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
use satoru::event::event_utils::LogData;
use satoru::test_utils::tests_lib::{setup, teardown};
use core::box::BoxTrait;
use core::array::ArrayTrait;
use core::traits::Into;
use core::panic;
use satoru::event::event_utils::{LogDataTrait};
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

// use core::tuple::{TupleSize, TupleTraitImpl};


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

#[test]
fn test_validate_callback_gas_limit() {
    // Setup
    let (world, addresses, data_store_addr, event_emitter_addr, order_vault_addr, 
        position_vault_addr, oracle_store_addr, swap_handler_addr, referral_storage_addr,
        order_handler_addr, position_manager_addr, callback_mock_addr, withdrawal_vault_addr,
        router_addr, market_factory_addr, deposit_vault_addr, deposit_handler_addr,
        order_vault_addr2, position_handler_addr, withdrawal_handler_addr) = setup();
    let data_store = IDataStoreDispatcher { contract_address: data_store_addr };

    // Set max callback gas limit
    let max_limit: u256 = 200000;
    data_store.set_u256(keys::max_callback_gas_limit(), max_limit);

    // Test valid gas limit
    validate_callback_gas_limit(data_store, CALLBACK_GAS_LIMIT);

    // Test exceeding gas limit
    let excessive_limit: u256 = 250000;
    // This should panic with CallbackError::InvalidCallbackGasLimit
    validate_callback_gas_limit(data_store, excessive_limit);

    // Pass both required arguments to teardown
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    teardown(world, market_factory);
}

#[test]
fn test_withdrawal_callbacks() {
    // Setup
    let (
        world, 
        addresses, 
        data_store_addr, 
        event_emitter_addr, 
        order_vault_addr, 
        position_vault_addr, 
        oracle_store_addr, 
        swap_handler_addr, 
        referral_storage_addr,
        order_handler_addr, 
        position_manager_addr, 
        callback_mock_addr, 
        withdrawal_vault_addr,
        router_addr, 
        market_factory_addr, 
        deposit_vault_addr, 
        deposit_handler_addr,
        order_vault_addr2, 
        position_handler_addr, 
        withdrawal_handler_addr
    ) = setup();
    
    // Get the callback mock dispatcher using the address from setup
    let callback_mock = ICallbackMockDispatcher { contract_address: callback_mock_addr };
    
    // Create test withdrawal with the provided mock callback address
    let withdrawal = create_test_withdrawal(callback_mock.contract_address);
    
    // Test initial counter (should be 1 as per the mock contract's constructor)
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data with an empty array of felt252 and event emitter
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_addr };
    let mut log_data = LogData {
        data: array![],
        event_emitter: event_emitter,
        address_dict: Default::default(),
        uint_dict: Default::default(),
        int_dict: Default::default(),
        bool_dict: Default::default(),
        felt252_dict: Default::default(),
        string_dict: Default::default(),
    };

    // Test execution callback
    after_withdrawal_execution(123, withdrawal, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase to 2');

    // Initialize log data with an empty array of felt252 and event emitter
    let mut log_data_cancellation = LogData {
        data: array![],
        event_emitter: event_emitter,
        address_dict: Default::default(),
        uint_dict: Default::default(),
        int_dict: Default::default(),
        bool_dict: Default::default(),
        felt252_dict: Default::default(),
        string_dict: Default::default(),
    };
    
    // Test cancellation callback
    after_withdrawal_cancellation(123, withdrawal, log_data_cancellation);
    assert(callback_mock.get_counter() == 3, 'Counter should increase to 3');

    // Cleanup
    let data_store = IDataStoreDispatcher { contract_address: data_store_addr };
    teardown(world, data_store);
}

#[test]
fn test_order_callbacks() {
    // Setup
    let (world, addresses, data_store_addr, ..) = setup();
    let callback_mock = deploy_callback_mock();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    
    // Create test order with mock callback
    let order = create_test_order(callback_mock.contract_address);
    
    // Test initial counter
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Test execution callback
    let mut log_data = LogData { data: array![] };
    after_order_execution(123, order, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase');

    // Test cancellation callback
    after_order_cancellation(123, order, log_data);
    assert(callback_mock.get_counter() == 3, 'Counter should increase again');

    // Test frozen callback
#[test]
fn test_invalid_callback_contracts() {
    // Setup
    let (world, addresses, data_store_addr, ..) = setup();
    let market_factory = IMarketFactoryDispatcher { contract_address: addresses };
    
    // Test with zero address callbacks
    // These should all return early without error
    let mut log_data = LogData {
        data: array![],
        event_emitter: IEventEmitterDispatcher { contract_address: data_store_addr },
        address_dict: Default::default(),
        uint_dict: Default::default(),
        int_dict: Default::default(),
        bool_dict: Default::default(),
        felt252_dict: Default::default(),
        string_dict: Default::default(),
    };
    let deposit = create_test_deposit(contract_address_const::<0>());
    let withdrawal = create_test_withdrawal(contract_address_const::<0>());
    let order = create_test_order(contract_address_const::<0>());
    after_deposit_execution(123, deposit, log_data);
    after_deposit_cancellation(123, deposit, log_data);
    after_withdrawal_execution(123, withdrawal, log_data);
    after_withdrawal_cancellation(123, withdrawal, log_data);
    after_order_execution(123, order, log_data);
    after_order_cancellation(123, order, log_data);
    after_order_frozen(123, order, log_data);

    teardown(world, market_factory);
}   after_withdrawal_cancellation(123, withdrawal, log_data);
    after_order_execution(123, order, log_data);
    after_order_cancellation(123, order, log_data);
    after_order_frozen(123, order, log_data);

    teardown(world, market_factory);
}