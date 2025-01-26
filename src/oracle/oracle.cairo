//! Contract to validate and store signed values.
//! Some calculations e.g. calculating the size in tokens for a position
//! may not work with zero / negative prices.
//! As a result, zero / negative prices are considered empty / invalid.
//! A market may need to be manually settled in this case.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::{
    oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait},
    oracle_utils::{SetPricesParams, ReportInfo}, error::OracleError,
};
use satoru::price::price::Price;
use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};


// *************************************************************************
//                  Interface of the `Oracle` contract.
// *************************************************************************
#[starknet::interface]
trait IOracle<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    /// * `oracle_store_address` - The address of the oracle store contract.
    fn initialize(
        ref self: TContractState,
        role_store_address: ContractAddress,
        oracle_store_address: ContractAddress,
        pragma_address: ContractAddress,
    );

    /// Validate and store signed prices
    ///
    /// The set_prices function is used to set the prices of tokens in the Oracle contract.
    /// It accepts an array of tokens and a signer_info parameter. The signer_info parameter
    /// contains information about the signers that have signed the transaction to set the prices.
    /// The first 16 bits of the signer_info parameter contain the number of signers, and the following
    /// bits contain the index of each signer in the oracle_store. The function checks that the number
    /// of signers is greater than or equal to the minimum number of signers required, and that
    /// the signer indices are unique and within the maximum signer index. The function then calls
    /// set_primary_prices and set_prices_from_price_feeds to set the prices of the tokens.
    ///
    /// Oracle prices are signed as a value together with a precision, this allows
    /// prices to be compacted as uint32 values.
    ///
    /// The signed prices represent the price of one unit of the token using a value
    /// with 30 decimals of precision.
    ///
    /// # Arguments
    /// * `data_store` - The data store.
    /// * `event_emitter` - The event emitter.
    /// * `params` - The set price params.
    fn set_prices(
        ref self: TContractState,
        data_store: IDataStoreDispatcher,
        event_emitter: IEventEmitterDispatcher,
        params: SetPricesParams,
    );

    /// Set the primary price
    /// # Arguments
    /// * `token` - The token to set the price for.
    /// * `price` - The price value to set to.
    fn set_primary_price(ref self: TContractState, token: ContractAddress, price: Price);

    /// Clear all prices
    fn clear_all_prices(ref self: TContractState);

    /// Get the length of tokens_with_prices
    /// # Returns
    /// The length of tokens_with_prices
    fn get_tokens_with_prices_count(self: @TContractState) -> u32;

    /// Get the tokens_with_prices from start to end.
    /// # Arguments
    /// * `start` - The start index, the value for this index will be included.
    /// * `end` -  The end index, the value for this index will be excluded.
    /// # Returns
    /// The tokens of tokens_with_prices for the specified indexes.
    fn get_tokens_with_prices(
        self: @TContractState, start: u32, end: u32
    ) -> Array<ContractAddress>;

    /// Get the primary price of a token.
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The primary price of a token.
    fn get_primary_price(self: @TContractState, token: ContractAddress) -> Price;

    /// Get the stable price of a token.
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The stable price of a token.
    fn get_stable_price(
        self: @TContractState, data_store: IDataStoreDispatcher, token: ContractAddress
    ) -> u256;

    /// Get the multiplier value to convert the external price feed price to the price of 1 unit of the token
    /// represented with 30 decimals.
    /// For example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
    /// 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
    /// if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
    /// in this case the priceFeedMultiplier should be 10 ^ 46
    /// the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
    /// formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
    /// # Arguments
    /// * `data_store` - The data store dispatcher.
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The price feed multiplier.
    fn get_price_feed_multiplier(
        self: @TContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
    ) -> u256;

    /// Validate prices in `params` for oracles. TODO implement price validations
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `params` - The parameters used to set prices in oracle.
    // fn validate_prices(
    //     self: @TContractState, data_store: IDataStoreDispatcher, params: SetPricesParams,
    // ) -> Array<ValidatedPrice>;

    fn get_asset_price_median(self: @TContractState, asset: DataType) -> PragmaPricesResponse;
}

/// A price that has been validated in validate_prices().
#[derive(Copy, Drop, starknet::Store, Serde)]
struct ValidatedPrice {
    /// The token to validate the price for.
    token: ContractAddress,
    /// The min price of the token.
    min: u256,
    /// The max price of the token.
    max: u256,
    /// The timestamp of the price validated.
    timestamp: u64,
    min_block_number: u64,
    max_block_number: u64,
}

