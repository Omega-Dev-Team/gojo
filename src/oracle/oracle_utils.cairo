// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::Default;
use hash::LegacyHash;
use ecdsa::recover_public_key;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::market::market::{Market};
use satoru::oracle::{
    oracle::{SetPricesCache, SetPricesInnerCache}, error::OracleError,
    interfaces::account::{IAccountDispatcher, IAccountDispatcherTrait}
};
use satoru::price::price::{Price};
use satoru::utils::{
    store_arrays::{StoreContractAddressArray, StorePriceArray, StoreU256Array, StoreFelt252Array},
    arrays::{are_lte_u64, are_gte_u64, get_uncompacted_value, get_uncompacted_value_u64},
    bits::{BITMASK_8, BITMASK_16, BITMASK_32, BITMASK_64}
};

// External imports.
use alexandria_data_structures::array_ext::SpanTraitExt;


/// SetPricesParams struct for values required in Oracle.set_prices.
/// # Arguments
/// * `signer_info` - compacted indexes of signers, the index is used to retrieve
/// the signer address from the OracleStore.
/// * `tokens` - list of tokens to set prices for.
/// * `compacted_oracle_block_numbers` - compacted oracle block numbers.
/// * `compacted_oracle_timestamps` - compacted oracle timestamps.
/// * `compacted_decimals` - compacted decimals for prices.
/// * `compacted_min_prices` - compacted min prices.
/// * `compacted_min_prices_indexes` - compacted min price indexes.
/// * `compacted_max_prices` - compacted max prices.
/// * `compacted_max_prices_indexes` - compacted max price indexes.
/// * `signatures` - signatures of the oracle signers.
/// * `price_feed_tokens` - tokens to set prices for based on an external price feed value.
#[derive(Default, Drop, Clone, Serde)]
struct SetPricesParams {
    signer_info: u256,
    tokens: Array<ContractAddress>,
    compacted_min_oracle_block_numbers: Array<u64>,
    compacted_max_oracle_block_numbers: Array<u64>,
    compacted_oracle_timestamps: Array<u64>,
    compacted_decimals: Array<u256>,
    compacted_min_prices: Array<u256>,
    compacted_min_prices_indexes: Array<u256>,
    compacted_max_prices: Array<u256>,
    compacted_max_prices_indexes: Array<u256>,
    signatures: Array<Span<felt252>>,
    price_feed_tokens: Array<ContractAddress>,
}

#[derive(Drop, Clone, starknet::Store, Serde)]
struct SimulatePricesParams {
    primary_tokens: Array<ContractAddress>,
    primary_prices: Array<Price>,
}


/// # Arguments
/// * `min_oracle_block_number` - The min block number used for the signed message hash.
/// * `max_oracle_block_number` - The max block number used for the signed message hash.
/// * `oracle_timestamp` - The timestamp used for the signed message hash.
/// * `block_hash` - The block hash used for the signed message hash.
/// * `token` - The token used for the signed message hash.
/// * `token_oracle_type` - The type of token used for the signed message hash.
/// * `precision` - The precision used for the signed message hash.
/// * `min_price` - The min price used for the signed message hash.
/// * `max_price` - The max price used for the signed message hash.
#[derive(Copy, Drop, starknet::Store, Serde)]
struct ReportInfo {
    min_oracle_block_number: u64,
    max_oracle_block_number: u64,
    oracle_timestamp: u64,
    block_hash: felt252,
    token: ContractAddress,
    token_oracle_type: felt252,
    precision: u256,
    min_price: u256,
    max_price: u256,
}

// compacted prices have a length of 32 bits
const COMPACTED_PRICE_BIT_LENGTH: usize = 32;
fn COMPACTED_PRICE_BITMASK() -> u256 {
    BITMASK_32
}

// compacted precisions have a length of 8 bits
const COMPACTED_PRECISION_BIT_LENGTH: usize = 8;
fn COMPACTED_PRECISION_BITMASK() -> u256 {
    BITMASK_8
}

