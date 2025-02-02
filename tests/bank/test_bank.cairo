use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::role::role;
use satoru::data::keys;
use satoru::role::role_store::{RoleStore, IRoleStoreDispatcher};
use satoru::data::data_store::{DataStore, IDataStoreDispatcher};
use satoru::event::event_emitter::{EventEmitter, IEventEmitterDispatcher};

use satoru::config::{Config, IConfigDispatcher, IConfigDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};


use array::ArrayTrait;

fn setup() -> (
    ContractAddress,
    IConfigDispatcher,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher
) {
    let caller = contract_address_const::<1>();

    let role_store_class = declare('RoleStore');
    let role_store = role_store_class.deploy(@ArrayTrait::new()).unwrap();

    let data_store_class = declare('DataStore');
    let data_store = data_store_class.deploy(@ArrayTrait::new()).unwrap();

    let event_emitter_class = declare('EventEmitter');
    let event_emitter = event_emitter_class.deploy(@ArrayTrait::new()).unwrap();

    let config_class = declare('Config');
    let config = config_class.deploy(@array![role_store, data_store, event_emitter]).unwrap();

    (caller, config, role_store, data_store, event_emitter)
}

#[test]
fn test_set_bool() {
    let (caller, config, role_store, data_store, _) = setup();

    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store);

    let mut data = ArrayTrait::new();
    data.append(123);

    start_prank(config, caller);
    config.set_bool(keys::MAX_SWAP_PATH_LENGTH, data, true);
    let value = data_store.get_bool(config.get_full_key(keys::MAX_SWAP_PATH_LENGTH, data));
    assert(value == true, 'Wrong bool value');
    stop_prank(config);
}

#[test]
fn test_set_address() {
    let (caller, config, role_store, data_store, _) = setup();
    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store);

    let mut data = ArrayTrait::new();
    let test_address = contract_address_const::<123>();

    start_prank(config, caller);
    config.set_address(keys::FEE_RECEIVER, data, test_address);
    let value = data_store.get_address(config.get_full_key(keys::FEE_RECEIVER, data));
    assert(value == test_address, 'Wrong address value');
    stop_prank(config);
}

#[test]
fn test_set_felt252() {
    let (caller, config, role_store, data_store, _) = setup();

    start_prank(role_store, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store);

    let mut data = ArrayTrait::new();
    let test_felt = 12345;

    start_prank(config, caller);
    config.set_felt252(keys::MIN_POSITION_SIZE_USD, data, test_felt);
    let value = data_store.get_felt252(config.get_full_key(keys::MIN_POSITION_SIZE_USD, data));
    assert(value == test_felt, 'Wrong felt252 value');
    stop_prank(config);
}