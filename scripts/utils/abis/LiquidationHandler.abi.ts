export const LiquidationHandlerABI = [
  {
    "type": "impl",
    "name": "LiquidationHandlerImpl",
    "interface_name": "satoru::exchange::liquidation_handler::ILiquidationHandler"
  },
  {
    "type": "enum",
    "name": "core::bool",
    "variants": [
      {
        "name": "False",
        "type": "()"
      },
      {
        "name": "True",
        "type": "()"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::integer::u256",
    "members": [
      {
        "name": "low",
        "type": "core::integer::u128"
      },
      {
        "name": "high",
        "type": "core::integer::u128"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::array::Span::<core::felt252>",
    "members": [
      {
        "name": "snapshot",
        "type": "@core::array::Array::<core::felt252>"
      }
    ]
  },
  {
    "type": "struct",
    "name": "satoru::oracle::oracle_utils::SetPricesParams",
    "members": [
      {
        "name": "signer_info",
        "type": "core::integer::u256"
      },
      {
        "name": "tokens",
        "type": "core::array::Array::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "compacted_min_oracle_block_numbers",
        "type": "core::array::Array::<core::integer::u64>"
      },
      {
        "name": "compacted_max_oracle_block_numbers",
        "type": "core::array::Array::<core::integer::u64>"
      },
      {
        "name": "compacted_oracle_timestamps",
        "type": "core::array::Array::<core::integer::u64>"
      },
      {
        "name": "compacted_decimals",
        "type": "core::array::Array::<core::integer::u256>"
      },
      {
        "name": "compacted_min_prices",
        "type": "core::array::Array::<core::integer::u256>"
      },
      {
        "name": "compacted_min_prices_indexes",
        "type": "core::array::Array::<core::integer::u256>"
      },
      {
        "name": "compacted_max_prices",
        "type": "core::array::Array::<core::integer::u256>"
      },
      {
        "name": "compacted_max_prices_indexes",
        "type": "core::array::Array::<core::integer::u256>"
      },
      {
        "name": "signatures",
        "type": "core::array::Array::<core::array::Span::<core::felt252>>"
      },
      {
        "name": "price_feed_tokens",
        "type": "core::array::Array::<core::starknet::contract_address::ContractAddress>"
      }
    ]
  },
  {
    "type": "interface",
    "name": "satoru::exchange::liquidation_handler::ILiquidationHandler",
    "items": [
      {
        "type": "function",
        "name": "execute_liquidation",
        "inputs": [
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "market",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "collateral_token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "is_long",
            "type": "core::bool"
          },
          {
            "name": "oracle_params",
            "type": "satoru::oracle::oracle_utils::SetPricesParams"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "constructor",
    "name": "constructor",
    "inputs": [
      {
        "name": "data_store_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "role_store_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "event_emitter_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "order_vault_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "oracle_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "swap_handler_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "referral_storage_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "order_utils_class_hash",
        "type": "core::starknet::class_hash::ClassHash"
      },
      {
        "name": "increase_order_utils_class_hash",
        "type": "core::starknet::class_hash::ClassHash"
      },
      {
        "name": "decrease_order_utils_class_hash",
        "type": "core::starknet::class_hash::ClassHash"
      },
      {
        "name": "swap_order_utils_class_hash",
        "type": "core::starknet::class_hash::ClassHash"
      }
    ]
  },
  {
    "type": "event",
    "name": "satoru::exchange::liquidation_handler::LiquidationHandler::Event",
    "kind": "enum",
    "variants": []
  }
] as const;