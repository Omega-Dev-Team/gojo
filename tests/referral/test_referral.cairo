use satoru::referral::{referral_utils, referral_tier};
use core::traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::data::keys;


fn deploy_mock_contracts() -> (IDataStoreDispatcher, IEventEmitterDispatcher, IReferralStorageDispatcher) {
    // Deploy mock contracts
    let role_store_class = declare('RoleStore');
    let role_store = role_store_class.deploy(@ArrayTrait::new()).unwrap();
    let data_store = declare('DataStore');
    let data_store_address = data_store.deploy(@array![role_store.into()]).unwrap();

    let event_emitter = declare('EventEmitter');
    let mut calldata = ArrayTrait::new();
    let event_emitter_address = event_emitter.deploy(@calldata).unwrap();

    let referral_storage_class = declare('ReferralStorage');
    let referral_storage_address = referral_storage_class.deploy(@array![event_emitter_address.into()]).unwrap();

    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let referral_storage = IReferralStorageDispatcher { contract_address: referral_storage_address };

    (data_store, event_emitter, referral_storage)
}

#[test]
fn test_set_trader_referral_code() {
    let (_, _, referral_storage) = deploy_mock_contracts();
    let account = contract_address_const::<1>();
    let code: felt252 = 'Hello';
    start_prank(referral_storage.contract_address, account);
    referral_utils::set_trader_referral_code(
        referral_storage,
        account,
        code
    );
    let (account_code, _) = referral_storage.get_trader_referral_info(
        account
    );
    stop_prank(referral_storage.contract_address);
    assert(account_code == code, 'invalid code');
}

#[test]
fn test_increment_affiliate_reward() {
    let (data_store, event_emitter, _) = deploy_mock_contracts();
    let account = contract_address_const::<1>();
    let token = contract_address_const::<2>();
    let market = contract_address_const::<3>();
    let delta: u256 = 1000;
    let key = keys::affiliate_reward_for_account_key(market, token, account);
    start_prank(data_store.contract_address, account);
    referral_utils::increment_affiliate_reward(
        data_store,
        event_emitter,
        market,
        token,
        account,
        delta
    );
    stop_prank(data_store.contract_address);
    let data_total = data_store.get_u256(key);
    assert(delta == data_total, 'invalid affiliate reward');
}

#[test]
fn test_get_referral_info() {
    let (_, _, referral_storage) = deploy_mock_contracts();
    let account = contract_address_const::<1>();
    let (code, affiliate, rebate, discount) = referral_utils::get_referral_info(
        referral_storage,
        account
    );
    assert(code == 0, 'Invalid code');
    assert(affiliate == contract_address_const::<0>(), 'Invalid affiliate');
    assert(rebate == 0, 'Invalid rebate');
    assert(discount == 0, 'Invalid discount');
}

#[test]
fn test_claim_affiliate_no_reward() {
    let (data_store, event_emitter, _) = deploy_mock_contracts();
    let account = contract_address_const::<1>();
    let receiver = contract_address_const::<2>();
    let market = contract_address_const::<3>();
    let token = contract_address_const::<4>();
    start_prank(data_store.contract_address, account);
    let reward = referral_utils::claim_affiliate_reward(
        data_store,
        event_emitter,
        market,
        token,
        account,
        receiver
    );
    stop_prank(data_store.contract_address);
    assert(reward == 0, 'Invalid reward');
}

#[test]
fn test_claim_affiliate_reward() {
    let (data_store, event_emitter, _) = deploy_mock_contracts();
    let account = contract_address_const::<1>();
    let receiver = contract_address_const::<2>();
    let market = contract_address_const::<3>();
    let token = contract_address_const::<4>();
    let mock_reward = 1000;
    let key: felt252 = keys::affiliate_reward_for_account_key(market, token, account);
    data_store.set_u256(key, mock_reward);
    start_prank(data_store.contract_address, account);
    let reward = referral_utils::claim_affiliate_reward(
        data_store,
        event_emitter,
        market,
        token,
        account,
        receiver
    );
    stop_prank(data_store.contract_address);
    assert(reward == mock_reward, 'Invalid reward');
}