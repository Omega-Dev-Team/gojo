use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use satoru::utils::span32::{Span32, Array32Trait, DefaultSpan32};
use satoru::deposit::deposit::{Deposit, DefaultDeposit};

#[test]
fn test_deposit_default_values() {
    let deposit = DefaultDeposit::default();
    
    // Test key
    assert(deposit.key == 0, 'key should be 0');
    
    // Test addresses
    assert(deposit.account == contract_address_const::<0>(), 'wrong account');
    assert(deposit.receiver == contract_address_const::<0>(), 'wrong receiver');
    assert(deposit.callback_contract == contract_address_const::<0>(), 'wrong callback');
    assert(deposit.ui_fee_receiver == contract_address_const::<0>(), 'wrong ui fee receiver');
    assert(deposit.market == contract_address_const::<0>(), 'wrong market');
    assert(deposit.initial_long_token == contract_address_const::<0>(), 'wrong long token');
    assert(deposit.initial_short_token == contract_address_const::<0>(), 'wrong short token');
    
    // Test amounts
    assert(deposit.initial_long_token_amount == 0, 'wrong long amount');
    assert(deposit.initial_short_token_amount == 0, 'wrong short amount');
    assert(deposit.min_market_tokens == 0, 'wrong min tokens');
    
    // Test other values
    assert(deposit.updated_at_block == 0, 'wrong block');
    assert(deposit.execution_fee == 0, 'wrong execution fee');
    assert(deposit.callback_gas_limit == 0, 'wrong gas limit');
}

#[test]
fn test_deposit_custom_values() {
    // Create addresses for testing
    let account = contract_address_const::<1>();
    let receiver = contract_address_const::<2>();
    let callback = contract_address_const::<3>();
    let ui_fee = contract_address_const::<4>();
    let market = contract_address_const::<5>();
    let long_token = contract_address_const::<6>();
    let short_token = contract_address_const::<7>();

    // Create swap paths
    let mut long_path = ArrayTrait::new();
    long_path.append(contract_address_const::<8>());
    long_path.append(contract_address_const::<9>());

    let mut short_path = ArrayTrait::new();
    short_path.append(contract_address_const::<10>());

    // Create deposit with custom values
    let deposit = Deposit {
        key: 123,
        account: account,
        receiver: receiver,
        callback_contract: callback,
        ui_fee_receiver: ui_fee,
        market: market,
        initial_long_token: long_token,
        initial_short_token: short_token,
        long_token_swap_path: Array32Trait::span32(@long_path),
        short_token_swap_path: Array32Trait::span32(@short_path),
        initial_long_token_amount: 1000,
        initial_short_token_amount: 500,
        min_market_tokens: 100,
        updated_at_block: 42,
        execution_fee: 10,
        callback_gas_limit: 1000000,
    };

    // Verify all values
    assert(deposit.key == 123, 'wrong key');
    assert(deposit.account == account, 'wrong account');
    assert(deposit.receiver == receiver, 'wrong receiver');
    assert(deposit.callback_contract == callback, 'wrong callback');
    assert(deposit.ui_fee_receiver == ui_fee, 'wrong ui fee receiver');
    assert(deposit.market == market, 'wrong market');
    assert(deposit.initial_long_token == long_token, 'wrong long token');
    assert(deposit.initial_short_token == short_token, 'wrong short token');
    assert(deposit.initial_long_token_amount == 1000, 'wrong long amount');
    assert(deposit.initial_short_token_amount == 500, 'wrong short amount');
    assert(deposit.min_market_tokens == 100, 'wrong min tokens');
    assert(deposit.updated_at_block == 42, 'wrong block');
    assert(deposit.execution_fee == 10, 'wrong execution fee');
    assert(deposit.callback_gas_limit == 1000000, 'wrong gas limit');
}
