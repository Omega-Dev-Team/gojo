use starknet::{ContractAddress, contract_address_const};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, compute_key, get_next_key};
use satoru::tests_lib::{setup, teardown};

#[test]
fn test_nonce_utils_functionality() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    // Correctly capture all elements from setup()
    let data_store = setup();

    // *********************************************************************************************
    // *                             INITIAL STATE                                                 *
    // *********************************************************************************************
    // Verify initial nonce is 0
    let initial_nonce = get_current_nonce(data_store);
    assert(initial_nonce == 0, 'Initial nonce should be 0');

    // *********************************************************************************************
    // *                           TEST INCREMENT NONCE                                            *
    // *********************************************************************************************
    // Test incrementing nonce
    let new_nonce = increment_nonce(data_store);
    assert(new_nonce == 1, 'Nonce should increment to 1');

    // Verify nonce is correctly stored in data_store
    let current_nonce = get_current_nonce(data_store);
    assert(current_nonce == 1, 'Current nonce should be 1');

    // Increment nonce again
    let new_nonce = increment_nonce(data_store);
    assert(new_nonce == 2, 'Nonce should increment to 2');

    // *********************************************************************************************
    // *                           TEST COMPUTE KEY                                                *
    // *********************************************************************************************
    // Create a static contract address for testing
    let test_address: ContractAddress = contract_address_const::<0x123>();
    
    // Test compute_key with known values
    let key1 = compute_key(test_address, 1_u256);
    // Since the hash output will depend on the inputs, we can verify it's not zero
    assert(key1 != 0, 'Key should not be zero');

    // Test compute_key with a different nonce
    let key2 = compute_key(test_address, 2_u256);
    assert(key2 != 0, 'Key should not be zero');
    assert(key1 != key2, 'Different nonces should produce different keys');

    // Test compute_key with the same values as original test
    let specific_address: ContractAddress = contract_address_const::<42069>();
    let key3 = compute_key(specific_address, 2_u256);
    assert(
        key3 == 0x24bd38ceb23566640607e8fd6d1ef05cf308413863f984763744a3cfd428b1b, 
        'Key should match expected value'
    );

    // *********************************************************************************************
    // *                           TEST GET NEXT KEY                                               *
    // *********************************************************************************************
    // Since get_next_key increments the nonce and then computes a key,
    // the current nonce should be 2 at this point
    let next_key = get_next_key(data_store);
    
    // Verify nonce was incremented
    let final_nonce = get_current_nonce(data_store);
    assert(final_nonce == 3, 'Nonce should be 3 after get_next_key');

    // We can't predict the exact hash result, but we can ensure it's not zero
    assert(next_key != 0, 'Next key should not be zero');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}