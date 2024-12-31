import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo } from 'starknet';
import {  DataStoreABI,LiquidationHandlerABI, OrderHandlerABI } from "./abis"

const contractAddressesPath = path.join(__dirname, '../constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));


dotenv.config();

// Connect provider
const providerUrl = process.env.PROVIDER_URL;
const provider = new RpcProvider({ nodeUrl: providerUrl! });

// Connect your account. To adapt to your own account:
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string;
const account0Address: string = process.env.ACCOUNT_PUBLIC as string;
const account0 = new Account(provider, account0Address!, privateKey0!);

const marketTokenAddress = contractAddresses['ETHUSDTMarketToken'];
const eth: string = contractAddresses['ETH'];
const usdt: string = contractAddresses['USDT'];
const readerAddress = contractAddresses['Reader'];
const dataStoreAddress = contractAddresses['DataStore'];
const liquidationHandlerAddress = contractAddresses['LiquidationHandler'];
const orderHandlerAddress = contractAddresses['OrderHandler'];

const compiledReaderSierra = json.parse(fs.readFileSync("./target/dev/satoru_Reader.contract_class.json").toString("ascii"));
const readerContract = new Contract(compiledReaderSierra.abi, readerAddress, provider);

// const compiledDataStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_DataStore.contract_class.json").toString("ascii"));
const dataStoreContract = new Contract(DataStoreABI, dataStoreAddress, provider).typedv2(DataStoreABI);
 
//const compiledLiquidationHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_LiquidationHandler.contract_class.json").toString("ascii"));
const liquidationHandlerContract = new Contract(LiquidationHandlerABI, liquidationHandlerAddress, provider).typedv2(LiquidationHandlerABI);

// const compiledOrderHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_OrderHandler.contract_class.json").toString("ascii"));
const orderHandlerContract = new Contract(OrderHandlerABI, orderHandlerAddress, provider)

orderHandlerContract.connect(account0);

export {
    readerContract,
    dataStoreContract,
    liquidationHandlerContract,
    orderHandlerContract,

    contractAddresses,
    account0,
    provider,
}