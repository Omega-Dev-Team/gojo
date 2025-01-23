import { Account, Contract, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec } from "starknet"
import { expandDecimals, decimalToFloat, tryInvoke } from "./constants/utils";
import { getContractAddresses } from "./utils/get-contract-addresses";
import { account0 } from "./utils/contracts";


const contractAddresses = getContractAddresses();


async function create_order() {
    // connect provider

    const marketTokenAddress = contractAddresses['ETHUSDCMarketToken']
    console.log("🚀 ~ create_order ~ marketTokenAddress:", marketTokenAddress)
    const eth: string = contractAddresses['ETH']
    const usdc: string = contractAddresses['USDC']

    const currentPrice = 3333;
    const initCollateral = 1;
    const leverage = 10;
    const execution_fee = expandDecimals(1, 17).toBigInt();
    const createOrderCalls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [
        {

            contractAddress: eth,
            entrypoint: "approve",
            calldata: [
                contractAddresses['Router'],
                uint256.bnToUint256(execution_fee),
            ]
        },
        {
            contractAddress: contractAddresses['ExchangeRouter'] as string,
            entrypoint: "send_tokens",
            calldata: [eth, contractAddresses['OrderVault'] as string, uint256.bnToUint256(execution_fee)]
        },
        {
            contractAddress: eth,
            entrypoint: "approve",
            calldata: [contractAddresses['Router'] as string, uint256.bnToUint256(expandDecimals(initCollateral, 18).toBigInt())]
        },
        {
            contractAddress: contractAddresses['ExchangeRouter'] as string,
            entrypoint: "send_tokens",
            calldata: [eth, contractAddresses['OrderVault'] as string, uint256.bnToUint256(expandDecimals(initCollateral, 18).toBigInt())]
        },
        {
            contractAddress: contractAddresses['ExchangeRouter'] as string,
            entrypoint: "create_order",
            calldata: [
                account0.address,
                {
                    callback_contract: 0,
                    ui_fee_receiver: 0,
                    market: marketTokenAddress,
                    initial_collateral_token: eth,
                    swap_path: [marketTokenAddress],
                    size_delta_usd: uint256.bnToUint256(decimalToFloat(initCollateral * leverage * currentPrice, 30).toString()),
                    initial_collateral_delta_amount: uint256.bnToUint256(expandDecimals(initCollateral, 18).toString()),
                    trigger_price: uint256.bnToUint256(expandDecimals(currentPrice, 12).toString()),
                    acceptable_price: uint256.bnToUint256(expandDecimals(currentPrice, 12).toString()),
                    execution_fee: uint256.bnToUint256(execution_fee).toString(),
                    callback_gas_limit: uint256.bnToUint256(0),
                    min_output_amount: uint256.bnToUint256(0),
                    order_type: 2,
                    decrease_position_swap_type: 0,
                    is_long: false,
                    referral_code: 0
                },
                "0"
            ]
        }
    ]

    await tryInvoke("Create Order", createOrderCalls);
}

create_order()