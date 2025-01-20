import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";

import { contractAddresses, dataStoreContract, } from './utils/contracts';
import { tryInvoke } from './constants/utils';


dotenv.config();

// Connect provider

const marketTokenAddress = contractAddresses['ETHUSDCMarketToken'];
const eth: string = contractAddresses['ETH'];
const usdc: string = contractAddresses['USDC'];
const readerAddress = contractAddresses['Reader'];
const dataStoreAddress = contractAddresses['DataStore'];

async function updateSwapInventory() {
    const virtualMarketId = dataStoreKeys.virtualMarketIdKey(marketTokenAddress);

    const currentPoolAmountLong = await dataStoreContract.get_u256(dataStoreKeys.poolAmountKey(marketTokenAddress, eth));
    const currentPoolAmountShort = await dataStoreContract.get_u256(dataStoreKeys.poolAmountKey(marketTokenAddress, usdc));

    const virtualInventoryForSwapsLongKey = dataStoreKeys.virtualInventoryForSwapsKey(virtualMarketId, true);
    const virtualInventoryForSwapsShortKey = dataStoreKeys.virtualInventoryForSwapsKey(virtualMarketId, false);

    const currentVirtualInventoryForSwapsLong = await dataStoreContract.get_u256(virtualInventoryForSwapsLongKey);
    const currentVirtualInventoryForSwapsShort = await dataStoreContract.get_u256(virtualInventoryForSwapsShortKey);

    console.table({
        currentPoolAmountLong,
        currentPoolAmountShort,
        currentVirtualInventoryForSwapsLong,
        currentVirtualInventoryForSwapsShort
    });

    const calls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [];

    calls.push(
        {
            contractAddress: dataStoreAddress,
            entrypoint: "set_u256",
            calldata: [virtualInventoryForSwapsLongKey, cairo.uint256(currentPoolAmountLong.toString()),]
        },
        {
            contractAddress: dataStoreAddress,
            entrypoint: "set_u256",
            calldata: [virtualInventoryForSwapsShortKey, cairo.uint256(currentPoolAmountShort.toString()),]
        }
    );

    // await tryInvoke(`Update inventory swap`, calls);

}


(async () => {
    await updateSwapInventory();
})();  
