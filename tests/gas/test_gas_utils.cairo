use starknet::{ContractAddress, contract_address_const};
use snforge_std::{spy_events, forge_print, PrintTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
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
    assert(
        min_handle_execution_error_gas == 0, 'Invalid error gas'
    );
}
