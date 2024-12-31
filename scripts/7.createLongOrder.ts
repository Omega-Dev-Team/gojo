import { Account, Contract, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path';
import { tryInvoke } from "./constants/utils";
import exp from "constants";
import { decimalToFloat, expandDecimals } from "./constants/market-config-data";

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

dotenv.config()

async function create_order() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const marketTokenAddress = contractAddresses['ETHUSDTMarketToken']
    console.log("🚀 ~ create_order ~ marketTokenAddress:", marketTokenAddress)
    const eth: string = contractAddresses['ETH']
    const usdt: string = contractAddresses['USDT']
    const account0 = new Account(provider, account0Address!, privateKey0!)
    const currentPrice = 3800;
    const initCollateral = 0.005;
    const leverage = 10;
    const createOrderCalls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [
        {
            contractAddress: eth,
            entrypoint: "transfer",
            calldata: [contractAddresses['OrderVault'] as string, uint256.bnToUint256(expandDecimals(initCollateral, 18).toBigInt())]
        },
        {
            contractAddress: contractAddresses['OrderHandler'] as string,
            entrypoint: "create_order",
            calldata: [
                account0.address,
                {
                    receiver: account0.address,
                    callback_contract: 0,
                    ui_fee_receiver: 0,
                    market: marketTokenAddress,
                    initial_collateral_token: eth,
                    swap_path: [marketTokenAddress],
                    size_delta_usd: uint256.bnToUint256(decimalToFloat(initCollateral * leverage * currentPrice, 30).toString()),
                    initial_collateral_delta_amount: uint256.bnToUint256(expandDecimals(initCollateral, 18).toString()),
                    trigger_price: uint256.bnToUint256(expandDecimals(currentPrice, 12).toString()),
                    acceptable_price: uint256.bnToUint256(expandDecimals(currentPrice, 12).toString()),
                    execution_fee: uint256.bnToUint256(0),
                    callback_gas_limit: uint256.bnToUint256(0),
                    min_output_amount: uint256.bnToUint256(0),
                    order_type: 2,
                    decrease_position_swap_type: 0,
                    is_long: false,
                    referral_code: 0
                }
            ]
        }
    ]

    await tryInvoke("Create Order", createOrderCalls);
}

create_order()