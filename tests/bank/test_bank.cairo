use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::role::role;
use satoru::data::keys;
use satoru::role::role_store::{RoleStore, IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{DataStore, IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{EventEmitter, IEventEmitterDispatcher};

use satoru::config::config::{Config, IConfigDispatcher, IConfigDispatcherTrait};

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
    let role_store_dispatcher = IRoleStoreDispatcher { contract_address: role_store };

    let data_store_class = declare('DataStore');
    let data_store = data_store_class.deploy(@ArrayTrait::new()).unwrap();
    let data_store_dispatcher = IDataStoreDispatcher { contract_address: data_store };

    let event_emitter_class = declare('EventEmitter');
    let event_emitter = event_emitter_class.deploy(@ArrayTrait::new()).unwrap();
    let event_emitter_dispatcher = IEventEmitterDispatcher { contract_address: event_emitter };

    let config_class = declare('Config');
    let config = config_class
        .deploy(@array![role_store.into(), data_store.into(), event_emitter.into()])
        .unwrap();
    let config_dispatcher = IConfigDispatcher { contract_address: config };

    (
        caller,
        config_dispatcher,
        role_store_dispatcher,
        data_store_dispatcher,
        event_emitter_dispatcher
    )
}

#[test]
fn test_set_bool() {
    let (caller, config, role_store, data_store, _) = setup();

    start_prank(role_store.contract_address, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store.contract_address);

    let mut data = ArrayTrait::new();
    data.append(123);
    let mut data_two = ArrayTrait::new();
    data_two.append(123);

    start_prank(config.contract_address, caller);
    config.set_bool(keys::max_swap_path_length(), data, true);
    let value = data_store.get_bool(config.get_full_key(keys::max_swap_path_length(), data_two));
    assert(value == true, 'Wrong bool value');
    stop_prank(config.contract_address);
}

#[test]
fn test_set_address() {
    let (caller, config, role_store, data_store, _) = setup();
    start_prank(role_store.contract_address, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store.contract_address);

    let mut data = ArrayTrait::new();
    let test_address = contract_address_const::<123>();

    let mut data_two = ArrayTrait::new();

    start_prank(config.contract_address, caller);
    config.set_address(keys::fee_receiver(), data, test_address);
    let value = data_store.get_address(config.get_full_key(keys::fee_receiver(), data_two));
    assert(value == test_address, 'Wrong address value');
    stop_prank(config.contract_address);
}

#[test]
fn test_set_felt252() {
    let (caller, config, role_store, data_store, _) = setup();

    start_prank(role_store.contract_address, caller);
    role_store.grant_role(caller, role::CONFIG_KEEPER);
    stop_prank(role_store.contract_address);

    let mut data = ArrayTrait::new();
    let test_felt = 12345;

    let mut data_two = ArrayTrait::new();

    start_prank(config.contract_address, caller);
    config.set_felt252(keys::min_position_size_usd(), data, test_felt);
    let value = data_store
        .get_felt252(config.get_full_key(keys::min_position_size_usd(), data_two));
    assert(value == test_felt, 'Wrong felt252 value');
    stop_prank(config.contract_address);
}

