import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json } from 'starknet';
import {  DataStoreABI,LiquidationHandlerABI, OrderHandlerABI, DepositHandlerABI } from "./abis";
import {  getContractAddresses  } from "./get-contract-addresses";

const contractAddresses = getContractAddresses();

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
const depositHandlerAddress = contractAddresses['DepositHandler'];
const withdrawalHandlerAddress = contractAddresses['WithdrawalHandler'];

const compiledReaderSierra = json.parse(fs.readFileSync("./target/dev/satoru_Reader.contract_class.json").toString("ascii"));
const readerContract = new Contract(compiledReaderSierra.abi, readerAddress, provider);

const compiledDataStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_DataStore.contract_class.json").toString("ascii"));
const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider).typedv2(DataStoreABI);
 
const compiledLiquidationHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_LiquidationHandler.contract_class.json").toString("ascii"));
const liquidationHandlerContract = new Contract(compiledLiquidationHandlerSierra.abi, liquidationHandlerAddress, provider).typedv2(LiquidationHandlerABI);

// const compiledOrderHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_OrderHandler.contract_class.json").toString("ascii"));
const orderHandlerContract = new Contract(OrderHandlerABI, orderHandlerAddress, provider);

const depositHandlerContract = new Contract(DepositHandlerABI, depositHandlerAddress, provider);

const withdrawalHandlerContract = new Contract(DepositHandlerABI, withdrawalHandlerAddress, provider);


orderHandlerContract.connect(account0);

export {
    readerContract,
    dataStoreContract,
    liquidationHandlerContract,
    orderHandlerContract,
    depositHandlerContract,
    withdrawalHandlerContract,

    contractAddresses,
    account0,
    provider,
}