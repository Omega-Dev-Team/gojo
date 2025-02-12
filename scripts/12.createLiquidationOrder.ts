import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec, cairo } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { liquidationHandlerContract, contractAddresses, account0, provider, readerContract, dataStoreContract } from "./utils/contracts";

dotenv.config()


async function executeLiquidationOrder() {
    const current_block = await provider.getBlockNumber();
    const current_block_data = await provider.getBlock(current_block);
    const block0 = 0;
    const block1 = current_block - 1;

    const eth: string = contractAddresses['ETH'];
    const usdt: string = contractAddresses['USDT'];
    const usdc: string = contractAddresses['USDC'];
    const marketTokenAddress = contractAddresses['ETHUSDCMarketToken'];
    const priceETH = 3343 * 1e12;
    const oracleParams = {
        signer_info: 1,
        tokens: [eth, usdt, usdc],
        compacted_min_oracle_block_numbers: [block0, block0, block0],
        compacted_max_oracle_block_numbers: [block1, block1, block1],
        compacted_oracle_timestamps: [current_block_data.timestamp, current_block_data.timestamp, current_block_data.timestamp],
        compacted_decimals: [18, 6, 6],
        compacted_min_prices: [priceETH, 0.99 * 1e24, 0.99 * 1e24], // 500000, 10000 compacted
        compacted_min_prices_indexes: [0],
        compacted_max_prices: [priceETH, 1.01 * 1e24, 1.01 * 1e24], // 500000, 10000 compacted
        compacted_max_prices_indexes: [0],
        signatures: [

        ],
        price_feed_tokens: []
    };

    const account = "0x06774e2c4fde12cc5a161fe2a717d3d7f43129d5ae388faaf52a2fb104bfd686";

    const prices = {
        index_token_price: {
            min: cairo.uint256(priceETH),
            max: cairo.uint256(priceETH),
        },
        long_token_price: {
            min: cairo.uint256(priceETH),
            max: cairo.uint256(priceETH),
        },
        short_token_price: {
            min: cairo.uint256(0.99 * 1e24),
            max: cairo.uint256(1.01 * 1e24),
        },
    };
    const marketAddresses = {
        market_token: marketTokenAddress,
        /// Address of the index token for the market.
        index_token: eth,
        /// Address of the long token for the market.
        long_token: eth,
        /// Address of the short token for the market.
        short_token: usdt,
    }

    const keys = await dataStoreContract.get_account_position_keys(account, 0, 1000n);
    console.log("🚀 ~ executeLiquidationOrder ~ keys:", keys)
    for await (const key of keys) { 
        const position = await dataStoreContract.get_position(key);
        const is_position_liquidatable = await readerContract.is_position_liquidable(
            {
                contract_address: dataStoreContract.address
            },
            {
                contract_address: contractAddresses["ReferralStorage"]
            },
            position,
            marketAddresses,
            prices,
            true
        );
        console.log("🚀 ~ forawait ~ is_position_liquidatable:", position, is_position_liquidatable)
        
    }

    liquidationHandlerContract.connect(account0);

    const payload = {
        oracle_params: oracleParams,
        account: account,
        market: marketTokenAddress,
        collateral_token: eth,
        is_long: true,
    }

    const executeLiquidationOrderCall = liquidationHandlerContract.populate("execute_liquidation", payload)

    let tx: any = await liquidationHandlerContract.execute_liquidation(executeLiquidationOrderCall.calldata as Calldata);
    console.log("Order executed: https://sepolia.starkscan.co/tx/" + tx.transaction_hash);
}

executeLiquidationOrder()