// compacted block numbers have a length of 64 bits
const COMPACTED_BLOCK_NUMBER_BIT_LENGTH: usize = 64;
fn COMPACTED_BLOCK_NUMBER_BITMASK() -> u64 {
    BITMASK_64
}

// compacted timestamps have a length of 64 bits
const COMPACTED_TIMESTAMP_BIT_LENGTH: usize = 64;
fn COMPACTED_TIMESTAMP_BITMASK() -> u64 {
    BITMASK_64
}

// compacted price indexes have a length of 8 bits
const COMPACTED_PRICE_INDEX_BIT_LENGTH: usize = 8;
fn COMPACTED_PRICE_INDEX_BITMASK() -> u256 {
    BITMASK_8
}

/// Validates wether a block number is in range.
/// # Arguments
/// * `min_oracle_block_numbers` - The oracles block number that should be less than block_number.
/// * `max_oracle_block_numbers` - The oracles block number that should be higher than block_number.
/// * `block_number` - The block number to compare to.
fn validate_block_number_within_range(
    min_oracle_block_numbers: Span<u64>, max_oracle_block_numbers: Span<u64>, block_number: u64
) {
    if !is_block_number_within_range(
        min_oracle_block_numbers, max_oracle_block_numbers, block_number
    ) {
        OracleError::ORACLE_BLOCK_NUMBERS_NOT_WITHIN_RANGE(
            min_oracle_block_numbers, max_oracle_block_numbers, block_number
        );
    }
}

/// Validates wether a block number is in range.
/// # Arguments
/// * `min_oracle_block_numbers` - The oracles block number that should be less than block_number.
/// * `max_oracle_block_numbers` - The oracles block number that should be higher than block_number.
/// * `block_number` - The block number to compare to.
/// # Returns
/// True if block_number is in range, false else.
fn is_block_number_within_range(
    min_oracle_block_numbers: Span<u64>, max_oracle_block_numbers: Span<u64>, block_number: u64
) -> bool {
    if (!are_lte_u64(min_oracle_block_numbers, block_number)) {
        return false;
    }
    if (!are_gte_u64(max_oracle_block_numbers, block_number)) {
        return false;
    }

    true
}

/// Get the uncompacted oracle block numbers.
/// # Arguments
/// * `compacted_oracle_block_numbers` - The compacted oracle block numbers.
/// * `length` - The length of the uncompacted oracle block numbers.
/// # Returns
/// The uncompacted oracle block numbers.
fn get_uncompacted_oracle_block_numbers(
    compacted_oracle_block_numbers: Span<u64>, length: usize
) -> Array<u64> {
    let mut block_numbers = ArrayTrait::new();

    let mut i = 0;
    loop {
        if (i == length) {
            break;
        }

        block_numbers
            .append(get_uncompacted_oracle_block_number(compacted_oracle_block_numbers, i));

        i += 1;
    };

    block_numbers
}

/// Get the uncompacted oracle block number.
/// # Arguments
/// * `compacted_oracle_block_numbers` - The compacted oracle block numbers.
/// * `index` - The index to get the uncompacted oracle block number at.
/// # Returns
/// The uncompacted oracle block number.
fn get_uncompacted_oracle_block_number(
    compacted_oracle_block_numbers: Span<u64>, index: usize
) -> u64 {
    let block_number = get_uncompacted_value_u64(
        compacted_oracle_block_numbers,
        index,
        COMPACTED_BLOCK_NUMBER_BIT_LENGTH,
        COMPACTED_BLOCK_NUMBER_BITMASK(),
        'get_uncmpctd_oracle_block_numb'
    );

    block_number
}

impl DefaultReportInfo of Default<ReportInfo> {
    fn default() -> ReportInfo {
        ReportInfo {
            min_oracle_block_number: 0,
            max_oracle_block_number: 0,
            oracle_timestamp: 0,
            block_hash: 0,
            token: Zeroable::zero(),
            token_oracle_type: 0,
            precision: 0,
            min_price: 0,
            max_price: 0,
        }
    }
}
