import { ec } from "starknet";
import dotenv from 'dotenv'
import { hashSingleString } from "./dataStoreKeys";
import { expandDecimals, decimalToFloat, percentageToFloat,  } from "./../utils/math";
import { SECONDS_PER_YEAR, SECONDS_PER_HOUR } from "./../utils/constants";
import { getContractAddresses } from "../utils/get-contract-addresses";


const contractAddresses = getContractAddresses()

dotenv.config()


const baseMarketConfig = {
  minCollateralFactor: decimalToFloat(1, 2), // 1%

  minCollateralFactorForOpenInterestMultiplierLong: 0,
  minCollateralFactorForOpenInterestMultiplierShort: 0,

  maxLongTokenPoolAmount: expandDecimals(1_000_000_000, 18),
  maxShortTokenPoolAmount: expandDecimals(1_000_000_000, 18),

  maxLongTokenPoolAmountForDeposit: expandDecimals(1_000_000_000, 18),
  maxShortTokenPoolAmountForDeposit: expandDecimals(1_000_000_000, 18),

  maxOpenInterestForLongs: decimalToFloat(1_000_000_000),
  maxOpenInterestForShorts: decimalToFloat(1_000_000_000),

  reserveFactorLongs: decimalToFloat(90, 2), // 95%,= 0.95
  reserveFactorShorts: decimalToFloat(90, 2), // 95%,

  openInterestReserveFactorLongs: decimalToFloat(9, 1), // 80%, // Config % liquidity ETH for user able to LONG, Ex: 80% of 1000 ETH = 800 ETH 
  openInterestReserveFactorShorts: decimalToFloat(8, 1), // 80%, // Config % liquidity USDT for user able to SHORT, Ex: 80% of 1000 USDT = 800 USDT

  maxPnlFactorForTradersLongs: decimalToFloat(8, 1), // 80%
  maxPnlFactorForTradersShorts: decimalToFloat(8, 1), // 80%

  maxPnlFactorForAdlLongs: decimalToFloat(1, 0), // 100%, no ADL under normal operation
  maxPnlFactorForAdlShorts: decimalToFloat(1, 0), // 100%, no ADL under normal operation

  minPnlFactorAfterAdlLongs: decimalToFloat(8, 1), // 80%, no ADL under normal operation
  minPnlFactorAfterAdlShorts: decimalToFloat(8, 1), // 80%, no ADL under normal operation

  maxPnlFactorForDepositsLongs: decimalToFloat(8, 1), // 80%
  maxPnlFactorForDepositsShorts: decimalToFloat(8, 1), // 80%

  maxPnlFactorForWithdrawalsLongs: decimalToFloat(8, 1), // 80%
  maxPnlFactorForWithdrawalsShorts: decimalToFloat(8, 1), // 80%

  positionFeeFactorForPositiveImpact: decimalToFloat(5, 4), // 0.05%
  positionFeeFactorForNegativeImpact: decimalToFloat(7, 4), // 0.07%

  negativePositionImpactFactor: decimalToFloat(1, 7), // 0.00001%
  positivePositionImpactFactor: decimalToFloat(5, 8), // 0.000005%
  positionImpactExponentFactor: decimalToFloat(2, 0), // 2

  negativeMaxPositionImpactFactor: decimalToFloat(1, 2), // 1%
  positiveMaxPositionImpactFactor: decimalToFloat(1, 2), // 1%
  maxPositionImpactFactorForLiquidations: decimalToFloat(1, 2), // 1%

  swapFeeFactorForPositiveImpact: decimalToFloat(5, 4), // 0.05%,
  swapFeeFactorForNegativeImpact: decimalToFloat(7, 4), // 0.07%,

  negativeSwapImpactFactor: decimalToFloat(1, 5), // 0.001%
  positiveSwapImpactFactor: decimalToFloat(5, 6), // 0.0005%
  swapImpactExponentFactor: decimalToFloat(2, 0), // 2

  minCollateralUsd: decimalToFloat(1, 0), // 1 USD
  minPositionSizeUsd: decimalToFloat(1, 0), // 1 USD

  // factor in open interest reserve factor 80%
  borrowingFactorForLongs: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized
  borrowingFactorForShorts: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized

  borrowingExponentFactorForLongs: decimalToFloat(1),
  borrowingExponentFactorForShorts: decimalToFloat(1),

  fundingFactor: decimalToFloat(1,8), // ~63% per year for a 100% skew
  fundingExponentFactor: decimalToFloat(1, 0),

  fundingIncreaseFactorPerSecond: 0,
  fundingDecreaseFactorPerSecond: 0,
  thresholdForStableFunding: 0,
  thresholdForDecreaseFunding: 0,
  minFundingFactorPerSecond: 0,
  maxFundingFactorPerSecond: 0,

  positionImpactPoolDistributionRate: 0,
  minPositionImpactPoolAmount: 0,
  positionImpactPoolAmount: 0,
};

