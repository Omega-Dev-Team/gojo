import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";

import { contractAddresses, dataStoreContract } from './utils/contracts';
import { decimalToFloat, tryInvoke } from './constants/utils';


dotenv.config();

const ui_fee_config = {
    ui_fee_factor: decimalToFloat(1, 4).toBigInt(), // 0.01% = 0.0001
    max_ui_fee_factor: decimalToFloat(1, 2).toBigInt(),
}

type DataTable = {
    key: string;
    value: string | bigint;
};

const UIFeeReceiver = contractAddresses["UIFeeReceiver"];

async function getFees() {
    //#region Read Execution Fees
    const data: DataTable[] = [];
    const fee_token = await dataStoreContract.get_address(dataStoreKeys.FEE_TOKEN);
    data.push({ key: 'fee_token', value: num.toHexString(fee_token) });

    const ui_fee_factor = await dataStoreContract.get_u256(dataStoreKeys.uiFeeFactorKey(UIFeeReceiver));
    data.push({ key: 'ui_fee_factor', value: BigInt(ui_fee_factor.toString()) });

    const max_ui_fee_factor = await dataStoreContract.get_u256(dataStoreKeys.MAX_UI_FEE_FACTOR);
    data.push({ key: 'max_ui_fee_factor', value: BigInt(max_ui_fee_factor.toString()) });

    console.table(data);

    //#endregion
}

async function setFees() {
    const calls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [];
    
    const datastoreAddress = dataStoreContract.address;
    calls.push(
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.uiFeeFactorKey(UIFeeReceiver), ui_fee_config.ui_fee_factor, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.MAX_UI_FEE_FACTOR, ui_fee_config.max_ui_fee_factor, "0"],
        },
    )
    await tryInvoke(`Config ui fee`, calls);


    //#endregion
}


(async () => {
    await getFees();
    await setFees();
    await getFees();
})();
