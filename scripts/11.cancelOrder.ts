import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { secureHeapUsed } from "crypto";

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

dotenv.config()


// connect provider
const providerUrl = process.env.PROVIDER_URL
const provider = new RpcProvider({ nodeUrl: providerUrl! })
// connect your account. To adapt to your own account :
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
const account0Address: string = process.env.ACCOUNT_PUBLIC as string
const account0 = new Account(provider, account0Address!, privateKey0!)

async function getDataStoreContract() {
    // read abi of DataStore contract
    const { abi: dataStoreAbi } = await provider.getClassAt(contractAddresses['DataStore']);
    if (dataStoreAbi === undefined) { throw new Error("no abi.") };
    const dataStoreContract = new Contract(dataStoreAbi, contractAddresses['DataStore'], provider);
    return dataStoreContract;
}

// Get latest account deposit key
export async function getLatestOrderKey(accountAddress: string) {
    const dataStoreContract = await getDataStoreContract();


    const accountOrderKeys = await dataStoreContract.get_account_order_keys(accountAddress, 0, Number(100));
    return accountOrderKeys[accountOrderKeys.length - 1];
}


async function deploy() {
    let key = await getLatestOrderKey(account0Address);
    console.log("🚀 ~ deploy ~ key:", key)


    const exchangeRouterAddress = contractAddresses['ExchangeRouter'];
    const compiledExchangeRouterSierra = json.parse(fs.readFileSync("./target/dev/satoru_ExchangeRouter.contract_class.json").toString("ascii"))

    const exchangeRouterContract = new Contract(compiledExchangeRouterSierra.abi, exchangeRouterAddress, provider);
    exchangeRouterContract.connect(account0)

    const call = exchangeRouterContract.populate("cancel_order", [
        key,
    ])
    let tx = await account0.execute(call)
    console.log("Cancel order executed: https://sepolia.starkscan.co/tx/" + tx.transaction_hash);
}

deploy()