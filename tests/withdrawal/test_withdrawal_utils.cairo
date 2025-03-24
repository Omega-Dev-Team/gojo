use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

// Local imports.
use satoru::bank::{bank::{IBankDispatcher, IBankDispatcherTrait},};
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::callback::callback_utils;
use satoru::event::{event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait}};
use satoru::fee::fee_utils;
use satoru::gas::gas_utils;
use satoru::market::{
    market::Market, market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait},
    market_utils, market_utils::MarketPrices
};
use satoru::nonce::nonce_utils;
use satoru::oracle::{oracle::{IOracleDispatcher, IOracleDispatcherTrait}, oracle_utils};
use satoru::pricing::{swap_pricing_utils, swap_pricing_utils::SwapFees};
use satoru::swap::{swap_utils, swap_utils::SwapParams};
use satoru::utils::{
    calc, account_utils, error_utils, precision, starknet_utils, span32::Span32,
    store_arrays::{StoreContractAddressArray, StoreU256Array}
};
use satoru::withdrawal::{
    error::WithdrawalError, withdrawal::Withdrawal,
    withdrawal_vault::{IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait},
    withdrawal_utils::{create_withdrawal, cancel_withdrawal, swap, execute_withdrawal, CreateWithdrawalParams, ExecuteWithdrawalParams}
};
use satoru::market::market_utils::validate_enabled_market_check;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};




fn deploy_contracts() -> (
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IMarketTokenDispatcher,
    IOracleDispatcher,
    IWithdrawalVaultDispatcher
) {
    // Deploy mock contracts
    let role_store_class = declare('RoleStore');
    let role_store_address = role_store_class.deploy(@ArrayTrait::new()).unwrap();
    let data_store = declare('DataStore');
    let data_store_address = data_store.deploy(@array![role_store_address.into()]).unwrap();

    let event_emitter = declare('EventEmitter');
    let mut calldata = ArrayTrait::new();
    let event_emitter_address = event_emitter.deploy(@calldata).unwrap();

    let withdrawal_vault = declare('WithdrawalVault');
    let withdrawal_vault_address = withdrawal_vault.deploy(@array![data_store_address.into(),role_store_address.into(), ]).unwrap();

    let market_token = declare('MarketToken');
    let market_token_address = market_token.deploy(@array![data_store_address.into(),role_store_address.into()]).unwrap();

    let oracle_store = declare('OracleStore');
    let oracle_store_address = oracle_store.deploy(@array![role_store_address.into(),event_emitter_address.into()]).unwrap();

    let oracle = declare('Oracle');
    let oracle_address = oracle.deploy(@array![role_store_address.into(),oracle_store_address.into(), contract_address_const::<0x123>().into()]).unwrap();

    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let oracle = IOracleDispatcher { contract_address: oracle_address };
    let market_token = IMarketTokenDispatcher { contract_address: market_token_address };
    let withdrawal_vault = IWithdrawalVaultDispatcher { contract_address: withdrawal_vault_address };

    (data_store, event_emitter, market_token, oracle, withdrawal_vault)
}


#[test]
fn test_create_withdrawal_success() {
    let (data_store, event_emitter, market_token, oracle, withdrawal_vault) = deploy_contracts();
        
    // Set up test data
    let account = contract_address_const::<0x200>();
    let receiver = contract_address_const::<0x201>();
    let callback_contract = contract_address_const::<0x202>();
    let ui_fee_receiver = contract_address_const::<0x203>();
    let market = contract_address_const::<0x100>();
        
    // Create empty swap paths
    let long_token_swap_path = ArrayTrait::<ContractAddress>::new().span32();
    let short_token_swap_path = ArrayTrait::<ContractAddress>::new().span32();
        
    let params = CreateWithdrawalParams {
        receiver,
        callback_contract,
        ui_fee_receiver,
        market,
        long_token_swap_path,
        short_token_swap_path,
        min_long_token_amount: 50000000000000000_u256,
        min_short_token_amount: 50000000000000000_u256,
        execution_fee: 0_u256,
        callback_gas_limit: 100000_u256,
    };
        
        
    // Execute function
    let key = create_withdrawal(
        IDataStoreDispatcher { contract_address: data_store.contract_address },
        IEventEmitterDispatcher { contract_address: event_emitter.contract_address },
        IWithdrawalVaultDispatcher { contract_address: withdrawal_vault.contract_address },
        account,
        params
    );
        
    // Verify withdrawal was created
    let stored_withdrawal = data_store.get_withdrawal(key);
    assert(stored_withdrawal.account == account, 'Wrong account');
    assert(stored_withdrawal.receiver == receiver, 'Wrong receiver');
    assert(stored_withdrawal.market == market, 'Wrong market');
}
    
