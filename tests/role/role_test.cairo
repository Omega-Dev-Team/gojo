use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use debug::PrintTrait;

use satoru::role::role::{
    ROLE_ADMIN, TIMELOCK_ADMIN, TIMELOCK_MULTISIG, CONFIG_KEEPER, CONTROLLER,
    ROUTER_PLUGIN, MARKET_KEEPER, FEE_KEEPER, ORDER_KEEPER, PRICING_KEEPER,
    LIQUIDATION_KEEPER, ADL_KEEPER
};
use satoru::role::error::RoleError;
use satoru::role::role_store::{IRoleStore, RoleStore};
use satoru::role::role_module::{IRoleModule, RoleModule};

fn setup_role_store() -> RoleStore::ContractState {
    let admin: ContractAddress = 123.try_into().unwrap();
    let mut state = RoleStore::constructor(admin);
    set_caller_address(admin);
    state
}

fn setup_role_module() -> (RoleStore::ContractState, RoleModule::ContractState) {
    let admin: ContractAddress = 123.try_into().unwrap();
    let role_store_state = setup_role_store();
    let role_store_address: ContractAddress = 456.try_into().unwrap();
    let role_module_state = RoleModule::constructor(role_store_address);
    (role_store_state, role_module_state)
}

#[test]
#[available_gas(2000000)]
fn test_role_store_constructor() {
    let admin: ContractAddress = 123.try_into().unwrap();
    let state = setup_role_store();
    
    // Check if admin has ROLE_ADMIN
    assert(RoleStore::IRoleStore::has_role(@state, admin, ROLE_ADMIN), 'Admin should have admin role');
}

#[test]
#[available_gas(2000000)]
fn test_role_store_grant_role() {
    let mut state = setup_role_store();
    let user: ContractAddress = 456.try_into().unwrap();
    
    // Grant CONFIG_KEEPER role
    RoleStore::IRoleStore::grant_role(ref state, user, CONFIG_KEEPER);
    
    assert(
        RoleStore::IRoleStore::has_role(@state, user, CONFIG_KEEPER),
        'User should have config keeper role'
    );
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('UNAUTHORIZED_ACCESS', 'ENTRYPOINT_FAILED'))]
fn test_role_store_unauthorized_grant() {
    let mut state = setup_role_store();
    let unauthorized_user: ContractAddress = 456.try_into().unwrap();
    let target_user: ContractAddress = 789.try_into().unwrap();
    
    set_caller_address(unauthorized_user);
    RoleStore::IRoleStore::grant_role(ref state, target_user, CONFIG_KEEPER);
}

#[test]
#[available_gas(2000000)]
fn test_role_store_revoke_role() {
    let mut state = setup_role_store();
    let user: ContractAddress = 456.try_into().unwrap();
    
    // First grant the role
    RoleStore::IRoleStore::grant_role(ref state, user, CONFIG_KEEPER);
    assert(RoleStore::IRoleStore::has_role(@state, user, CONFIG_KEEPER), 'Role should be granted');
    
    // Then revoke it
    RoleStore::IRoleStore::revoke_role(ref state, user, CONFIG_KEEPER);
    assert(!RoleStore::IRoleStore::has_role(@state, user, CONFIG_KEEPER), 'Role should be revoked');
}

#[test]
#[available_gas(2000000)]
fn test_role_module_initialization() {
    let (_, role_module_state) = setup_role_module();
    let role_store_address: ContractAddress = 456.try_into().unwrap();
    
    RoleModule::IRoleModule::initialize(ref role_module_state, role_store_address);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('UNAUTHORIZED_ACCESS', 'ENTRYPOINT_FAILED'))]
fn test_role_module_unauthorized_access() {
    let (_, mut role_module_state) = setup_role_module();
    let unauthorized_user: ContractAddress = 789.try_into().unwrap();
    
    set_caller_address(unauthorized_user);
    RoleModule::IRoleModule::only_config_keeper(@role_module_state);
}

#[test]
#[available_gas(2000000)]
fn test_role_store_get_role_count() {
    let mut state = setup_role_store();
    let user1: ContractAddress = 456.try_into().unwrap();
    let user2: ContractAddress = 789.try_into().unwrap();
    
    RoleStore::IRoleStore::grant_role(ref state, user1, CONFIG_KEEPER);
    RoleStore::IRoleStore::grant_role(ref state, user2, MARKET_KEEPER);
    
    let count = RoleStore::IRoleStore::get_role_count(@state);
    assert(count == 3, 'Should have 3 roles'); // ROLE_ADMIN + 2 new roles
}

#[test]
#[available_gas(2000000)]
fn test_role_store_get_role_members() {
    let mut state = setup_role_store();
    let user1: ContractAddress = 456.try_into().unwrap();
    let user2: ContractAddress = 789.try_into().unwrap();
    
    RoleStore::IRoleStore::grant_role(ref state, user1, CONFIG_KEEPER);
    RoleStore::IRoleStore::grant_role(ref state, user2, CONFIG_KEEPER);
    
    let members = RoleStore::IRoleStore::get_role_members(@state, CONFIG_KEEPER, 0, 10);
    assert(members.len() == 2, 'Should have 2 members');
}

#[test]
#[available_gas(2000000)]
fn test_role_module_multiple_roles() {
    let (mut role_store_state, role_module_state) = setup_role_module();
    let user: ContractAddress = 456.try_into().unwrap();
    
    RoleStore::IRoleStore::grant_role(ref role_store_state, user, CONFIG_KEEPER);
    RoleStore::IRoleStore::grant_role(ref role_store_state, user, MARKET_KEEPER);
    
    set_caller_address(user);
    RoleModule::IRoleModule::only_config_keeper(@role_module_state);
    RoleModule::IRoleModule::only_market_keeper(@role_module_state);
}