use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use debug::PrintTrait;

use satoru::role::role::{
    ROLE_ADMIN, TIMELOCK_ADMIN, TIMELOCK_MULTISIG, CONFIG_KEEPER, CONTROLLER, ROUTER_PLUGIN,
    MARKET_KEEPER, FEE_KEEPER, ORDER_KEEPER, PRICING_KEEPER, LIQUIDATION_KEEPER, ADL_KEEPER
};
use satoru::role::error::RoleError;
use satoru::role::role_store::{
    IRoleStore, RoleStore, IRoleStoreDispatcher, IRoleStoreDispatcherTrait
};
use satoru::role::role_module::{
    IRoleModule, RoleModule, IRoleModuleDispatcher, IRoleModuleDispatcherTrait
};

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

fn setup_role_store() -> IRoleStoreDispatcher {
    let admin: ContractAddress = 123.try_into().unwrap();

    let role_store_class = declare('RoleStore');
    let role_store = role_store_class.deploy(@array![admin.into()]).unwrap();
    let role_store_dispatcher = IRoleStoreDispatcher { contract_address: role_store };

    role_store_dispatcher
}

fn setup_role_module() -> (IRoleStoreDispatcher, IRoleModuleDispatcher) {
    let admin: ContractAddress = 123.try_into().unwrap();
    let role_store_dispatcher = setup_role_store();

    let role_module_class = declare('RoleModule');
    let role_module = role_module_class
        .deploy(@array![role_store_dispatcher.contract_address.into()])
        .unwrap();
    let role_module_dispatcher = IRoleModuleDispatcher { contract_address: role_module };

    (role_store_dispatcher, role_module_dispatcher)
}

#[test]
#[available_gas(2000000)]
fn test_role_store_constructor() {
    let admin: ContractAddress = 123.try_into().unwrap();
    let role_store = setup_role_store();

    // Check if admin has ROLE_ADMIN
    assert(role_store.has_role(admin, ROLE_ADMIN), 'Admin should have admin role');
}

#[test]
#[available_gas(2000000)]
fn test_role_store_grant_role() {
    let role_store = setup_role_store();
    let admin: ContractAddress = 123.try_into().unwrap();
    let user: ContractAddress = 456.try_into().unwrap();

    start_prank(role_store.contract_address, admin);
    // Grant CONFIG_KEEPER role
    role_store.grant_role(user, CONFIG_KEEPER);

    assert(role_store.has_role(user, CONFIG_KEEPER), 'User != config keeper role');
    stop_prank(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('unauthorized_access',))]
fn test_role_store_unauthorized_grant() {
    let role_store = setup_role_store();
    let unauthorized_user: ContractAddress = 456.try_into().unwrap();
    let target_user: ContractAddress = 789.try_into().unwrap();

    start_prank(role_store.contract_address, unauthorized_user);
    role_store.grant_role(target_user, CONFIG_KEEPER);
    stop_prank(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
fn test_role_store_revoke_role() {
    let role_store = setup_role_store();
    let admin: ContractAddress = 123.try_into().unwrap();
    let user: ContractAddress = 456.try_into().unwrap();

    start_prank(role_store.contract_address, admin);

    // First grant the role
    role_store.grant_role(user, CONFIG_KEEPER);
    assert(role_store.has_role(user, CONFIG_KEEPER), 'Role should be granted');

    // Then revoke it
    role_store.revoke_role(user, CONFIG_KEEPER);
    assert(!role_store.has_role(user, CONFIG_KEEPER), 'Role should be revoked');
    stop_prank(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
fn test_role_module_initialization() {
    let (role_store, role_module) = setup_role_module();

    role_module.initialize(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('unauthorized_access',))]
fn test_role_module_unauthorized_access() {
    let (_, role_module) = setup_role_module();
    let unauthorized_user: ContractAddress = 789.try_into().unwrap();

    start_prank(role_module.contract_address, unauthorized_user);
    role_module.only_config_keeper();
    stop_prank(role_module.contract_address);
}

#[test]
#[available_gas(2000000)]
fn test_role_store_get_role_count() {
    let role_store = setup_role_store();
    let admin: ContractAddress = 123.try_into().unwrap();
    let user1: ContractAddress = 456.try_into().unwrap();
    let user2: ContractAddress = 789.try_into().unwrap();

    start_prank(role_store.contract_address, admin);
    role_store.grant_role(user1, CONFIG_KEEPER);
    role_store.grant_role(user2, MARKET_KEEPER);

    let count = role_store.get_role_count();
    assert(count == 3, 'Should have 3 roles'); // ROLE_ADMIN + 2 new roles
    stop_prank(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
fn test_role_store_get_role_members() {
    let role_store = setup_role_store();
    let admin: ContractAddress = 123.try_into().unwrap();
    let user1: ContractAddress = 456.try_into().unwrap();
    let user2: ContractAddress = 789.try_into().unwrap();

    start_prank(role_store.contract_address, admin);
    role_store.grant_role(user1, CONFIG_KEEPER);
    role_store.grant_role(user2, CONFIG_KEEPER);

    let members = role_store.get_role_members(CONFIG_KEEPER, 0, 10);
    assert(members.len() == 2, 'Should have 2 members');
    stop_prank(role_store.contract_address);
}

#[test]
#[available_gas(2000000)]
fn test_role_module_multiple_roles() {
    let (role_store, role_module) = setup_role_module();
    let admin: ContractAddress = 123.try_into().unwrap();
    let user: ContractAddress = 456.try_into().unwrap();

    start_prank(role_store.contract_address, admin);

    role_store.grant_role(user, CONFIG_KEEPER);
    role_store.grant_role(user, MARKET_KEEPER);

    stop_prank(role_store.contract_address);

    start_prank(role_module.contract_address, user);
    role_module.only_config_keeper();
    role_module.only_market_keeper();
    stop_prank(role_module.contract_address);
}

