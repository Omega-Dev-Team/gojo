use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use satoru::role::role;
use satoru::data::keys;
use satoru::role::role_store::{
    IRoleStoreDispatcher, IRoleStoreDispatcherTrait, RoleStore::InternalFunctionsTrait, 
    RoleStore, IRoleStore
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::fee::fee_handler::{IFeeHandlerDispatcher, IFeeHandlerDispatcherTrait};

use array::ArrayTrait;

fn deploy_contract(name: felt252, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name);
    let contract_address = contract.deploy(@calldata)
        .expect('failed deploying contract');
    contract_address
}

fn setup() -> (
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress
) {
    let admin: ContractAddress = contract_address_const::<'ADMIN'>();

    let role_store_address = deploy_contract('RoleStore', array![admin.into()]);
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_contract('DataStore', array![role_store_address.into()]);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_contract('EventEmitter', array![]);
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let fee_handler_class = declare('FeeHandler');
    let fee_handler_address = fee_handler_class.deploy(@array![role_store_address.into(), data_store_address.into(), event_emitter_address.into()]).unwrap();

    (admin, fee_handler_address, role_store_address, data_store_address, event_emitter_address)
}

#[test]
fn test_claim_fees_valid() {
    let (caller, fee_handler_address, role_store_address, data_store_address, _) = setup();

    let market: ContractAddress = contract_address_const::<'MARKET'>();
    let token: ContractAddress = contract_address_const::<'TOKEN'>();
    let receiver: ContractAddress = contract_address_const::<'RECEIVER'>();

    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    start_prank(role_store_address, caller);
    role_store.grant_role(caller, role::CONTROLLER);
    stop_prank(role_store_address);

    start_prank(data_store_address, caller);
    // Set up initial state
    data_store.set_u256(keys::claimable_fee_amount_key(market, token), 100.into());
    data_store.set_address(keys::fee_receiver(), receiver);
    let receiver = data_store.get_address(keys::fee_receiver());
   // println!()
    stop_prank(data_store_address);

    start_prank(fee_handler_address, caller);
    // Call claim_fees
    let fee_handler = IFeeHandlerDispatcher { contract_address: fee_handler_address };
    fee_handler.claim_fees(array![market], array![token]);
    stop_prank(fee_handler_address);

    // // Assert expected behavior
    // start_prank(data_store_address, caller);
    // let fee_amount = data_store.get_u256(keys::claimable_fee_amount_key(market, token));
    // stop_prank(data_store_address);
    // assert(fee_amount == 0, 'fee amount should be zero');
}

// #[test]
// #[should_panic(expected: ('invalid_claim_fees_input',))]
// fn test_claim_fees_invalid_input() {
//     let (caller, fee_handler_address, _, data_store_address, _) = setup();

//     start_prank(fee_handler_address, caller);
//     let market = ContractAddress::try_from(2).unwrap();
//     let token = ContractAddress::try_from(3).unwrap();

//     // Call claim_fees with mismatched arrays
//     IFeeHandlerDispatcher { contract_address: fee_handler }.claim_fees(array![market], array![]);
//     stop_prank(fee_handler_address);
// }

// #[test]
// fn test_claim_fees_no_fees() {
//     let (caller, fee_handler, role_store, data_store, event) = setup();

//     start_prank(caller);
//     let market = ContractAddress::try_from(2).unwrap();
//     let token = ContractAddress::try_from(3).unwrap();
//     let receiver = ContractAddress::try_from(4).unwrap();

//     // Set up initial state with no fees
//     data_store.set_u256(keys::claimable_fee_amount_key(market, token), 0.into());
//     data_store.set_address(keys::fee_receiver(), receiver);

//     // Call claim_fees
//     IFeeHandlerDispatcher { contract_address: fee_handler }.claim_fees(array![market], array![token]);

//     // Assert expected behavior
//     let fee_amount = data_store.get_u256(keys::claimable_fee_amount_key(market, token));
//     assert(fee_amount == 0, 'Fee amount should remain zero');
//     stop_prank();
// }

// #[test]
// fn test_claim_fees_multiple_markets() {
//     let (caller, fee_handler, role_store, data_store, event) = setup();

//     start_prank(caller);
//     let market1 = ContractAddress::try_from(2).unwrap();
//     let token1 = ContractAddress::try_from(3).unwrap();
//     let market2 = ContractAddress::try_from(5).unwrap();
//     let token2 = ContractAddress::try_from(6).unwrap();
//     let receiver = ContractAddress::try_from(4).unwrap();

//     // Set up initial state
//     data_store.set_u256(keys::claimable_fee_amount_key(market1, token1), 100.into());
//     data_store.set_u256(keys::claimable_fee_amount_key(market2, token2), 200.into());
//     data_store.set_address(keys::fee_receiver(), receiver);

//     // Call claim_fees
//     IFeeHandlerDispatcher { contract_address: fee_handler }.claim_fees(array![market1, market2], array![token1, token2]);

//     // Assert expected behavior
//     let fee_amount1 = data_store.get_u256(keys::claimable_fee_amount_key(market1, token1));
//     let fee_amount2 = data_store.get_u256(keys::claimable_fee_amount_key(market2, token2));
//     assert(fee_amount1 == 0, 'Fee amount for market1 should be zero after claiming');
//     assert(fee_amount2 == 0, 'Fee amount for market2 should be zero after claiming');
//     stop_prank();
// }