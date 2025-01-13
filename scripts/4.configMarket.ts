import { num } from "starknet";
import * as dataStoreKeys from "./constants/dataStoreKeys";
import { markets_config } from "./constants/market-config-data";
import { tryInvoke } from "./constants/utils";
import { getContractAddresses } from "./utils/get-contract-addresses";
import { dataStoreContract, readerContract } from "./utils/contracts";


const contractAddresses = getContractAddresses();
console.log("🚀 ~ contractAddresses:", contractAddresses)



/// Create a new market.
export async function configMarket(marketName: string) {
   const dataStore = dataStoreContract;
   const reader = readerContract;
   const market = contractAddresses[marketName as keyof typeof contractAddresses];
   if(!market) { 
      throw new Error(`Market ${marketName} not found in contract`);
   }

   const tokensInMarket = await reader.functions.get_market({
      contract_address: dataStore.address
   }, market);

   const index_token = num.toHex(tokensInMarket.index_token);
   console.log("🚀 ~ configMarket ~ index_token:", index_token)
   const long_token = num.toHex(tokensInMarket.long_token);
   const short_token = num.toHex(tokensInMarket.short_token);

   const configData = markets_config[market];

   const configMarketCalls: Array<{ contractAddress: string, entrypoint: string, calldata: any[] }> = [];

   const virtualTokenIdForIndexTokenKey = dataStoreKeys.virtualTokenIdKey(index_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_felt252",
      calldata: [virtualTokenIdForIndexTokenKey, configData.virtualTokenIdForIndexToken]
   });
   

   const virtualTokenIdForShortTokenKey = dataStoreKeys.virtualTokenIdKey(short_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_felt252",
      calldata: [virtualTokenIdForShortTokenKey, configData.virtualTokenIdForIndexToken]
   });

   const virtualTokenIdForMarketTokenKey = dataStoreKeys.virtualMarketIdKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_felt252",
      calldata: [virtualTokenIdForMarketTokenKey, configData.virtualMarketId]
   });

   // positionImpactPoolAmount
   const positionImpactPoolAmountKey = dataStoreKeys.positionImpactPoolAmountKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positionImpactPoolAmountKey, configData.positionImpactPoolAmount.toBigInt(), "0"]
   });

   // minPositionImpactPoolAmount
   const minPositionImpactPoolAmountKey = dataStoreKeys.minPositionImpactPoolAmountKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minPositionImpactPoolAmountKey, configData.minPositionImpactPoolAmount.toBigInt(), "0"]
   });

   // // positionImpactPoolDistributionRate
   // const minPositionImpactPoolAmountRateCalls: Call[] = []
   // const positionImpactPoolDistributionRateKey = dataStoreKeys.positionImpactPoolDistributionRateKey(market);
   // minPositionImpactPoolAmountRateCalls.push({
   //    contractAddress: dataStore.address,
   //    entrypoint: "set_u256",
   //    calldata: [positionImpactPoolDistributionRateKey, configData.positionImpactPoolDistributionRate.toBigInt(), "0"]
   // });
   // await tryInvoke("minPositionImpactPoolAmountRateCalls", minPositionImpactPoolAmountRateCalls);

   // maxLongTokenPoolAmount
   const maxLongTokenPoolAmountKey = dataStoreKeys.maxPoolAmountKey(market, long_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxLongTokenPoolAmountKey, configData.maxLongTokenPoolAmount.toBigInt(), "0"]
   });

   // maxShortTokenPoolAmount
   const maxShortTokenPoolAmountKey = dataStoreKeys.maxPoolAmountKey(market, short_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxShortTokenPoolAmountKey, configData.maxShortTokenPoolAmount.toBigInt(), "0"]
   });

   // maxLongTokenPoolAmountForDeposit => maxPoolAmountForDepositKey()
   const maxLongTokenPoolAmountForDepositKey = dataStoreKeys.maxPoolAmountForDepositKey(market, long_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxLongTokenPoolAmountForDepositKey, configData.maxLongTokenPoolAmountForDeposit.toBigInt(), "0"]
   });
   // maxShortTokenPoolAmountForDeposit => maxPoolAmountForDepositKey()
   const maxShortTokenPoolAmountForDepositKey = dataStoreKeys.maxPoolAmountForDepositKey(market, short_token);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxShortTokenPoolAmountForDepositKey, configData.maxShortTokenPoolAmountForDeposit.toBigInt(), "0"]
   });

   // negativePositionImpactFactor
   const negativePositionImpactFactorKey = dataStoreKeys.positionImpactFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [negativePositionImpactFactorKey, configData.negativePositionImpactFactor.toBigInt(), "0"]
   });

   // positivePositionImpactFactor
   const positivePositionImpactFactorKey = dataStoreKeys.positionImpactFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positivePositionImpactFactorKey, configData.positivePositionImpactFactor.toBigInt(), "0"]
   });

   // positionImpactExponentFactorKey
   const positionImpactExponentFactorKey = dataStoreKeys.positionImpactExponentFactorKey(market);
   console.log("🚀 ~ configMarket ~ positionImpactExponentFactorKey:", positionImpactExponentFactorKey)
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positionImpactExponentFactorKey, configData.positionImpactExponentFactor.toBigInt(), "0"]
   });


   const negativePositionFeeFactorKey = dataStoreKeys.positionFeeFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [negativePositionFeeFactorKey, configData.positionFeeFactorForNegativeImpact.toBigInt(), "0"]
   });


   const positivePositionFeeFactorKey = dataStoreKeys.positionFeeFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positivePositionFeeFactorKey, configData.positionFeeFactorForPositiveImpact.toBigInt(), "0"]
   });

   // minCollateralFactorForOpenInterestMultiplierShort
   const minCollateralFactorKey = dataStoreKeys.minCollateralFactorKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minCollateralFactorKey, configData.minCollateralFactor.toBigInt(), "0"]
   });

   // minCollateralFactorForOpenInterestMultiplierLong
   const minCollateralFactorForOpenInterestMultiplierLongKey = dataStoreKeys.minCollateralFactorForOpenInterest(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minCollateralFactorForOpenInterestMultiplierLongKey, configData.minCollateralFactorForOpenInterestMultiplierLong.toBigInt(), "0"]
   });

   // minCollateralFactorForOpenInterestMultiplierShort
   const minCollateralFactorForOpenInterestMultiplierShortKey = dataStoreKeys.minCollateralFactorForOpenInterest(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minCollateralFactorForOpenInterestMultiplierShortKey, configData.minCollateralFactorForOpenInterestMultiplierShort.toBigInt(), "0"]
   });

   // negativeSwapImpactFactor
   const negativeSwapFeeFactorKey = dataStoreKeys.swapFeeFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [negativeSwapFeeFactorKey, configData.swapFeeFactorForNegativeImpact.toBigInt(), "0"]
   });

   // positiveSwapImpactFactor
   const positiveSwapFeeFactorKey = dataStoreKeys.swapImpactFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positiveSwapFeeFactorKey, configData.swapFeeFactorForPositiveImpact.toBigInt(), "0"]
   });

   // negativeSwapImpactFactor
   const negativeSwapImpactFactorKey = dataStoreKeys.swapImpactFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [negativeSwapImpactFactorKey, configData.negativeSwapImpactFactor.toBigInt(), "0"]
   });

   // positiveSwapImpactFactor
   const positiveSwapImpactFactorKey = dataStoreKeys.swapImpactFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positiveSwapImpactFactorKey, configData.positiveSwapImpactFactor.toBigInt(), "0"]
   });

   // positiveSwapImpactFactor
   const swapImpactExponentFactorKey = dataStoreKeys.swapImpactExponentFactorKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [swapImpactExponentFactorKey, configData.swapImpactExponentFactor.toBigInt(), "0"]
   });

   // maxOpenInterestForLongs
   const maxOpenInterestForLongsKey = dataStoreKeys.maxOpenInterestKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxOpenInterestForLongsKey, configData.maxOpenInterestForLongs.toBigInt(), "0"]
   });

   // maxOpenInterestForShorts
   const maxOpenInterestForShortsKey = dataStoreKeys.maxOpenInterestKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxOpenInterestForShortsKey, configData.maxOpenInterestForShorts.toBigInt(), "0"]
   });

   // fundingIncreaseFactorPerSecond
   const fundingIncreaseFactorPerSecondKey = dataStoreKeys.fundingIncreaseFactorPerSecondKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [fundingIncreaseFactorPerSecondKey, configData.fundingIncreaseFactorPerSecond.toBigInt(), "0"]
   });

   // fundingDecreaseFactorPerSecond
   const fundingDecreaseFactorPerSecondKey = dataStoreKeys.fundingDecreaseFactorPerSecondKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [fundingDecreaseFactorPerSecondKey, configData.fundingDecreaseFactorPerSecond.toBigInt(), "0"]
   });

   // minFundingFactorPerSecond
   const minFundingFactorPerSecondKey = dataStoreKeys.minFundingFactorPerSecondKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minFundingFactorPerSecondKey, configData.minFundingFactorPerSecond.toBigInt(), "0"]
   });

   // maxFundingFactorPerSecond
   const maxFundingFactorPerSecondKey = dataStoreKeys.maxFundingFactorPerSecondKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxFundingFactorPerSecondKey, configData.maxFundingFactorPerSecond.toBigInt(), "0"]
   });

   // thresholdForStableFunding
   const thresholdForStableFundingKey = dataStoreKeys.thresholdForStableFundingKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [thresholdForStableFundingKey, configData.thresholdForStableFunding.toBigInt(), "0"]
   });

   // thresholdForDecreaseFunding
   const thresholdForDecreaseFundingKey = dataStoreKeys.thresholdForDecreaseFundingKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [thresholdForDecreaseFundingKey, configData.thresholdForDecreaseFunding.toBigInt(), "0"]
   });

   const fundingFactorKey = dataStoreKeys.fundingFactorKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [fundingFactorKey, configData.fundingFactor.toBigInt(), "0"]
   });

   const fundingExponentFactorKey = dataStoreKeys.fundingExponentFactorKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [fundingExponentFactorKey, configData.fundingExponentFactor.toBigInt(), "0"]
   });

   // borrowingFactorForLongs
   const borrowingFactorForLongsKey = dataStoreKeys.borrowingFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [borrowingFactorForLongsKey, configData.borrowingFactorForLongs.toBigInt(), "0"]
   });
   // borrowingFactorForShorts
   const borrowingFactorForShortsKey = dataStoreKeys.borrowingFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [borrowingFactorForShortsKey, configData.borrowingFactorForShorts.toBigInt(), "0"]
   });

   // borrowingExponentFactorForLongs
   const borrowingExponentFactorForLongsKey = dataStoreKeys.borrowingExponentFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [borrowingExponentFactorForLongsKey, configData.borrowingExponentFactorForLongs.toBigInt(), "0"]
   });
   // borrowingExponentFactorForShorts
   const borrowingExponentFactorForShortsKey = dataStoreKeys.borrowingExponentFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [borrowingExponentFactorForShortsKey, configData.borrowingExponentFactorForShorts.toBigInt(), "0"]
   });

   // reserveFactorLongs
   const reserveFactorLongsKey = dataStoreKeys.reserveFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [reserveFactorLongsKey, configData.reserveFactorLongs.toBigInt(), "0"]
   });

   // reserveFactorShorts
   const reserveFactorShortsKey = dataStoreKeys.reserveFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [reserveFactorShortsKey, configData.reserveFactorShorts.toBigInt(), "0"]
   });

   // openInterestReserveFactorLongs
   const openInterestReserveFactorLongsKey = dataStoreKeys.openInterestReserveFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [openInterestReserveFactorLongsKey, configData.openInterestReserveFactorLongs.toBigInt(), "0"]
   });

   // openInterestReserveFactorShorts
   const openInterestReserveFactorShortsKey = dataStoreKeys.openInterestReserveFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [openInterestReserveFactorShortsKey, configData.openInterestReserveFactorShorts.toBigInt(), "0"]
   });

   // maxPnlFactorForTradersLongs
   const maxPnlFactorForTradersLongsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_TRADERS_KEY, market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForTradersLongsKey, configData.maxPnlFactorForTradersLongs.toBigInt(), "0"]
   });

   // maxPnlFactorForTradersShorts
   const maxPnlFactorForTradersShortsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_TRADERS_KEY, market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForTradersShortsKey, configData.maxPnlFactorForTradersShorts.toBigInt(), "0"]
   });

   // maxPnlFactorForAdlLongs
   const maxPnlFactorForAdlLongsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_ADL, market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForAdlLongsKey, configData.maxPnlFactorForAdlLongs.toBigInt(), "0"]
   });

   // maxPnlFactorForAdlShorts
   const maxPnlFactorForAdlShortsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_ADL, market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForAdlShortsKey, configData.maxPnlFactorForAdlShorts.toBigInt(), "0"]
   });

   // minPnlFactorAfterAdlLongs
   const minPnlFactorAfterAdlLongsKey = dataStoreKeys.minPnlFactorAfterAdl(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minPnlFactorAfterAdlLongsKey, configData.minPnlFactorAfterAdlLongs.toBigInt(), "0"]
   });

   // minPnlFactorAfterAdlShorts
   const minPnlFactorAfterAdlShortsKey = dataStoreKeys.minPnlFactorAfterAdl(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minPnlFactorAfterAdlShortsKey, configData.minPnlFactorAfterAdlShorts.toBigInt(), "0"]
   });

   // maxPnlFactorForDepositsLongs
   const maxPnlFactorForDepositsLongsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_DEPOSITS_KEY, market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForDepositsLongsKey, configData.maxPnlFactorForDepositsLongs.toBigInt(), "0"]
   });

   // maxPnlFactorForDepositsShorts
   const maxPnlFactorForDepositsShortsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_DEPOSITS_KEY, market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForDepositsShortsKey, configData.maxPnlFactorForDepositsShorts.toBigInt(), "0"]
   });

   // maxPnlFactorForWithdrawalsLongs
   const maxPnlFactorForWithdrawalsLongsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_WITHDRAWALS_KEY, market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForWithdrawalsLongsKey, configData.maxPnlFactorForWithdrawalsLongs.toBigInt(), "0"]
   });

   // maxPnlFactorForWithdrawalsShorts
   const maxPnlFactorForWithdrawalsShortsKey = dataStoreKeys.maxPnlFactorKey(dataStoreKeys.MAX_PNL_FACTOR_FOR_WITHDRAWALS_KEY, market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPnlFactorForWithdrawalsShortsKey, configData.maxPnlFactorForWithdrawalsShorts.toBigInt(), "0"]
   });

   // positiveMaxPositionImpactFactor
   const positiveMaxPositionImpactFactorKey = dataStoreKeys.maxPositionImpactFactorKey(market, true);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [positiveMaxPositionImpactFactorKey, configData.positiveMaxPositionImpactFactor.toBigInt(), "0"]
   });

   // negativeMaxPositionImpactFactor
   const negativeMaxPositionImpactFactorKey = dataStoreKeys.maxPositionImpactFactorKey(market, false);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [negativeMaxPositionImpactFactorKey, configData.negativeMaxPositionImpactFactor.toBigInt(), "0"]
   });

   // maxPositionImpactFactorForLiquidations
   const maxPositionImpactFactorForLiquidationsKey = dataStoreKeys.maxPositionImpactFactorForLiquidationsKey(market);
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [maxPositionImpactFactorForLiquidationsKey, configData.maxPositionImpactFactorForLiquidations.toBigInt(), "0"]
   });



   // minCollateralUsd
   const minCollateralUsdKey = dataStoreKeys.MIN_COLLATERAL_USD_KEY;
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minCollateralUsdKey, configData.minCollateralUsd.toBigInt(), "0"]
   });


   // minPositionSizeUsd
   const minPositionSizeUsdKey = dataStoreKeys.MIN_POSITION_SIZE_USD_KEY;
   configMarketCalls.push({
      contractAddress: dataStore.address,
      entrypoint: "set_u256",
      calldata: [minPositionSizeUsdKey, configData.minPositionSizeUsd.toBigInt(), "0"]
   });

   await tryInvoke(`config ${marketName}`, configMarketCalls);
}

(async () => {
   // await configMarket('ETHUSDTMarketToken');
   await configMarket('ETHUSDCMarketToken');
})()