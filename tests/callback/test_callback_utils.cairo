use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::contract_address_try_from_felt252;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};
use satoru::utils::span32::{Span32, Array32Trait};
use alexandria_data_structures::array_ext::SpanTraitExt;
use core::traits::TryInto;
use satoru::utils::i256::i256;
use satoru::callback::callback_utils::{
    validate_callback_gas_limit as validateCallbackGasLimit, 
    set_saved_callback_contract as setSavedCallbackContract, 
    get_saved_callback_contract as getSavedCallbackContract,
    after_deposit_execution as afterDepositExecution, 
    after_deposit_cancellation as afterDepositCancellation, 
    after_withdrawal_execution as afterWithdrawalExecution,
    after_withdrawal_cancellation as afterWithdrawalCancellation, 
    after_order_execution as afterOrderExecution, 
    after_order_cancellation as afterOrderCancellation,
    after_order_frozen as afterOrderFrozen, 
    is_valid_callback_contract as isValidCallbackContract
};
use satoru::callback::error::CallbackError;
use satoru::callback::mocks::{ICallbackMockDispatcher, ICallbackMockDispatcherTrait};
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::order::order::{Order, OrderType, DecreasePositionSwapType};
use satoru::data::data_store::IDataStoreDispatcher;
use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::data::keys;
use satoru::event::event_utils::{LogData, LogDataTrait};
use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
use core::array::ArrayTrait;
use core::panic_with_felt252;
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

// Constants for testing
const ACCOUNT: felt252 = 123;
const MARKET: felt252 = 456;
const CALLBACK_GAS_LIMIT: u256 = 100000;
const MAX_CALLBACK_GAS_LIMIT: u256 = 200000;
const EXCESSIVE_GAS_LIMIT: u256 = 250000;

// Helper function to deploy a callback mock contract
fn deployCallbackMock() -> ICallbackMockDispatcher {
    let callbackMockClass = declare('CallbackMock');
    let callbackMockAddress = callbackMockClass.deploy(@ArrayTrait::new()).unwrap();
    ICallbackMockDispatcher { contract_address: callbackMockAddress }
}

// Helper function to deploy mock contracts for testing
fn deployMockContracts() -> (IDataStoreDispatcher, IEventEmitterDispatcher, ICallbackMockDispatcher) {
    // Deploy role store
    let roleStoreClass = declare('RoleStore');
    let roleStore = roleStoreClass.deploy(@ArrayTrait::new()).unwrap();
    
    // Deploy data store
    let dataStore = declare('DataStore');
    let dataStoreAddress = dataStore.deploy(@array![roleStore.into()]).unwrap();
    
    // Deploy event emitter
    let eventEmitter = declare('EventEmitter');
    let eventEmitterAddress = eventEmitter.deploy(@ArrayTrait::new()).unwrap();
    
    // Deploy callback mock
    let callbackMock = deployCallbackMock();
    
    // Create dispatchers
    let dataStore = IDataStoreDispatcher { contract_address: dataStoreAddress };
    let eventEmitter = IEventEmitterDispatcher { contract_address: eventEmitterAddress };
    
    // Set up max callback gas limit in the data store
    dataStore.setU256(keys::maxCallbackGasLimit(), MAX_CALLBACK_GAS_LIMIT);
    
    (dataStore, eventEmitter, callbackMock)
}

