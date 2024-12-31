import { Account, UINT_256_MAX, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec, cairo } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { tryInvoke } from "./constants/utils";

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));
const eth = contractAddresses['ETH'];
const btc = contractAddresses['BTC'];
const usdt = contractAddresses['USDT'];
const zeroAddress = contractAddresses['ZeroAddress'];

dotenv.config()

async function create_withdrawal() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)
    let MarketTokenAddress = contractAddresses['ETHUSDTMarketToken'];
    let withdrawalVaultAddress = contractAddresses['WithdrawalVault'];
    let routerAddress = contractAddresses['Router'];
    let exchangeRouterAddress = contractAddresses['ExchangeRouter'];

    const marketAmount =  uint256.bnToUint256(0.25 * 1e18);
    const executionFee =  uint256.bnToUint256(0n);

    const withdrawalCaldatas: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [
       
        {
            contractAddress: MarketTokenAddress,
            entrypoint: "approve",
            calldata: [
                routerAddress,
                marketAmount
            ]
        },
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: "send_tokens",
            calldata: [
                MarketTokenAddress,
                withdrawalVaultAddress,
                marketAmount,
            ],
        },
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: 'create_withdrawal',
            calldata: CallData.compile({
                receiver: account0.address,
                callback_contract: zeroAddress,
                ui_fee_receiver: zeroAddress,
                market: MarketTokenAddress,
                long_token_swap_path: [],
                short_token_swap_path: [],
                min_long_token_amount: uint256.bnToUint256(0),
                min_short_token_amount: uint256.bnToUint256(0),
                execution_fee: executionFee,
                callback_gas_limit: uint256.bnToUint256(0),
            }),
        }
    ];
    await tryInvoke("Create Withdrawal", withdrawalCaldatas);
}

create_withdrawal()