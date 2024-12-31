import { Account, AllowArray, Call, RpcProvider } from "starknet";
import dotenv from 'dotenv'
import { ethers } from "ethers";
dotenv.config()
const providerUrl = process.env.PROVIDER_URL
const provider = new RpcProvider({ nodeUrl: providerUrl! })
const account0Address: string = process.env.ACCOUNT_PUBLIC as string
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
const account = new Account(provider, account0Address!, privateKey0!)


export function bigNumberify(n: any) {
   return ethers.BigNumber.from(n);
 }
 
 export function expandDecimals(n: any, decimals: any) {
   return bigNumberify(n).mul(bigNumberify(10).pow(decimals));
 }
 
 export function decimalToFloat(value: any, decimals = 0) {
   return expandDecimals(value, 30 - decimals);
 }
 
 export function exponentToFloat(value: any) {
   if (!value.includes("e")) {
     throw new Error("Invalid exponent input");
   }
 
   const components = value.split("e");
   if (components.length !== 2) {
     throw new Error("Invalid exponent input");
   }
 
   const exponent = parseInt(components[1]);
   if (isNaN(exponent)) {
     throw new Error("Invalid exponent");
   }
 
   return ethers.utils.parseUnits(components[0], 30 + exponent);
 }
 
 export function percentageToFloat(value: any) {
   if (value[value.length - 1] !== "%") {
     throw new Error("Invalid percentage input");
   }
 
   const trimmedValue = value.substring(0, value.length - 1);
 
   return ethers.utils.parseUnits(trimmedValue, 28);
 }
 

export async function tryInvoke(functionName: string, calldata: Call[]) {
   try {
      console.log(`\x1b[32m🚀 INVOKE ${functionName}...`);
      const txCall = await account.execute(calldata);
      console.log(`\x1b[32m✅ https://sepolia.starkscan.co/tx/` + txCall.transaction_hash);
      await provider.waitForTransaction(txCall.transaction_hash);
   } catch (e) {
      console.log(`\x1b[31m❌ ERROR ${functionName}: \n`, e);
   } finally {
      // Reset the console color
      console.log('\x1b[0m');
   }
}

export const sleep = (seconds: number) => {
   return new Promise(resolve => setTimeout(resolve, seconds * 1000));
}