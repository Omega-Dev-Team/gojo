import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";
import { get_max_pnl_factor } from './utils/data-store';
import { dataStoreContract } from './utils/contracts';
import { markets_config } from './constants/market-config-data';


const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

const classHashesPath = path.join(__dirname, 'constants', 'classHashes.json');
const classHashes = JSON.parse(fs.readFileSync(classHashesPath, 'utf8'));

dotenv.config();

// Connect provider
const providerUrl = process.env.PROVIDER_URL;
const provider = new RpcProvider({ nodeUrl: providerUrl! });

// Connect your account. To adapt to your own account:
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string;
const account0Address: string = process.env.ACCOUNT_PUBLIC as string;
const account0 = new Account(provider, account0Address!, privateKey0!);

const marketTokenAddress = contractAddresses['ETHUSDTMarketToken'];
const configData = markets_config[marketTokenAddress];

async function getFundingFee() {
    const THRESHOLD_FOR_STABLE_FUNDING = await dataStoreContract.get_u256(dataStoreKeys.thresholdForStableFundingKey(marketTokenAddress));
    const FUNDING_FACTOR = await dataStoreContract.get_u256(dataStoreKeys.fundingFactorKey(marketTokenAddress));
    const FUNDING_EXPONENT_FACTOR = await dataStoreContract.get_u256(dataStoreKeys.fundingExponentFactorKey(marketTokenAddress));

    const default_FUNDING_FACTOR = configData.fundingFactor
    console.log("🚀 ~ getFundingFee ~ default_FUNDING_FACTOR:", default_FUNDING_FACTOR.toBigInt())
    console.table({
        THRESHOLD_FOR_STABLE_FUNDING,
        FUNDING_FACTOR,
        FUNDING_EXPONENT_FACTOR
    })
}
(async () => {
    getFundingFee()
})();
