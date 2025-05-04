use starknet::{ContractAddress, contract_address_const};
use snforge_std::{start_prank, stop_prank, forge_print::print, PrintTrait, spy_events, EventSpy, test_address};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::test_utils::tests_lib::{setup, teardown, deploy_bank};
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
    assert(min_handle_execution_error_gas == 0, 'Invalid error gas');
}

#[test]
fn test_get_execution_gas() {
    let (_, _, _, _, _, _, _, data_store, _, _, _, _, _, _, _, _, _, _, _, _,) = setup();

    let starting_gas = 1000;
    let execution_gas = get_execution_gas(data_store, starting_gas);
    let min_handle_execution_error_gas = get_min_handle_execution_error_gas(data_store);
    print(array![min_handle_execution_error_gas.try_into().unwrap()]);
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
    // let event_spy = EventSpy::new();
    // let event_emitter = event_spy.get_event_emitter();
    role_store.grant_role(test_address(), 'CONTROLLER');
    pay_execution_fee(
        data_store, event_emitter, bank, execution_fee, starting_gas, admin, user
    );
}
