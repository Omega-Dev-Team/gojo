use integer::BoundedInt;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::liquidation::liquidation_utils::create_liquidation_order;
use satoru::order::order::{OrderType, Order};
use satoru::position::position::Position;
use satoru::position::position_utils;
use satoru::role::role;
use satoru::role::role_store::{
    IRoleStoreDispatcher, IRoleStoreDispatcherTrait, RoleStore::InternalFunctionsTrait, 
    RoleStore, IRoleStore
};
use snforge_std::{declare, start_prank, stop_prank};
use snforge_std::cheatcodes::contract_class::{ContractClass, ContractClassTrait};
use starknet::{ContractAddress, contract_address_const};
use traits::Default;


// *********************************************************************************************
// *                              SETUP HELPERS                                                *
// *********************************************************************************************

fn deploy_contract(name: felt252, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name);
    let contract_address = contract.deploy(@calldata)
        .expect('failed deploying contract');
    contract_address
}

fn setup_role_store() -> RoleStore::ContractState {
    let admin: ContractAddress = contract_address_const::<'ADMIN'>();
    let mut test_state = RoleStore::contract_state_for_testing();
    // The constructor assigns ROLE_ADMIN to the admin.
    RoleStore::constructor(ref test_state, admin);
    test_state
}

/// Deploys the three main contracts and returns the dispatchers
fn _setup() -> (IDataStoreDispatcher, IRoleStoreDispatcher, IEventEmitterDispatcher) {
    let admin: ContractAddress = contract_address_const::<'ADMIN'>();

    let role_store_address = deploy_contract('RoleStore', array![admin.into()]);
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_contract('DataStore', array![role_store_address.into()]);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_contract('EventEmitter', array![]);
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    (data_store, role_store, event_emitter)
}

/// Convenience helper for tests that need additional parameters.
/// Returns the deployed contracts along with common account addresses.
fn _setup_liquidation() -> (IDataStoreDispatcher, IRoleStoreDispatcher, IEventEmitterDispatcher, ContractAddress, ContractAddress, ContractAddress) {
    let (data_store, role_store, event_emitter) = _setup();
    let admin: ContractAddress = contract_address_const::<'ADMIN'>();
    let market: ContractAddress = contract_address_const::<'MARKET'>();
    let collateral_token: ContractAddress = contract_address_const::<'TOKEN'>();
    (data_store, role_store, event_emitter, admin, market, collateral_token)
}

//////////////////////////////
///       TESTS
//////////////////////////////

#[test]
fn setup_role() {
    let admin: ContractAddress = contract_address_const::<'ADMIN'>();
    let state = setup_role_store();
    assert(
        state.has_role(admin, role::ROLE_ADMIN),
        'Admin should have admin role'
    );
}

#[test]
#[should_panic]
fn test_role_store_unauthorized_grant() {
    // This should panic because an unauthorized call to grant_role is attempted.
    let mut state = setup_role_store();
    // Use a dummy unauthorized user.
    let unauthorized_user: ContractAddress = 123.try_into().unwrap();
    state.grant_role(unauthorized_user, role::CONFIG_KEEPER);
}

#[test]
fn test_create_liquidation_order() {
    let (data_store, role_store, event_emitter, admin, market, collateral_token) = _setup_liquidation();

    let local_role_state = setup_role_store();
    assert(
        local_role_state.has_role(admin, role::ROLE_ADMIN),
        'Admin should have admin role'
    );

    let dummy_position = Position {
        key: admin.into(),
        account: admin,
        market: market,
        collateral_token: collateral_token,
        size_in_usd: 1000,
        size_in_tokens: 0,
        collateral_amount: 0,
        borrowing_factor: 0,
        funding_fee_amount_per_size: 0,
        long_token_claimable_funding_amount_per_size: 0,
        short_token_claimable_funding_amount_per_size: 0,
        increased_at_block: 0,
        decreased_at_block: 0,
        is_long: true,
    };

    // grant CONTROLLER role because needed for write access in DataStore
    start_prank(role_store.contract_address, admin);
    role_store.grant_role(admin, role::CONTROLLER);
    stop_prank(role_store.contract_address);

    
    
    start_prank(data_store.contract_address, admin);
    let position_key = position_utils::get_position_key(admin, market, collateral_token, true);
    data_store.set_position(position_key, dummy_position);
    let nonce_key = create_liquidation_order(
        data_store,
        event_emitter,
        admin,
        market,
        collateral_token,
        true 
    );
    stop_prank(data_store.contract_address);

    let created_order = data_store.get_order(nonce_key);
    assert(created_order.order_type == OrderType::Liquidation, 'OrderType is not Liquidation');
    assert(created_order.size_delta_usd == dummy_position.size_in_usd, 'size_delta_usd mismatch');
}

#[test]
fn test_create_liquidation_order_short_position() {
    // This test verifies that when creating a liquidation order for a short position,
    // the acceptable_price field is set to the maximum value.
    let (data_store, role_store, event_emitter, admin, market, collateral_token) = _setup_liquidation();

    let dummy_position = Position {
        key: admin.into(),
        account: admin,
        market: market,
        collateral_token: collateral_token,
        size_in_usd: 2000,
        size_in_tokens: 0,
        collateral_amount: 0,
        borrowing_factor: 0,
        funding_fee_amount_per_size: 0,
        long_token_claimable_funding_amount_per_size: 0,
        short_token_claimable_funding_amount_per_size: 0,
        increased_at_block: 0,
        decreased_at_block: 0,
        is_long: false,
    };

    start_prank(role_store.contract_address, admin);
    role_store.grant_role(admin, role::CONTROLLER);
    stop_prank(role_store.contract_address);

    
    start_prank(data_store.contract_address, admin);
    let position_key = position_utils::get_position_key(admin, market, collateral_token, false);
    data_store.set_position(position_key, dummy_position);
    stop_prank(data_store.contract_address);

    start_prank(data_store.contract_address, admin);
    let nonce_key = create_liquidation_order(
        data_store,
        event_emitter,
        admin,
        market,
        collateral_token,
        false
    );
    stop_prank(data_store.contract_address);

    let created_order = data_store.get_order(nonce_key);
    let expected_acceptable_price = BoundedInt::<u256>::max();
    assert(
        created_order.order_type == OrderType::Liquidation,
        'OrderType is not Liquidation'
    );
    assert(
        created_order.acceptable_price == expected_acceptable_price,
        'unexpected "acceptable_price"'
    );
}