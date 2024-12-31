import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";

import { contractAddresses, dataStoreContract } from './utils/contracts';
import { decimalToFloat, tryInvoke } from './constants/utils';


dotenv.config();

const execution_fee_config = {
    max_callback_gas_limit: 0n,
    single_swap_gas_limit: 10_000n,
    deposit_single_gas_limit: 10_000n,
    deposit_double_gas_limit: 20_000n,
    withdrawal_single_gas_limit: 10_000n,
    withdrawal_double_gas_limit: 20_000n,

    est_base_gas_limit: 5000n,
    est_multiplier_factor: decimalToFloat(1).toBigInt(),
    exec_base_gas_fee_amount: 5000n,
    exec_multiplier_factor: decimalToFloat(1).toBigInt(),
}

type DataTable = {
    key: string;
    value: string | bigint;
};

async function getFees() {
    //#region Read Execution Fees
    const data: DataTable[] = [];
    const fee_token = await dataStoreContract.get_address(dataStoreKeys.FEE_TOKEN);
    data.push({ key: 'fee_token', value: num.toHexString(fee_token) });

    const max_callback_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.MAX_CALLBACK_GAS_LIMIT);
    data.push({ key: 'max_callback_gas_limit', value: BigInt(max_callback_gas_limit.toString()) });

    const single_swap_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.SINGLE_SWAP_GAS_LIMIT_KEY);
    data.push({ key: 'single_swap_gas_limit', value: BigInt(single_swap_gas_limit.toString()) });

    // short or long token
    const deposit_single_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.depositGasLimitKey(true));
    data.push({ key: 'deposit_single_gas_limit', value: BigInt(deposit_single_gas_limit.toString()) });

    // both short and long token
    const deposit_double_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.depositGasLimitKey(false));
    data.push({ key: 'deposit_double_gas_limit', value: BigInt(deposit_double_gas_limit.toString()) });

    // short or long token
    const withdrawal_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.withdrawalGasLimitKey());
    data.push({ key: 'withdrawal_gas_limit', value: BigInt(withdrawal_gas_limit.toString()) });




    let est_base_gas_limit = await dataStoreContract.get_u256(dataStoreKeys.ESTIMATED_GAS_FEE_BASE_AMOUNT);
    let est_multiplier_factor = await dataStoreContract.get_u256(dataStoreKeys.ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR);
    data.push({ key: 'est_base_gas_limit', value: BigInt(est_base_gas_limit.toString()) });
    data.push({ key: 'est_multiplier_factor', value: BigInt(est_multiplier_factor.toString()) });


    let exec_base_gas_fee_amount = await dataStoreContract.get_u256(dataStoreKeys.EXEC_GAS_FEE_BASE_AMT_KEY);
    let exec_multiplier_factor = await dataStoreContract.get_u256(dataStoreKeys.EXEC_GAS_FEE_MULT_FACT_KEY);
    data.push({ key: 'exec_base_gas_fee_amount', value: BigInt(exec_base_gas_fee_amount.toString()) });
    data.push({ key: 'exec_multiplier_factor', value: BigInt(exec_multiplier_factor.toString()) });

    console.table(data);

    //#endregion
}

async function setFees() {
    //#region Set Execution Fees
    const calls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [];
    const datastoreAddress = dataStoreContract.address;
    calls.push(
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.MAX_CALLBACK_GAS_LIMIT, execution_fee_config.max_callback_gas_limit, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.SINGLE_SWAP_GAS_LIMIT_KEY, execution_fee_config.single_swap_gas_limit, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.depositGasLimitKey(true), execution_fee_config.deposit_single_gas_limit, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.depositGasLimitKey(false), execution_fee_config.deposit_double_gas_limit, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.ESTIMATED_GAS_FEE_BASE_AMOUNT, execution_fee_config.est_base_gas_limit, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR, execution_fee_config.est_multiplier_factor, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.EXEC_GAS_FEE_BASE_AMT_KEY, execution_fee_config.exec_base_gas_fee_amount, "0"],
        },
        {
            contractAddress: datastoreAddress,
            entrypoint: 'set_u256',
            calldata: [dataStoreKeys.EXEC_GAS_FEE_MULT_FACT_KEY, execution_fee_config.exec_multiplier_factor, "0"],
        },
    )
    await tryInvoke(`Config execution fee`, calls);


    //#endregion
}


(async () => {
    await setFees();
    await getFees();
})();