// Helper function to create a test deposit
fn createTestDeposit(callback_contract: ContractAddress) -> Deposit {
    Deposit {
        key: 0,
        account: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        receiver: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        callback_contract: callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_try_from_felt252(MARKET).unwrap(),
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
fn createTestWithdrawal(callback_contract: ContractAddress) -> Withdrawal {
    Withdrawal {
        key: 0,
        account: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        receiver: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        callback_contract: callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_try_from_felt252(MARKET).unwrap(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        market_token_amount: 0,
        min_long_token_amount: 0,
        min_short_token_amount: 0,
        execution_fee: 0,
        callback_gas_limit: CALLBACK_GAS_LIMIT,
        updated_at_block: 0
    }
}

// Helper function to create a test order
fn createTestOrder(callback_contract: ContractAddress) -> Order {
    Order {
        key: 0,
        account: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        receiver: contract_address_try_from_felt252(ACCOUNT).unwrap(),
        callback_contract: callback_contract,
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_try_from_felt252(MARKET).unwrap(),
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

// Helper function to create LogData for testing
fn createLogData(event_emitter: IEventEmitterDispatcher) -> LogData {
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
fn testValidateCallbackGasLimit() {
    let (dataStore, _, _) = deployMockContracts();
    
    // Test valid gas limit - should not panic
    validateCallbackGasLimit(dataStore, CALLBACK_GAS_LIMIT);
    
    // Test zero gas limit - should not panic
    validateCallbackGasLimit(dataStore, 0);
}

#[test]
#[should_panic(expected: ('MAX_CALLBACK_GAS_LIMIT_EXCEEDED',))]
fn testValidateCallbackGasLimitExceeded() {
    let (dataStore, _, _) = deployMockContracts();
    
    // Test exceeding gas limit - should panic
    validateCallbackGasLimit(dataStore, EXCESSIVE_GAS_LIMIT);
}

#[test]
fn testSavedCallbackContract() {
    let (dataStore, _, callbackMock) = deployMockContracts();
    
    // Test account and market
    let account = contract_address_try_from_felt252(ACCOUNT).unwrap();
    let market = contract_address_try_from_felt252(MARKET).unwrap();
    
    // Test set and get callback contract
    setSavedCallbackContract(dataStore, account, market, callbackMock.contract_address);
    let savedContract = getSavedCallbackContract(dataStore, account, market);
    
    assert(savedContract == callbackMock.contract_address, 'Wrong saved contract');
}

#[test]
fn testIsValidCallbackContract() {
    // Test with valid address
    let validAddress = contract_address_const::<'VALID_ADDRESS'>();
    assert(isValidCallbackContract(validAddress), 'Should be valid');
    
    // Test with zero address
    let zeroAddress = contract_address_const::<0>();
    assert(!isValidCallbackContract(zeroAddress), 'Should be invalid');
}

#[test]
fn testDepositCallbacks() {
    let (_, event_emitter, callbackMock) = deployMockContracts();
    
    // Create test deposit with mock callback
    let deposit = createTestDeposit(callbackMock.contract_address);
    
    // Test initial counter
    assert(callbackMock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data
    let log_data = createLogData(event_emitter);

    // Test execution callback
    afterDepositExecution(123, deposit, log_data);
    assert(callbackMock.get_counter() == 2, 'Counter should increase to 2');

    // Create new log data for next test
    let log_data = createLogData(event_emitter);
    
    // Test cancellation callback
    afterDepositCancellation(123, deposit, log_data);
    assert(callbackMock.get_counter() == 3, 'Counter should increase to 3');
}

#[test]
fn testWithdrawalCallbacks() {
    let (_, event_emitter, callbackMock) = deployMockContracts();
    
    // Create test withdrawal with the provided mock callback address
    let withdrawal = createTestWithdrawal(callbackMock.contract_address);
    
    // Test initial counter
    assert(callbackMock.get_counter() == 1, 'Wrong initial counter');

    // Initialize log data
    let log_data = createLogData(event_emitter);

    // Test execution callback
    afterWithdrawalExecution(123, withdrawal, log_data);
    assert(callbackMock.get_counter() == 2, 'Counter should increase to 2');
    
    // Create new log data for next test
    let log_data = createLogData(event_emitter);
    
    // Test cancellation callback
    afterWithdrawalCancellation(123, withdrawal, log_data);
    assert(callbackMock.get_counter() == 3, 'Counter should increase to 3');
}

#[test]
fn testOrderCallbacks() {
    let (_, event_emitter, callbackMock) = deployMockContracts();
    
    // Create test order with mock callback
    let order = createTestOrder(callbackMock.contract_address);
    
    // Test initial counter
    assert(callbackMock.get_counter() == 1, 'Wrong initial counter');

    // Test execution callback
    let log_data = createLogData(event_emitter);
    afterOrderExecution(123, order, log_data);
    assert(callbackMock.get_counter() == 2, 'Counter should increase to 2');

    // Test cancellation callback
    let log_data = createLogData(event_emitter);
    afterOrderCancellation(123, order, log_data);
    assert(callbackMock.get_counter() == 3, 'Counter should increase to 3');

    // Test frozen callback
    let log_data = createLogData(event_emitter);
    afterOrderFrozen(123, order, log_data);
    assert(callbackMock.get_counter() == 4, 'Counter should increase to 4');
}

#[test]
fn testInvalidCallbackContracts() {
    let (_, event_emitter, _) = deployMockContracts();
    
    // Test with zero address callbacks
    let deposit = createTestDeposit(contract_address_const::<0>());
    let withdrawal = createTestWithdrawal(contract_address_const::<0>());
    let order = createTestOrder(contract_address_const::<0>());
    
    // These should all return early due to invalid callback contract without errors
    // Create a new log_data for each function call to avoid move errors
    afterDepositExecution(123, deposit, createLogData(event_emitter));
    afterDepositCancellation(123, deposit, createLogData(event_emitter));
    afterWithdrawalExecution(123, withdrawal, createLogData(event_emitter));
    afterWithdrawalCancellation(123, withdrawal, createLogData(event_emitter));
    afterOrderExecution(123, order, createLogData(event_emitter));
    afterOrderCancellation(123, order, createLogData(event_emitter));
    afterOrderFrozen(123, order, createLogData(event_emitter));
    
    // If we reach here without panics, the test passes
    assert(true, 'Test should not panic');
}