export const markets_config = {
  [contractAddresses['ETHUSDCMarketToken']]: {
    tokens: { indexToken: "ETH", longToken: "ETH", shortToken: "USDC" },
    virtualTokenIdForIndexToken: hashSingleString("PERP:ETH/USD"),
    virtualMarketId: hashSingleString("SPOT:ETH/USD"),

    ...baseMarketConfig,

    maxLongTokenPoolAmount: expandDecimals(90_000_000, 18),
    maxShortTokenPoolAmount: expandDecimals(8_000_000_000, 6),

    maxLongTokenPoolAmountForDeposit: expandDecimals(20_000_000, 18), // Max deposit for each user
    maxShortTokenPoolAmountForDeposit: expandDecimals(100_000_000, 6), // Max deposit for each user

    negativePositionImpactFactor: decimalToFloat(15, 4), // 0.015%
    positivePositionImpactFactor: decimalToFloat(9, 4), // 0.09%

    positionImpactPoolDistributionRate: expandDecimals(256, 41), // ~2.21 ETH/day
    minPositionImpactPoolAmount: expandDecimals(24, 18), // 24 ETH
    positionImpactPoolAmount: expandDecimals(0, 0), // Error: INVALID_POOL_VALUE_FOR_DEPOSIT

    //#region Swap fee config
    swapFeeFactorForPositiveImpact: decimalToFloat(7, 4), // 0.07%,
    swapFeeFactorForNegativeImpact: decimalToFloat(11, 4), // 0.11%, // Buy, Sell Fee
  
    negativeSwapImpactFactor: decimalToFloat(1, 5), // 0.001%
    positiveSwapImpactFactor: decimalToFloat(5, 6), // 0.0005%
    swapImpactExponentFactor: decimalToFloat(15, 1), // 1.5%


    //#region Minimum collateral 
    // minCollateralFactor of 0.01 (1%) when open interest is 50,000,000 USD
    minCollateralFactor: decimalToFloat(1, 2), // 1%
    minCollateralFactorForOpenInterestMultiplierLong: decimalToFloat(5, 10),
    minCollateralFactorForOpenInterestMultiplierShort: decimalToFloat(2, 10),

    minCollateralUsd: decimalToFloat(2, 0), // 2 USD

    reserveFactorLongs: decimalToFloat(1, 0), // 95%,= 0.95, amount of ETH for reserve
    reserveFactorShorts: decimalToFloat(1, 0), // 95%,

    //#region Reserve Factor for Open Interest, số tiền dự trữ của LONG-SHORT Token có thể trade
    openInterestReserveFactorLongs: decimalToFloat(8, 1), // 80%, // Config % liquidity ETH for user able to LONG, Ex: 80% of 1000 ETH = 800 ETH 
    openInterestReserveFactorShorts: decimalToFloat(8, 1), // 80%, // Config % liquidity USDT for user able to SHORT, Ex: 80% of 1000 USDT = 800 USDT

    //#region MAX OI Config in Trade page
    maxOpenInterestForLongs: decimalToFloat(64_000_000),
    maxOpenInterestForShorts: decimalToFloat(70_000_000),

    //#region Funding fee config
    fundingIncreaseFactorPerSecond: decimalToFloat(0), // 0.0000000000008, at least 3.5 hours to reach max funding
    fundingDecreaseFactorPerSecond: decimalToFloat(0), // not applicable if thresholdForDecreaseFunding = 0
    minFundingFactorPerSecond: decimalToFloat(3, 10), // 0.00000003%, 0.000108% per hour, 0.95% per year
    maxFundingFactorPerSecond: decimalToFloat(1, 8), // 0.000001%,  0.0036% per hour, 31.5% per year
    thresholdForStableFunding: percentageToFloat("0%").div(SECONDS_PER_HOUR * 1), // if this config > 0, it will be funding factor instead of fundingFactor
    thresholdForDecreaseFunding: decimalToFloat(0), // 0%

    fundingFactor: percentageToFloat("1%").div(SECONDS_PER_HOUR * 1),
    fundingExponentFactor: decimalToFloat(1),

    //#region Borrowing factor config
    borrowingFactorForLongs: percentageToFloat("1%").div(SECONDS_PER_HOUR * 1), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 10% utilized
    borrowingFactorForShorts: percentageToFloat("1%").div(SECONDS_PER_HOUR * 1), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized
    // borrowingFactorForLongs: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized
    // borrowingFactorForShorts: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized

    borrowingExponentFactorForLongs: decimalToFloat(15, 1), // 1.5
    borrowingExponentFactorForShorts: decimalToFloat(15, 1), // 1.5

    //#region Position fee
    positionFeeFactorForPositiveImpact: decimalToFloat(5, 4), // 0.05% = 0.0005
    positionFeeFactorForNegativeImpact: decimalToFloat(7, 4), // 0.07% = 0.0007
    positionImpactExponentFactor: decimalToFloat(1, 0), // 2
  },
  [contractAddresses['ETHUSDTMarketToken']]: {
    tokens: { indexToken: "ETH", longToken: "ETH", shortToken: "USDT" },
    virtualTokenIdForIndexToken: hashSingleString("PERP:ETH/USD"),
    virtualMarketId: hashSingleString("SPOT:ETH/USD"),

    ...baseMarketConfig,

    maxLongTokenPoolAmount: expandDecimals(90_000_000, 18),
    maxShortTokenPoolAmount: expandDecimals(80_000_000, 6),

    maxLongTokenPoolAmountForDeposit: expandDecimals(20_000_000, 18), // Max deposit for each user
    maxShortTokenPoolAmountForDeposit: expandDecimals(100_000_000, 6), // Max deposit for each user

    negativePositionImpactFactor: decimalToFloat(15, 11), // 0.05% for ~1,600,000 USD of imbalance
    positivePositionImpactFactor: decimalToFloat(9, 11), // 0.05% for ~2,700,000 USD of imbalance

    positionImpactPoolDistributionRate: expandDecimals(256, 41), // ~2.21 ETH/day
    minPositionImpactPoolAmount: expandDecimals(24, 18), // 24 ETH
    positionImpactPoolAmount: expandDecimals(0, 0), // Error: INVALID_POOL_VALUE_FOR_DEPOSIT

    negativeSwapImpactFactor: decimalToFloat(2, 10), // 0.05% for 2,500,000 USD of imbalance
    positiveSwapImpactFactor: decimalToFloat(2, 10), // 0.05% for 2,500,000 USD of imbalance

    //#region Minimum collateral 
    // minCollateralFactor of 0.01 (1%) when open interest is 50,000,000 USD
    minCollateralFactor: decimalToFloat(5, 2), // 1%
    minCollateralFactorForOpenInterestMultiplierLong: decimalToFloat(5, 10),
    minCollateralFactorForOpenInterestMultiplierShort: decimalToFloat(2, 10),
    minCollateralUsd: decimalToFloat(2, 0), // 2 USD

    reserveFactorLongs: decimalToFloat(1, 0), // 95%,= 0.95, amount of ETH for reserve
    reserveFactorShorts: decimalToFloat(1, 0), // 95%,

    //#region Reserve Factor for Open Interest, số tiền dự trữ của LONG-SHORT Token có thể trade
    openInterestReserveFactorLongs: decimalToFloat(8, 1), // 90%, // Config % liquidity ETH for user able to LONG, Ex: 80% of 1000 ETH = 800 ETH 
    openInterestReserveFactorShorts: decimalToFloat(8, 1), // 80%, // Config % liquidity USDT for user able to SHORT, Ex: 80% of 1000 USDT = 800 USDT

    //#region MAX OI Config in Trade page
    maxOpenInterestForLongs: decimalToFloat(64_000_000),
    maxOpenInterestForShorts: decimalToFloat(70_000_000),

    //#region Funding fee config
    fundingIncreaseFactorPerSecond: decimalToFloat(0), // 0.0000000000008, at least 3.5 hours to reach max funding
    fundingDecreaseFactorPerSecond: decimalToFloat(0), // not applicable if thresholdForDecreaseFunding = 0
    minFundingFactorPerSecond: decimalToFloat(3, 10), // 0.00000003%, 0.000108% per hour, 0.95% per year
    maxFundingFactorPerSecond: decimalToFloat(1, 8), // 0.000001%,  0.0036% per hour, 31.5% per year
    thresholdForStableFunding: decimalToFloat(5, 10), // (5, 2) => 5%, (5, 10) => 0.0000000005, cang cao so % per hours cang nho
    thresholdForDecreaseFunding: decimalToFloat(0), // 0%

    fundingFactor: decimalToFloat(1, 10),
    fundingExponentFactor: decimalToFloat(1),

    //#region Borrowing factor config
    borrowingFactorForLongs: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized
    borrowingFactorForShorts: decimalToFloat(625, 11), // 0.00000000625 * 80% = 0.000000005, 0.0000005% / second, 15.77% per year if the pool is 100% utilized

    borrowingExponentFactorForLongs: decimalToFloat(15, 1), // 1.5
    borrowingExponentFactorForShorts: decimalToFloat(15, 1), // 1.5

    //#region Position fee
    positionFeeFactorForPositiveImpact: decimalToFloat(5, 4), // 0.05% = 0.0005
    positionFeeFactorForNegativeImpact: decimalToFloat(7, 4), // 0.07% = 0.0007
    positionImpactExponentFactor: decimalToFloat(1, 0), // 2
    
  }
}