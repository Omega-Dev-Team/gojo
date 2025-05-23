export const DepositHandlerABI = [
  {
    "type": "impl",
    "name": "DepositHandlerImpl",
    "interface_name": "satoru::exchange::deposit_handler::IDepositHandler"
  },
  {
    "type": "struct",
    "name": "core::array::Span::<core::starknet::contract_address::ContractAddress>",
    "members": [
      {
        "name": "snapshot",
        "type": "@core::array::Array::<core::starknet::contract_address::ContractAddress>"
      }
    ]
  },
  {
    "type": "struct",
    "name": "satoru::utils::span32::Span32::<core::starknet::contract_address::ContractAddress>",
    "members": [
      {
        "name": "snapshot",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
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
    "name": "satoru::deposit::deposit_utils::CreateDepositParams",
    "members": [
      {
        "name": "receiver",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "callback_contract",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "ui_fee_receiver",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "market",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "initial_long_token",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "initial_short_token",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "long_token_swap_path",
        "type": "satoru::utils::span32::Span32::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "short_token_swap_path",
        "type": "satoru::utils::span32::Span32::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "min_market_tokens",
        "type": "core::integer::u256"
      },
      {
        "name": "execution_fee",
        "type": "core::integer::u256"
      },
      {
        "name": "callback_gas_limit",
        "type": "core::integer::u256"
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
    "type": "struct",
    "name": "satoru::price::price::Price",
    "members": [
      {
        "name": "min",
        "type": "core::integer::u256"
      },
      {
        "name": "max",
        "type": "core::integer::u256"
      }
    ]
  },
  {
    "type": "struct",
    "name": "satoru::oracle::oracle_utils::SimulatePricesParams",
    "members": [
      {
        "name": "primary_tokens",
        "type": "core::array::Array::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "primary_prices",
        "type": "core::array::Array::<satoru::price::price::Price>"
      }
    ]
  },
  {
    "type": "interface",
    "name": "satoru::exchange::deposit_handler::IDepositHandler",
    "items": [
      {
        "type": "function",
        "name": "create_deposit",
        "inputs": [
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "params",
            "type": "satoru::deposit::deposit_utils::CreateDepositParams"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "cancel_deposit",
        "inputs": [
          {
            "name": "key",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "execute_deposit",
        "inputs": [
          {
            "name": "key",
            "type": "core::felt252"
          },
          {
            "name": "oracle_params",
            "type": "satoru::oracle::oracle_utils::SetPricesParams"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "simulate_execute_deposit",
        "inputs": [
          {
            "name": "key",
            "type": "core::felt252"
          },
          {
            "name": "params",
            "type": "satoru::oracle::oracle_utils::SimulatePricesParams"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "execute_deposit_keeper",
        "inputs": [
          {
            "name": "key",
            "type": "core::felt252"
          },
          {
            "name": "oracle_params",
            "type": "satoru::oracle::oracle_utils::SetPricesParams"
          },
          {
            "name": "keeper",
            "type": "core::starknet::contract_address::ContractAddress"
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
        "name": "deposit_vault_address",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "oracle_address",
        "type": "core::starknet::contract_address::ContractAddress"
      }
    ]
  },
  {
    "type": "event",
    "name": "satoru::exchange::deposit_handler::DepositHandler::Event",
    "kind": "enum",
    "variants": []
  }
] as const;