/// Struct used in set_prices as a cache.
#[derive(Default, Drop)]
struct SetPricesCache {
    info: ReportInfo,
    /// The min block confirmations expected.
    min_block_confirmations: u64,
    /// The max allowed age of price values.
    max_price_age: u64,
    /// The max ref_price deviation factor allowed.
    max_ref_price_deviation_factor: u256,
    /// The previous oracle block number of the loop.
    prev_min_oracle_block_number: u64,
    // The prices that have been validated to set.
    validated_prices: Array<ValidatedPrice>,
}

/// Struct used in validate_prices as an inner cache.
#[derive(Default, Drop)]
struct SetPricesInnerCache {
    /// The current price index to retrieve from compacted_min_prices and compacted_max_prices
    /// to construct the min_prices and max_prices array.
    price_index: usize,
    /// The current signature index to retrieve from the signatures array.
    signature_index: usize,
    /// The index of the min price in min_prices for the current signer.
    min_price_index: u256,
    /// The index of the max price in max_prices for the current signer.
    max_price_index: u256,
    /// The min prices.
    min_prices: Array<u256>,
    /// The max prices.
    max_prices: Array<u256>,
    /// The min price index using U256Mask.
    min_price_index_mask: u256,
    /// The max price index using U256Mask.
    max_price_index_mask: u256,
}

#[starknet::contract]
mod Oracle {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::traits::Into;
    use core::traits::TryInto;
    use core::zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::info::{get_block_timestamp, get_block_number};
    use starknet::syscalls::get_block_hash_syscall;
    use starknet::SyscallResultTrait;
    use starknet::storage_access::storage_base_address_from_felt252;

