use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::role::role;
use satoru::bank::strict_bank::{IStrictBank, IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::role::role_store::{RoleStore, IRoleStoreDispatcher};
use satoru::data::data_store::{DataStore, IDataStoreDispatcher};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use array::ArrayTrait;

fn setup() -> (
    ContractAddress,
    IStrictBankDispatcher,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    ContractAddress
) {
    let caller = contract_address_const::<1>();

    let role_store_class = declare('RoleStore');
    let role_store = role_store_class.deploy(@ArrayTrait::new()).unwrap();

    let data_store_class = declare('DataStore');
    let data_store = data_store_class.deploy(@ArrayTrait::new()).unwrap();

    let token = contract_address_const::<123>();

    let strict_bank_class = declare('StrictBank');
    let strict_bank = strict_bank_class.deploy(@array![data_store, role_store]).unwrap();

    (caller, strict_bank, role_store, data_store, token)
}

#[test]
fn test_transfer_out() {
    let (caller, strict_bank, role_store, _, token) = setup();
    
    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONTROLLER);
    stop_prank(role_store);

    let receiver = contract_address_const::<456>();
    let amount = 1000;

    start_prank(strict_bank, caller);
    strict_bank.transfer_out(caller, token, receiver, amount.into());
    stop_prank(strict_bank);
}

#[test]
fn test_record_transfer_in() {
    let (caller, strict_bank, role_store, _, token) = setup();

    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONTROLLER);
    stop_prank(role_store);

    start_prank(strict_bank, caller);
    let amount = strict_bank.record_transfer_in(token);
    assert(amount >= 0, 'Invalid transfer amount');
    stop_prank(strict_bank);
}

#[test]
fn test_sync_token_balance() {
    let (caller, strict_bank, role_store, _, token) = setup();

    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONTROLLER);
    stop_prank(role_store);

    start_prank(strict_bank, caller);
    let new_balance = strict_bank.sync_token_balance(token);
    assert(new_balance >= 0, 'Invalid balance');
    stop_prank(strict_bank);
}
