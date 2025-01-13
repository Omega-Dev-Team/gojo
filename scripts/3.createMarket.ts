import { Account, Contract, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import { contractAddresses } from "./utils/contracts";
import { getContractPath } from "./utils/get-contract-addresses";

const contractAddressesPath = getContractPath();

const ETH = contractAddresses['ETH'];
const BTC = contractAddresses['BTC'];
const USDT = contractAddresses['USDT'];
const USDC = contractAddresses['USDC'];

dotenv.config()

async function create_market() {
    const opts = {
        isDeployETHUSDCMarket: true,
        isDeployETHUSDTMarket: false,
    }
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)

    const marketFactoryAddress = contractAddresses['MarketFactory'];
    const compiledMarketFactorySierra = json.parse(fs.readFileSync("./target/dev/satoru_MarketFactory.contract_class.json").toString("ascii"))
    const abi = compiledMarketFactorySierra.abi
    const marketFactoryContract = new Contract(abi, marketFactoryAddress, provider);
    marketFactoryContract.connect(account0)
    const market_type = "market_v1";

    if (opts.isDeployETHUSDCMarket) {
        console.log("Creating ETH-USDC Market...")
        const createETHUSDC = marketFactoryContract.populate("create_market", [
            ETH,
            ETH,
            USDC,
            market_type
        ]);
        const resETHUSDC = await marketFactoryContract.create_market(createETHUSDC.calldata);
        const ETHUSDCMarketToken = (await provider.waitForTransaction(resETHUSDC.transaction_hash) as any).events[0].data[1];

        contractAddresses.ETHUSDCMarketToken = ETHUSDCMarketToken;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (opts.isDeployETHUSDTMarket) {
        console.log("Creating ETH-USDT Market...")
        const createETHUSDT = marketFactoryContract.populate("create_market", [
            ETH,
            ETH,
            USDT,
            market_type
        ]);
        const resETHUSDT = await marketFactoryContract.create_market(createETHUSDT.calldata);
        const ETHUSDTMarketToken = (await provider.waitForTransaction(resETHUSDT.transaction_hash) as any).events[0].data[1];

        contractAddresses.ETHUSDTMarketToken = ETHUSDTMarketToken;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');

    }



    console.log('Markets created ✅\n')
}

create_market()