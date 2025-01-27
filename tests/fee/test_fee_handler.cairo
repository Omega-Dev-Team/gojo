use satoru::fee::fee_handler::{FeeHandler, IFeeHandlerDispatcher, IFeeHandlerDispatcherTrait};
use satoru::test_utils::tests_lib::{setup};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use starknet::{contract_address_const, ContractAddress};

use satoru::test_utils::tests_lib::{};

use array::ArrayTrait;

#[test]
fn claim_fees() {
   let (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,fee_handler,) = setup();

    fee_handler.claim_fees(array![], array![]);
}
