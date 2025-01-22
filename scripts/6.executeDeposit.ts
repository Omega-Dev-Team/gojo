import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { dataStoreContract, depositHandlerContract } from './utils/contracts';
import { getContractAddresses } from "./utils/get-contract-addresses";

const contractAddresses = getContractAddresses();

dotenv.config()

// Function to pause execution for the given number of milliseconds.
const sleep = (milliseconds: number | undefined) => {
    return new Promise(resolve => setTimeout(resolve, milliseconds));
}

// connect provider
const providerUrl = process.env.PROVIDER_URL
const provider = new RpcProvider({ nodeUrl: providerUrl! })
// connect your account. To adapt to your own account :
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
const account0Address: string = process.env.ACCOUNT_PUBLIC as string
const account0 = new Account(provider, account0Address!, privateKey0!)

// Read account deposit keys count
export async function getAccountDepositCount(accountAddress: string) {
    const accountDepositCount = await dataStoreContract.get_account_deposit_count(accountAddress);
    return Number(accountDepositCount);
}

// Get all account deposit keys
export async function getAccountDepositKeys(accountAddress: string) {
    const accountDepositCount = await getAccountDepositCount(accountAddress);
    console.log("Account Deposit Count:", accountDepositCount)
    const accountDepositKeys = await dataStoreContract.get_account_deposit_keys(accountAddress, 0, Number(accountDepositCount));
    return accountDepositKeys;
}

// Get latest account deposit key
export async function getAccountLatestDepositKeys(accountAddress: string) {
    const accountDepositKeys = await getAccountDepositKeys(accountAddress);
    return accountDepositKeys[accountDepositKeys.length - 1];
}

async function execute_deposit() {
    const key = await getAccountLatestDepositKeys("0x048b7fa2d7519ead304594b4006cbaaeaf3d3ce34b7c7e88a20939d953679521");
    console.log("🚀 ~ execute_deposit ~ key:", key)

    const current_block = await provider.getBlockNumber();
    const current_block_data = await provider.getBlock(current_block);
    const block0 = 0;
    const block1 = current_block - 1;

    const oracleParams = {
        signer_info: 1,
        tokens: [contractAddresses['ETH'], contractAddresses['USDT'], contractAddresses['USDC']],
        compacted_min_oracle_block_numbers: [block0, block0, block0],
        compacted_max_oracle_block_numbers: [block1, block1, block1],
        compacted_oracle_timestamps: [current_block_data.timestamp, current_block_data.timestamp, current_block_data.timestamp],
        compacted_decimals: [18, 6, 6],
        compacted_min_prices: [3300.95 * 1e12, 1 * 1e24, 1 * 1e24], // 500000, 10000 compacted
        compacted_min_prices_indexes: [0],
        compacted_max_prices: [3300.95 * 1e12, 1 * 1e24, 1 * 1e24], // 500000, 10000 compacted
        compacted_max_prices_indexes: [0],
        signatures: [
            ['signatures1', 'signatures2'], ['signatures1', 'signatures2']
        ],
        price_feed_tokens: []
    };

    depositHandlerContract.connect(account0)

    const executeOrderCall = depositHandlerContract.populate("execute_deposit", [
        key,
        oracleParams
    ])
    console.log("🚀 ~ deploy ~ executeOrderCall:", executeOrderCall)
    let tx = await depositHandlerContract.execute_deposit(executeOrderCall.calldata)
    console.log("Deposit executed: https://sepolia.starkscan.co/tx/" + tx.transaction_hash + "\n");
}

execute_deposit()