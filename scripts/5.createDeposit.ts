import { Account, Contract, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { tryInvoke } from "./constants/utils";

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));
const ETH = contractAddresses['ETH'];
const BTC = contractAddresses['BTC'];
const USDT = contractAddresses['USDT'];

dotenv.config()

async function create_market() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)
    let MarketTokenAddress = contractAddresses['ETHUSDTMarketToken'];
    let depositVaultAddress = contractAddresses['DepositVault'];
    let routerAddress = contractAddresses['Router'];
    let exchangeRouterAddress = contractAddresses['ExchangeRouter'];

    let eth = contractAddresses['ETH'];
    let feeToken = contractAddresses['ETH'];
    let usdt = contractAddresses['USDT'];
    let ethDepositedAmount = 1 * 1e18;
    let usdtDepositedAmount = 100 * 1e6;
    const executionFee = 0.055 * 1e18;

    const depositCalls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [
        {
            contractAddress: usdt,
            entrypoint: "approve",
            calldata: [
                routerAddress,
                uint256.bnToUint256(usdtDepositedAmount),
            ]
        },
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: "send_tokens",
            calldata: [
                usdt,
                depositVaultAddress,
                uint256.bnToUint256(usdtDepositedAmount),
            ]
        },
        {
            contractAddress: feeToken,
            entrypoint: "approve",
            calldata: [
                routerAddress,
                uint256.bnToUint256(executionFee),
            ]
        },
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: "send_tokens",
            calldata: [
                feeToken,
                depositVaultAddress,
                uint256.bnToUint256(executionFee),
            ]
        },
        {
            contractAddress: eth,
            entrypoint: "approve",
            calldata: [
                routerAddress,
                uint256.bnToUint256(ethDepositedAmount),
            ]
        },
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: "send_tokens",
            calldata: [
                eth,
                depositVaultAddress,
                uint256.bnToUint256(ethDepositedAmount),
            ]
        },
     
        {
            contractAddress: exchangeRouterAddress,
            entrypoint: 'create_deposit',
            calldata: CallData.compile({
                receiver: account0.address,
                callback_contract: "0x0000000000000000000000000000000000000000000000000000000000000000",
                ui_fee_receiver: "0x0000000000000000000000000000000000000000000000000000000000000000",
                market: MarketTokenAddress,
                initial_long_token: eth,
                initial_short_token: usdt,
                long_token_swap_path: [],
                short_token_swap_path: [],
                min_market_tokens: uint256.bnToUint256(0),
                execution_fee: uint256.bnToUint256(executionFee),
                callback_gas_limit: uint256.bnToUint256(0),
            }),
        }
    ];
    await tryInvoke("Create Deposit", depositCalls);
}

create_market()