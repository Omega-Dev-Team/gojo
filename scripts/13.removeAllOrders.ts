import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";

import { account0, contractAddresses, dataStoreContract, provider } from './utils/contracts';


dotenv.config();

// Connect provider

const marketTokenAddress = contractAddresses['ETHUSDTMarketToken'];
const eth: string = contractAddresses['ETH'];
const usdt: string = contractAddresses['USDT'];
const readerAddress = contractAddresses['Reader'];
const dataStoreAddress = contractAddresses['DataStore'];

async function removeAllOrders() {
    const keys = await dataStoreContract.get_order_keys(0, 1000n);
    console.log("🚀 ~ removeAllOrders ~ keys:", keys)
    dataStoreContract.connect(account0);
    for await (const key of keys) {
        const order = await dataStoreContract.get_order(key);
        console.log("🚀 ~ forawait ~ order:", order)
        const removeTx: any = await dataStoreContract.remove_order(key, order.account);
        console.log("🚀 ~ forawait ~ removeTx:", removeTx)
        await provider.waitForTransaction(removeTx.transaction_hash);
    }
}


(async () => {
    await removeAllOrders();
})();