    use alexandria_math::BitShift;
    use alexandria_sorting::merge_sort;
    use alexandria_storage::list::{ListTrait, List};
    use poseidon::poseidon_hash_span;
    // Local imports.
    use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::price::price::Price;
    use satoru::oracle::{
        oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait}, oracle_utils,
        oracle_utils::{SetPricesParams, ReportInfo}, error::OracleError,
    };
    use satoru::role::role_module::{
        IRoleModule, RoleModule
    }; //::role_store::IInternalContractMemberStateTrait as RoleModuleStateTrait;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::utils::{arrays, arrays::pow, bits, calc, precision};
    use satoru::utils::u256_mask::{Mask, MaskTrait, validate_unique_and_set_index};

    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};

    use super::{IOracle, SetPricesCache, SetPricesInnerCache, ValidatedPrice};


    // *************************************************************************
    //                              CONSTANTS
    // *************************************************************************
    const SIGNER_INDEX_LENGTH: u256 = 16;
    // subtract 1 as the first slot is used to store number of signers
    const MAX_SIGNERS: u256 = 15; //256 / SIGNER_INDEX_LENGTH - 1;
    // signer indexes are recorded in a signerIndexFlags uint256 value to check for uniqueness
    const MAX_SIGNER_INDEX: u256 = 256;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `OracleStore` contract.
        oracle_store: IOracleStoreDispatcher,
        /// Interface to interact with the Pragma Oracle.
        price_feed: IPragmaABIDispatcher,
        /// List of Prices related to a token.
        tokens_with_prices: List<ContractAddress>,
        /// Mapping between tokens and prices.
        primary_prices: LegacyMap::<ContractAddress, Price>,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    /// * `oracle_store_address` - The address of the oracle store contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        role_store_address: ContractAddress,
        oracle_store_address: ContractAddress,
        pragma_address: ContractAddress,
    ) {
        self.initialize(role_store_address, oracle_store_address, pragma_address);
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl OracleImpl of super::IOracle<ContractState> {
        fn initialize(
            ref self: ContractState,
            role_store_address: ContractAddress,
            oracle_store_address: ContractAddress,
            pragma_address: ContractAddress,
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.role_store.read().contract_address.is_zero(), OracleError::ALREADY_INITIALIZED
            );
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
            self
                .oracle_store
                .write(IOracleStoreDispatcher { contract_address: oracle_store_address });
            self.price_feed.write(IPragmaABIDispatcher { contract_address: pragma_address });
        }

        fn set_prices(
            ref self: ContractState,
            data_store: IDataStoreDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) {
            let cloned_params = params.clone();
            
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            let tokens_with_prices_len = self.tokens_with_prices.read().len();
            if !tokens_with_prices_len.is_zero() {
                OracleError::NON_EMPTY_TOKENS_WITH_PRICES(tokens_with_prices_len);
            };

            // in this case if params.tokens is empty, the function can return
            if params.tokens.len().is_zero() {
                return;
            }

            let mut i = 0;
            loop {
                if i == params.tokens.len() {
                    break;
                }
                let token = *params.tokens.at(i);
                let price = Price {
                    min: *params.compacted_max_prices.at(i), max: *params.compacted_max_prices.at(i)
                };
                self.set_primary_price_(token, price);
                i += 1;
            };

            // NOTE(Ted): Emit event OraclePriceUpdate for Indexer tracking
            self.emit_tokens_oracle_price_update_(event_emitter, cloned_params);
            // self.set_prices_(data_store, event_emitter, params); TODO uncomment
        }

        // Set the primary price
        // Arguments
        // * `token` - The token to set the price for.
        // * `price` - The price value to set to.
        fn set_primary_price(ref self: ContractState, token: ContractAddress, price: Price,) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            self.set_primary_price_(token, price);
        }

        fn clear_all_prices(ref self: ContractState) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            loop {
                if self.tokens_with_prices.read().len() == Zeroable::zero() {
                    break;
                }
                let token = self.tokens_with_prices.read().get(0).expect('array get failed');
                self.remove_primary_price(token);
            };
        }

        fn get_asset_price_median(self: @ContractState, asset: DataType) -> PragmaPricesResponse {
            self.price_feed.read().get_data(asset, AggregationMode::Median(()))
        }
        //USAGE/
        // let KEY :felt252 = 18669995996566340; // felt252 conversion of "BTC/USD", can also write const KEY : felt252 = 'BTC/USD';
        // Sepolia contract address : 0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a
        // let oracle_address : ContractAddress = contract_address_const::<0x06df335982dddce41008e4c03f2546fa27276567b5274c7d0c1262f3c2b5d167>();
        // let price = get_asset_price_median(DataType::SpotEntry(KEY));

        fn get_tokens_with_prices_count(self: @ContractState) -> u32 {
            let token_with_prices = self.tokens_with_prices.read();
            let tokens_with_prices_len = token_with_prices.len();
            let mut count = 0;
            let mut i = 0;
            loop {
                if i == tokens_with_prices_len {
                    break;
                }
                if !token_with_prices.get(i).expect('array get failed').is_zero() {
                    count += 1;
                }
                i += 1;
            };
            count
        }

        fn get_tokens_with_prices(
            self: @ContractState, start: u32, mut end: u32
        ) -> Array<ContractAddress> {
            let mut arr: Array<ContractAddress> = array![];
            let tokens_with_prices = self.tokens_with_prices.read();
            let tokens_with_prices_len = tokens_with_prices.len();
            if end > tokens_with_prices_len {
                end = tokens_with_prices_len;
            }
            if tokens_with_prices.len().is_zero() {
                return arr;
            }
            let mut arr: Array<ContractAddress> = array![];
            let mut index = start;
            loop {
                if index >= end {
                    break;
                }
                arr.append(tokens_with_prices[index]);
                index += 1;
            };
            arr
        }

        fn get_primary_price(self: @ContractState, token: ContractAddress) -> Price {
            if token.is_zero() {
                return Price { min: 0, max: 0 };
            }
            let price = self.primary_prices.read(token);
            if price.is_zero() {
                OracleError::EMPTY_PRIMARY_PRICE();
            }
            price
        }


        fn get_stable_price(
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress
        ) -> u256 {
            data_store.get_u256(keys::stable_price_key(token))
        }

        fn get_price_feed_multiplier(
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
        ) -> u256 {
            let multiplier = data_store.get_u256(keys::price_feed_multiplier_key(token));

            if multiplier.is_zero() {
                OracleError::EMPTY_PRICE_FEED_MULTIPLIER();
            }
            multiplier
        }
    // fn validate_prices(
    //     self: @ContractState, data_store: IDataStoreDispatcher, params: SetPricesParams,
    // ) -> Array<ValidatedPrice> {
    //     self.validate_prices_(data_store, params)
    // }
    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {

    fn emit_tokens_oracle_price_update_(
            self: @ContractState,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) {
            let mut i = 0;
            loop {
                if i == params.tokens.len() {
                    break;
                }
                let token = *params.tokens.at(i);
                let price = Price {
                    min: *params.compacted_max_prices.at(i), max: *params.compacted_max_prices.at(i)
                };
                self.emit_oracle_price_updated(event_emitter, token, price.min, price.max, false);
                i += 1;
            };
        }


        /// Set the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        /// * `price` - The price value to set to.
        fn set_primary_price_(ref self: ContractState, token: ContractAddress, price: Price) {
            match self.get_token_with_price_index(token) {
                Option::Some(i) => (),
                Option::None(_) => {
                    self.primary_prices.write(token, price);

                    let mut tokens_with_prices = self.tokens_with_prices.read();
                    let index_of_zero = self.get_token_with_price_index(Zeroable::zero());
                    // If an entry with zero address is found the entry is set to the new token,
                    // otherwise the new token is appended to the list. This is to avoid the list 
                    // to grow indefinitely.
                    match index_of_zero {
                        Option::Some(i) => { tokens_with_prices.set(i, token); },
                        Option::None => { tokens_with_prices.append(token); }
                    }
                }
            }
        }

        /// Remove the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        fn remove_primary_price(ref self: ContractState, token: ContractAddress) {
            self.primary_prices.write(token, Zeroable::zero());
            let mut tokens_prices = self.tokens_with_prices.read();
            tokens_prices.pop_front();
            self.tokens_with_prices.write(tokens_prices);
        }

        /// Get the price feed prices.
        /// There is a small risk of stale pricing due to latency in price updates or if the chain is down.
        /// This is meant to be for temporary use until low latency price feeds are supported for all tokens.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The price feed multiplier.
        fn get_price_feed_price(
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
        ) -> (bool, u256) {
            let token_id = data_store.get_token_id(token);
            if token_id == 0 {
                return (false, 0);
            }
            let response = self.get_asset_price_median(DataType::SpotEntry(token_id));

            if response.price <= 0 {
                OracleError::INVALID_PRICE_FEED(token, response.price.into());
            }

            let heart_beat_duration = data_store
                .get_u256(keys::price_feed_heartbeat_duration_key(token));

            let current_timestamp = get_block_timestamp();
            if current_timestamp > response.last_updated_timestamp && current_timestamp
                - response
                    .last_updated_timestamp > heart_beat_duration
                    .try_into()
                    .expect('u256 into u32 failed') {
                OracleError::PRICE_FEED_NOT_UPDATED(
                    token, response.last_updated_timestamp, heart_beat_duration
                );
            }

            let precision_ = self.get_price_feed_multiplier(data_store, token);
            let adjusted_price = precision::mul_div( // TODO check precision file
                response.price.into(), precision_, precision::FLOAT_PRECISION
            );

            (true, adjusted_price)
        }

        /// Emits an `OraclePriceUpdated` event for a specific token.
        /// # Parameters
        /// * `event_emitter`: Dispatcher used for emitting events.
        /// * `token`: The contract address of the token for which the price is being updated.
        /// * `min_price`: The minimum price value for the token.
        /// * `max_price`: The maximum price value for the token.
        /// * `is_price_feed`: A boolean flag indicating whether the source is a price feed.
        fn emit_oracle_price_updated(
            self: @ContractState,
            event_emitter: IEventEmitterDispatcher,
            token: ContractAddress,
            min_price: u256,
            max_price: u256,
            is_price_feed: bool,
        ) {
            event_emitter.emit_oracle_price_updated(token, min_price, max_price, is_price_feed);
        }

        /// Returns the index of a given `token` in the `tokens_with_prices` list.
        /// # Arguments
        /// * `token` - A `ContractAddress` representing the token whose index we want to find.
        /// # Returns
        /// * `Option<usize>` - Returns `Some(index)` if the token is found.
        ///   Returns `None` if the token is not found.
        fn get_token_with_price_index(
            self: @ContractState, token: ContractAddress
        ) -> Option<usize> {
            let mut tokens_with_prices = self.tokens_with_prices.read();
            let mut index = Option::None;
            let mut len = 0;
            loop {
                if len == tokens_with_prices.len() {
                    break;
                }
                let token_with_price = tokens_with_prices.get(len);
                match token_with_price {
                    Option::Some(t) => {
                        if token_with_price.unwrap() == token {
                            index = Option::Some(len);
                        }
                    },
                    Option::None => (),
                }
                len += 1;
            };
            index
        }
    }
}
