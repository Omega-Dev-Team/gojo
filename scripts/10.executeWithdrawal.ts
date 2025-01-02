import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { dataStoreContract,withdrawalHandlerContract} from './utils/contracts';

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

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
export async function getAccountWithdrawalCount(accountAddress: string) {
    const accountDepositCount = await dataStoreContract.get_account_withdrawal_count(accountAddress);
    return Number(accountDepositCount);
}

// Get all account deposit keys
export async function getAccountWithdrawalKeys(accountAddress: string) {
    const accountDepositCount = await getAccountWithdrawalCount(accountAddress);
    const accountWithdrawalKeys = await dataStoreContract.get_account_withdrawal_keys(accountAddress, 0, Number(accountDepositCount));
    return accountWithdrawalKeys;
}

// Get latest account deposit key
export async function getAccountLatestWithdrawalKeys(accountAddress: string) {
    const accountWithdrawalKeys = await getAccountWithdrawalKeys(accountAddress);
    return accountWithdrawalKeys[accountWithdrawalKeys.length - 1];
}

export async function getWithdrawal(key: string) {
    const data = await dataStoreContract.get_withdrawal(key);
    return (data);
}

async function deploy() {
    let key = await getAccountLatestWithdrawalKeys("0x06774e2c4fde12cc5a161fe2a717d3d7f43129d5ae388faaf52a2fb104bfd686");
    console.log("🚀 ~ deploy ~ key:", key)

    const current_block = await provider.getBlockNumber();
    const current_block_data = await provider.getBlock(current_block);
    const block0 = 0;
    const block1 = current_block - 1;

    const setPricesParams = {
        signer_info: 0,
        tokens: [contractAddresses['ETH'], contractAddresses['USDT'], contractAddresses['USDC'],],
        compacted_min_oracle_block_numbers: [block0, block0, block0],
        compacted_max_oracle_block_numbers: [block1, block1, block1],
        compacted_oracle_timestamps: [current_block_data.timestamp, current_block_data.timestamp, current_block_data.timestamp],
        compacted_decimals: [18, 18],
        compacted_min_prices: [3466.42 * 1e12, 1 * 1e24, 1 * 1e24], // 500000, 10000 compacted
        compacted_min_prices_indexes: [0],
        compacted_max_prices: [3466.42 * 1e12, 1 * 1e24, 1 * 1e24], // 500000, 10000 compacted
        compacted_max_prices_indexes: [0],
        signatures: [
            ['signatures1', 'signatures2'], ['signatures1', 'signatures2']
        ],
        price_feed_tokens: []
    };

    withdrawalHandlerContract.connect(account0)

    const executeOrderCall = withdrawalHandlerContract.populate("execute_withdrawal", [
        key,
        setPricesParams
    ])
    let tx = await withdrawalHandlerContract.execute_withdrawal(executeOrderCall.calldata)
    console.log("Withdrawal executed: https://sepolia.starkscan.co/tx/" + tx.transaction_hash);
}

deploy()