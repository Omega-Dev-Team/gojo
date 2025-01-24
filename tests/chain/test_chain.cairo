use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use satoru::chain::chain::{Chain, IChainDispatcher, IChainDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use array::ArrayTrait;

fn setup() -> (
    ContractAddress,
    ContractAddress
) {
    let caller = contract_address_const::<1>();

    let chain_class = declare('Chain');
    let chain = chain_class.deploy(@array![]).unwrap();

    (caller, chain)
}

#[test]
fn test_get_block_number() {
    let (caller, chain) = setup();

    let dispatcher = IChainDispatcher { contract_address: chain };

    let block_number = dispatcher.get_block_number();

    assert(block_number > 0, 'BLOCK NUMBER WRONG');
}

#[test]
fn test_get_block_timestamp() {
    let (caller, chain) = setup();

    let dispatcher = IChainDispatcher { contract_address: chain };

    let block_timestamp = dispatcher.get_block_timestamp();

    assert(block_timestamp == 0, 'TIMESTAMP WRONG');
}