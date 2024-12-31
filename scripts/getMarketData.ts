import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract, json, cairo, hash, CallData, num } from 'starknet';
import * as dataStoreKeys from "./constants/dataStoreKeys";
import { get_max_pnl_factor } from './utils/data-store';


const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

const classHashesPath = path.join(__dirname, 'constants', 'classHashes.json');
const classHashes = JSON.parse(fs.readFileSync(classHashesPath, 'utf8'));

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
const multicallAddress = contractAddresses['Multicall'];

const compiledReaderSierra = json.parse(fs.readFileSync("./target/dev/satoru_Reader.contract_class.json").toString("ascii"));
const readerContract = new Contract(compiledReaderSierra.abi, readerAddress, provider);

const compiledDataStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_DataStore.contract_class.json").toString("ascii"));
const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider);

async function getMarketInfo() {

    const prices = {
        index_token_price: {
            min: cairo.uint256(3467444862000000n),
            max: cairo.uint256(3467252183196146n),
        },
        long_token_price: {
            min: cairo.uint256(3467444862000000n),
            max: cairo.uint256(3467252183196146n),
        },
        short_token_price: {
            min: cairo.uint256(999830380000000000000000n),
            max: cairo.uint256(999730959810515600000000n),
        },
    };
    const marketAddresses = {
        market_token: marketTokenAddress,
        /// Address of the index token for the market.
        index_token: eth,
        /// Address of the long token for the market.
        long_token: eth,
        /// Address of the short token for the market.
        short_token: usdt,
    }

    try {
        // const marketInfo = await readerContract.get_market_info(
        //     {
        //         contract_address: dataStoreAddress
        //     },
        //     prices,
        //     marketTokenAddress
        // );

        const marketTokenMinPriceForDeposit = await readerContract.get_market_token_price(
            {
                contract_address: dataStoreAddress
            },
            marketAddresses,
            prices.index_token_price,
            prices.long_token_price,
            prices.short_token_price,
            "0x4896bc14d7c67b49131baf26724d3f29032ddd7539a3a8d88324140ea2de9b4",
            false
        );
        console.log("🚀 ~ getMarketInfo ~ marketTokenMinPriceForDeposit:", marketTokenMinPriceForDeposit)
        const marketTokenMaxPrice = await readerContract.get_market_token_price(
            {
                contract_address: dataStoreAddress
            },
            marketAddresses,
            prices.index_token_price,
            prices.long_token_price,
            prices.short_token_price,
            "0x4896bc14d7c67b49131baf26724d3f29032ddd7539a3a8d88324140ea2de9b4",
            true
        );
        console.log("🚀 ~ getMarketInfo ~ marketTokenMaxPrice:", marketTokenMaxPrice, dataStoreKeys.MAX_PNL_FACTOR_FOR_DEPOSITS_KEY)


        const { abi: multicallAbi } = await provider.getClassAt(multicallAddress)

        const multicallContract = new Contract(multicallAbi, multicallAddress, provider);
        const calls = [
            {
                contractAddress: readerContract.address,
                entrypoint: "get_market_token_price",
                calldata: [
                    dataStoreAddress,
                    marketAddresses,
                    prices.index_token_price,
                    prices.long_token_price,
                    prices.short_token_price,
                    dataStoreKeys.MAX_PNL_FACTOR_FOR_WITHDRAWALS_KEY,
                    false
                ]
            },
            {
                contractAddress: readerContract.address,
                entrypoint: "get_market_token_price",
                calldata: [
                    dataStoreAddress,
                    marketAddresses,
                    prices.index_token_price,
                    prices.long_token_price,
                    prices.short_token_price,
                    dataStoreKeys.MAX_PNL_FACTOR_FOR_WITHDRAWALS_KEY,
                    true
                ]
            },
        ]
      
          const results = await multicallContract.aggregate(
            [{
                to: readerContract.address,
                selector: hash.getSelectorFromName("get_market_token_price"),
                calldata: [
                    "2617077082248363474622888832383166249398275504387584680825588467112070904905",
                    "3316154428832334163538131499044040983866191587682184247516817978419454543199",
                    "3044714494559826322742141285906543398537841278671544812382133912971350055969",
                    "2763934918819577073572391515534451252496240860424360260709359908162207270589",
                    "3044714494559826322742141285906543398537841278671544812382133912971350055969",
                    "3340704909589153",
                    "0",
                    "3341240000000000",
                    "0",
                    "3340704909589153",
                    "0",
                    "3341240000000000",
                    "0",
                    "1000090000000000000000000",
                    "0",
                    "1000162000000000000000000",
                    "0",
                    "2052053140496741304857828964158084980053636404363645881438881641220168083892",
                    "0"
                ]
            }]
          );
          [
            "2617077082248363474622888832383166249398275504387584680825588467112070904905",
                    "3316154428832334163538131499044040983866191587682184247516817978419454543199",
                    "3044714494559826322742141285906543398537841278671544812382133912971350055969",
                    "2763934918819577073572391515534451252496240860424360260709359908162207270589",
                    "3044714494559826322742141285906543398537841278671544812382133912971350055969",

                    "2052053140496741304857828964158084980053636404363645881438881641220168083892"
          ].map((key, i) => console.log(num.toHex(key)))
        const callData = new CallData(readerContract.abi);
        let parsedResult0 = callData.parse(calls[0].entrypoint, results['1'][0]);
        console.log("🚀 ~ getMarketInfo ~ parsedResult0:", parsedResult0)

    } catch (error) {
        console.error("Error calling get_market_info:", error);
    }
}


async function getPoolAmount() {
    try {
        let divisor = eth === usdt ? 2n : 1n;
        const POOL_AMOUNT_ETH_KEY = dataStoreKeys.poolAmountKey(marketTokenAddress, eth);
        const poolAmountEth = await dataStoreContract.get_u256(POOL_AMOUNT_ETH_KEY);


        const POOL_AMOUNT_USDT_KEY = dataStoreKeys.poolAmountKey(marketTokenAddress, usdt);
        const poolAmountUsdt = await dataStoreContract.get_u256(POOL_AMOUNT_USDT_KEY);
        console.log("🚀 ~ getPoolAmount ~ poolAmountUsdt:", poolAmountEth, poolAmountUsdt)



    } catch (error) {
        console.error("Error calling get_pool_amount:", error);
        throw error;
    }
}

async function getMaxPnlFactor() {
    const maxPnlFactorWithdrawal = await get_max_pnl_factor(dataStoreKeys.MAX_PNL_FACTOR_FOR_DEPOSITS_KEY, marketTokenAddress, true);
}
(async () => {
    getMarketInfo().catch(console.error);
    getPoolAmount().catch(console.error);
    getMaxPnlFactor()
})();