#[test]
#[should_panic]
fn test_create_withdrawal_insufficient_fee() {
    let (data_store, event_emitter, market_token, oracle, withdrawal_vault) = deploy_contracts();
        
    // Set up test data
    let account = contract_address_const::<0x200>();
    let receiver = contract_address_const::<0x201>();
    let callback_contract = contract_address_const::<0x202>();
    let ui_fee_receiver = contract_address_const::<0x203>();
    let market = contract_address_const::<0x100>();
        
    // Create empty swap paths
    let long_token_swap_path = ArrayTrait::<ContractAddress>::new().span32();
    let short_token_swap_path = ArrayTrait::<ContractAddress>::new().span32();
        
    let params = CreateWithdrawalParams {
        receiver,
        callback_contract,
        ui_fee_receiver,
        market,
        long_token_swap_path,
        short_token_swap_path,
        min_long_token_amount: 50000000000000000_u256,
        min_short_token_amount: 50000000000000000_u256,
        execution_fee: 1000000000_u256, // Higher than available
        callback_gas_limit: 100000_u256,
    };
        
        
        
    // Should fail due to insufficient fee
    create_withdrawal(
        IDataStoreDispatcher { contract_address: data_store.contract_address },
        IEventEmitterDispatcher { contract_address: event_emitter.contract_address },
        IWithdrawalVaultDispatcher { contract_address: withdrawal_vault.contract_address },
        account,
        params
    );
}
    

    
#[test]
fn test_cancel_withdrawal() {
let (data_store, event_emitter, market_token, oracle, withdrawal_vault) = deploy_contracts();
        
    // Create a withdrawal first
    let account = contract_address_const::<0x200>();
    let market = contract_address_const::<0x100>();
    let key = 0x123;
        
    // Create and store withdrawal
    let withdrawal = Withdrawal {
            key: key,
            account: account,
            receiver: contract_address_const::<0x201>(),
            callback_contract: contract_address_const::<0x202>(),
            ui_fee_receiver: contract_address_const::<0x203>(),
            market: market,
            long_token_swap_path: ArrayTrait::<ContractAddress>::new().span32(),
            short_token_swap_path: ArrayTrait::<ContractAddress>::new().span32(),
            market_token_amount: 100000000000000000_u256,
            min_long_token_amount: 50000000000000000_u256,
            min_short_token_amount: 50000000000000000_u256,
            updated_at_block: get_block_timestamp(),
            execution_fee: 10000000000000000_u256,
            callback_gas_limit: 100000_u256,
    };
        
    data_store.set_withdrawal(key, withdrawal);
        
        
        
    // Cancel the withdrawal
    let keeper = contract_address_const::<0x300>();
    let mut reason_bytes = ArrayTrait::<felt252>::new();
        
    cancel_withdrawal(
            IDataStoreDispatcher { contract_address: data_store.contract_address },
            IEventEmitterDispatcher { contract_address: event_emitter.contract_address },
            IWithdrawalVaultDispatcher { contract_address: withdrawal_vault.contract_address },
            key,
            keeper,
            100000_u256,
            'TEST_CANCELLATION',
            reason_bytes
    );
        
        // Verify withdrawal was removed
    let stored_withdrawal = data_store.get_withdrawal(key);
    assert(stored_withdrawal.account == Zeroable::zero(), 'Withdrawal not removed');
}
    
#[test]
#[should_panic]
fn test_cancel_nonexistent_withdrawal() {
    let (data_store, event_emitter, market_token, oracle, withdrawal_vault) = deploy_contracts();
        
    // Try to cancel a non-existent withdrawal
    let key = 0x456;
    let keeper = contract_address_const::<0x300>();
    let mut reason_bytes = ArrayTrait::<felt252>::new();
        
    cancel_withdrawal(
        IDataStoreDispatcher { contract_address: data_store.contract_address },
        IEventEmitterDispatcher { contract_address: event_emitter.contract_address },
        IWithdrawalVaultDispatcher { contract_address: withdrawal_vault.contract_address },
        key,
        keeper,
        100000_u256,
        'TEST_CANCELLATION',
        reason_bytes
    );
}

#[test]
fn test_swap() {
    let (data_store, event_emitter, market_token, oracle, withdrawal_vault) = deploy_contracts();

    // Set up test data
    let key = 0x123;
    let ui_fee_receiver = contract_address_const::<0x203>();
    let min_oracle_block_numbers: Array<u64> = array![2000000_u64, 120000_u64, 100000_u64];
    let min_oracle_block_numbers: Array<u64> = array![20000000_u64, 12000000_u64, 1000000_u64];
    let keeper = contract_address_const::<0x300>();
    let some_token = contract_address_const::<0x400>();
    let token_in = contract_address_const::<0x200>();
    let receiver = contract_address_const::<0x500>();
    let ui_fee_receiver = contract_address_const::<0x600>();
    let amount_in: u256 = 100000000000_u256;

    // create execute withdrawal paramas
    let params = ExecuteWithdrawalParams{
        data_store: IDataStoreDispatcher{contract_address: data_store.contract_address},
        event_emitter: IEventEmitterDispatcher{contract_address: event_emitter.contract_address},
        withdrawal_vault: IWithdrawalVaultDispatcher{contract_address: withdrawal_vault.contract_address},
        oracle: IOracleDispatcher{contract_address: oracle.contract_address},
        key,
        min_oracle_block_numbers,
        max_oracle_block_numbers,
        keeper,
        starting_gas: 1000000000000_u256,
    };
    // create market data
    let market = Market {
        market_token: market_token.contract_address,
        index_token: some_token,
        long_token: some_token,
        short_token: some_token,
    };
    
    let swap_path = ArrayTrait::<ContractAddress>::new().span32();
    let (output_token, output_amount) = swap(
        @params,
        market,
        token_in,
        amount_in,
        swap_path,
        min_output_amount: 100000000000_u256,
        receiver,
        ui_fee_receiver,
    );

    assert!(output_token == token_in, 'invalid token');
    assert!(output_amount == amount_in, 'invalid amount');
}