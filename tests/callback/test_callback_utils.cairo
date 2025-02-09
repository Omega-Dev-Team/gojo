use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::callback::callback_utils::{
    validate_callback_gas_limit, set_saved_callback_contract, get_saved_callback_contract,
    after_deposit_execution, after_deposit_cancellation, is_valid_callback_contract
};
use satoru::callback::error::CallbackError;
use satoru::callback::mocks::{ICallbackMockDispatcher, deploy_callback_mock};
use satoru::deposit::deposit::Deposit;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_utils::LogData;
use satoru::test_utils::tests_lib::{setup, teardown};

// Constants for testing
const ACCOUNT: felt252 = 123;
const MARKET: felt252 = 456;
const CALLBACK_GAS_LIMIT: u256 = 100000;

// Helper function to create a test deposit
fn create_test_deposit(callback_contract: ContractAddress) -> Deposit {
    Deposit {
        account: contract_address_const::<'ACCOUNT'>(),
        receiver: contract_address_const::<'ACCOUNT'>(),
        callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<'MARKET'>(),
        initial_long_token: contract_address_const::<0>(),
        initial_short_token: contract_address_const::<0>(),
        long_token_swap_path: array![],
        short_token_swap_path: array![],
        min_market_tokens: 0,
        execution_fee: 0,
        callback_gas_limit: CALLBACK_GAS_LIMIT,
        starting_gas: 0,
        ui_fee_receiver_gas_limit: 0
    }
}

#[test]
fn test_validate_callback_gas_limit() {
    // Setup
    let (world, address) = setup();
    let data_store = IDataStoreDispatcher { contract_address: address.data_store };
    
    // Set max callback gas limit
    let max_limit: u256 = 200000;
    data_store.set_u256(keys::max_callback_gas_limit(), max_limit);

    // Test valid gas limit
    match validate_callback_gas_limit(data_store, CALLBACK_GAS_LIMIT) {
        () => {},
        // If we get here, the test passed
    };

    // Test exceeding gas limit
    let excessive_limit: u256 = 300000;
    match validate_callback_gas_limit(data_store, excessive_limit) {
        () => panic!("Should have failed with excessive gas limit"),
        panic_data => {
            assert(*panic_data.at(0) == CallbackError::MAX_CALLBACK_GAS_LIMIT_EXCEEDED.into(), 'Wrong error');
        }
    };

    teardown(world);
}

#[test]
fn test_saved_callback_contract() {
    // Setup
    let (world, address) = setup();
    let data_store = IDataStoreDispatcher { contract_address: address.data_store };
    
    let account = contract_address_const::<'ACCOUNT'>();
    let market = contract_address_const::<'MARKET'>();
    let callback_mock = deploy_callback_mock();

    // Test setting and getting callback contract
    set_saved_callback_contract(data_store, account, market, callback_mock.contract_address);
    let saved_contract = get_saved_callback_contract(data_store, account, market);
    
    assert(saved_contract == callback_mock.contract_address, 'Wrong callback contract');

    teardown(world);
}

#[test]
fn test_deposit_callbacks() {
    // Setup
    let (world, address) = setup();
    let callback_mock = deploy_callback_mock();
    
    // Create test deposit with mock callback
    let deposit = create_test_deposit(callback_mock.contract_address);
    
    // Test initial counter
    assert(callback_mock.get_counter() == 1, 'Wrong initial counter');

    // Test execution callback
    let mut log_data = LogData { data: array![] };
    after_deposit_execution(123, deposit, log_data);
    assert(callback_mock.get_counter() == 2, 'Counter should increase');

    // Test cancellation callback
    after_deposit_cancellation(123, deposit, log_data);
    assert(callback_mock.get_counter() == 3, 'Counter should increase again');

    teardown(world);
}

#[test]
fn test_is_valid_callback_contract() {
    // Test with zero address
    assert(!is_valid_callback_contract(contract_address_const::<0>()), 'Should be invalid');
    
    // Test with non-zero address
    assert(is_valid_callback_contract(contract_address_const::<1>()), 'Should be valid');
}