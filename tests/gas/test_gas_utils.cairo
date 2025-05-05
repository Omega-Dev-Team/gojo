use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    start_prank, stop_prank, forge_print::print, PrintTrait, spy_events, EventSpy, test_address
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::test_utils::tests_lib::{setup, teardown, deploy_bank};
use satoru::utils::span32::Array32Trait;
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::order::order::{Order, OrderType, DecreasePositionSwapType};
use satoru::gas::gas_utils::{
    get_min_handle_execution_error_gas, get_execution_gas, pay_execution_fee,
    pay_execution_fee_deposit, pay_execution_fee_order, pay_execution_fee_withdrawal,
    validate_execution_fee, adjust_gas_usage, adjust_gas_limit_for_estimate,
    estimate_execute_deposit_gas_limit, estimate_execute_withdrawal_gas_limit,
    estimate_execute_order_gas_limit, estimate_execute_increase_order_gas_limit,
    estimate_execute_decrease_order_gas_limit, estimate_execute_swap_order_gas_limit,
};

#[test]
fn test_get_min_handle_execution_error_gas() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();

    let min_handle_execution_error_gas = get_min_handle_execution_error_gas(data_store);
    assert(min_handle_execution_error_gas == 0x0, 'Invalid error gas');
}

#[test]
fn test_get_execution_gas() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let starting_gas = 1000;
    let execution_gas = get_execution_gas(data_store, starting_gas);
    let min_handle_execution_error_gas = get_min_handle_execution_error_gas(data_store);
    let expected_gas = starting_gas - min_handle_execution_error_gas;

    assert(execution_gas == expected_gas, 'Invalid execution gas');
}

#[test]
fn test_pay_execution_fee() {
    let (
        _,
        _,
        role_store_address,
        data_store_address,
        _,
        _,
        role_store,
        data_store,
        event_emitter,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
    ) =
        setup();
    let bank = IBankDispatcher {
        contract_address: deploy_bank(data_store_address, role_store_address)
    };
    let execution_fee = 1000;
    let starting_gas = 1000;
    let admin: ContractAddress = 123.try_into().unwrap();
    let user: ContractAddress = 456.try_into().unwrap();

    role_store.grant_role(test_address(), 'CONTROLLER');
    pay_execution_fee(data_store, event_emitter, bank, execution_fee, starting_gas, admin, user);
}

#[test]
fn test_pay_execution_fee_deposit() {
    let (
        _,
        _,
        _,
        _,
        _,
        _,
        role_store,
        data_store,
        event_emitter,
        _,
        _,
        deposit_vault,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
    ) =
        setup();
    let execution_fee = 1000;
    let starting_gas = 1000;
    let keeper: ContractAddress = 123.try_into().unwrap();
    let refund_receiver: ContractAddress = 456.try_into().unwrap();

    role_store.grant_role(test_address(), 'CONTROLLER');
    pay_execution_fee_deposit(
        data_store,
        event_emitter,
        deposit_vault,
        execution_fee,
        starting_gas,
        keeper,
        refund_receiver
    );
}

#[test]
fn test_pay_execution_fee_order() {
    let (
        _,
        _,
        _,
        _,
        _,
        _,
        role_store,
        data_store,
        event_emitter,
        _,
        _,
        _,
        _,
        _,
        order_vault,
        _,
        _,
        _,
        _,
        _,
    ) =
        setup();
    let execution_fee = 1000;
    let starting_gas = 1000;
    let keeper: ContractAddress = 123.try_into().unwrap();
    let refund_receiver: ContractAddress = 456.try_into().unwrap();

    role_store.grant_role(test_address(), 'CONTROLLER');
    pay_execution_fee_order(
        data_store, event_emitter, order_vault, execution_fee, starting_gas, keeper, refund_receiver
    );
}

#[test]
fn test_pay_execution_fee_withdrawal() {
    let (
        _,
        _,
        _,
        _,
        _,
        _,
        role_store,
        data_store,
        event_emitter,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        withdrawal_vault,
        _,
    ) =
        setup();
    let execution_fee = 1000;
    let starting_gas = 1000;
    let keeper: ContractAddress = 123.try_into().unwrap();
    let refund_receiver: ContractAddress = 456.try_into().unwrap();

    role_store.grant_role(test_address(), 'CONTROLLER');
    pay_execution_fee_withdrawal(
        data_store,
        event_emitter,
        withdrawal_vault,
        execution_fee,
        starting_gas,
        keeper,
        refund_receiver
    );
}

#[test]
fn test_validate_execution_fee() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let estimated_gas_limit = 1000;
    let execution_fee = 1000;

    validate_execution_fee(data_store, estimated_gas_limit, execution_fee);
}

#[test]
fn test_adjust_gas_usage() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let gas_used = 1000;

    adjust_gas_usage(data_store, gas_used);
}

#[test]
fn test_adjust_gas_limit_for_estimate() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let estimated_gas_limit = 1000;

    adjust_gas_limit_for_estimate(data_store, estimated_gas_limit);
}

#[test]
fn test_estimate_execute_deposit_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let deposit = Deposit {
        key: 0,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        initial_long_token: contract_address_const::<0>(),
        initial_short_token: contract_address_const::<0>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        initial_long_token_amount: 0,
        initial_short_token_amount: 0,
        min_market_tokens: 0,
        updated_at_block: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    let estimate = estimate_execute_deposit_gas_limit(data_store, deposit);
    assert(estimate == 0, 'Invalid deposit gas limit');
}

#[test]
fn test_estimate_execute_withdrawal_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let withdrawal = Withdrawal {
        key: 0,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: 0,
        min_long_token_amount: 0,
        min_short_token_amount: 0,
        updated_at_block: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    let estimate = estimate_execute_withdrawal_gas_limit(data_store, withdrawal);
    assert(estimate == 0, 'Invalid withdrawal gas limit');
}

#[test]
fn test_estimate_execute_order_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let order = Order {
        key: 0,
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
        order_type: OrderType::MarketSwap,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        initial_collateral_token: contract_address_const::<0>(),
        swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        updated_at_block: 0,
        is_long: true,
        is_frozen: true,
    };

    let estimate = estimate_execute_order_gas_limit(data_store, @order);
    assert(estimate == 0, 'Invalid order gas limit');
}

#[test]
fn test_estimate_execute_increase_order_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let order = Order {
        key: 0,
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
        order_type: OrderType::MarketSwap,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        initial_collateral_token: contract_address_const::<0>(),
        swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        updated_at_block: 0,
        is_long: true,
        is_frozen: true,
    };

    let estimate = estimate_execute_increase_order_gas_limit(data_store, order);
    assert(estimate == 0, 'Invalid inc order gas limit');
}

#[test]
fn test_estimate_execute_decrease_order_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let order = Order {
        key: 0,
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
        order_type: OrderType::MarketSwap,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        initial_collateral_token: contract_address_const::<0>(),
        swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        updated_at_block: 0,
        is_long: true,
        is_frozen: true,
    };

    let estimate = estimate_execute_decrease_order_gas_limit(data_store, order);
    assert(estimate == 0, 'Invalid dec order gas limit');
}

#[test]
fn test_estimate_execute_swap_order_gas_limit() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();
    let order = Order {
        key: 0,
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
        order_type: OrderType::MarketSwap,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        initial_collateral_token: contract_address_const::<0>(),
        swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        updated_at_block: 0,
        is_long: true,
        is_frozen: true,
    };

    let estimate = estimate_execute_swap_order_gas_limit(data_store, order);
    assert(estimate == 0, 'Invalid swap order gas limit');
}
