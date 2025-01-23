import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
import fs from 'fs'
import path from 'path';
import dotenv from 'dotenv'
import { sleep, tryInvoke } from "./constants/utils"
import { getContractAddresses } from "./utils/get-contract-addresses";

const contractAddresses = getContractAddresses();

dotenv.config()

async function deploy() {
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    // const tedAccountAddress: string = '0x07D0de127e7636bE507Be8f5EaC675aBa819E12E4c2320FF6e55DF693F9085d4';
    const tedAccountAddress: string = '0x048b7fa2d7519EAd304594B4006CbaAEAf3D3CE34B7c7E88a20939d953679521';
    const account0 = new Account(provider, account0Address!, privateKey0!)

    const grantRoleCalls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [account0Address, shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [account0Address, shortString.encodeShortString("MARKET_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [account0Address, shortString.encodeShortString("ORDER_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [account0Address, shortString.encodeShortString("FROZEN_ORDER_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [tedAccountAddress, shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [tedAccountAddress, shortString.encodeShortString("MARKET_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [tedAccountAddress, shortString.encodeShortString("ORDER_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [tedAccountAddress, shortString.encodeShortString("LIQUIDATION_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [tedAccountAddress, shortString.encodeShortString("FROZEN_ORDER_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['MarketFactory'], shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['MarketFactory'], shortString.encodeShortString("MARKET_KEEPER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['OrderHandler'], shortString.encodeShortString("CONTROLLER")]
        },
        
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['DepositHandler'], shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['WithdrawalHandler'], shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['LiquidationHandler'], shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['SwapHandler'], shortString.encodeShortString("CONTROLLER")]
        },
        {
            contractAddress: contractAddresses['RoleStore'],
            entrypoint: "grant_role",
            calldata: [contractAddresses['ExchangeRouter'], shortString.encodeShortString("CONTROLLER")]
        },

    ];
    await tryInvoke("Grant Roles", grantRoleCalls);

    sleep(30);

    const dataStoreAddress = contractAddresses['DataStore'];
    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider)
    dataStoreContract.connect(account0);
    const dataCall = dataStoreContract.populate(
        "set_address",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("FEE_TOKEN"))]), contractAddresses['ETH']])
    const setAddressTx = await dataStoreContract.set_address(dataCall.calldata)
    await provider.waitForTransaction(setAddressTx.transaction_hash)
    const dataCall2 = dataStoreContract.populate(
        "set_u256",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("MAX_SWAP_PATH_LENGTH"))]), 5n])
    const setAddressTx2 = await dataStoreContract.set_u256(dataCall2.calldata)
    await provider.waitForTransaction(setAddressTx2.transaction_hash)

    const dataCall3 = dataStoreContract.populate(
        "set_u256",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("MAX_ORACLE_PRICE_AGE"))]), 1000000000000n])
    const setAddressTx3 = await dataStoreContract.set_u256(dataCall3.calldata)
    await provider.waitForTransaction(setAddressTx2.transaction_hash)
}

deploy()