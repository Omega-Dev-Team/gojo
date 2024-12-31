import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec, uint256 } from "starknet"
import fs from 'fs'
import path from 'path';
import dotenv from 'dotenv'
import { sleep, tryInvoke } from "./constants/utils"

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

const classHashesPath = path.join(__dirname, 'constants', 'classHashes.json');
const classHashes = JSON.parse(fs.readFileSync(classHashesPath, 'utf8'));

dotenv.config()

async function deploy() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("Deploying contracts...")
    const resp = await provider.getSpecVersion();

    const STRKToken = {
        name: "Starknet Token",
        symbol: "STRK",
        decimals: 18,
        initialSupply: uint256.bnToUint256(1000000000000000000000000000n)
    };

    const maSTRKToken = {
        name: "Magik STRK Token",
        symbol: "maSTRK",
        decimals: 18,
        initialSupply: uint256.bnToUint256(1000000000000000000000000000n)
    };

    const compiledERC20Casm = json.parse(fs.readFileSync("./target/dev/satoru_ERC20.compiled_contract_class.json").toString("ascii"))
    const compiledERC20Sierra = json.parse(fs.readFileSync("./target/dev/satoru_ERC20.contract_class.json").toString("ascii"))
    const erc20Calldata: CallData = new CallData(compiledERC20Sierra.abi)


    // Deploy STRKToken
    const strkTokenConstructor: Calldata = erc20Calldata.compile("constructor", {
        name: STRKToken.name,
        symbol: STRKToken.symbol,
        initial_supply: STRKToken.initialSupply,
        recipient: account0Address
    })

    const strkTokenResponse = await account0.declareAndDeploy({
        contract: compiledERC20Sierra,
        casm: compiledERC20Casm,
        constructorCalldata: strkTokenConstructor,
    })
    console.log("🚀 ~ deploy ~ strkTokenResponse:", strkTokenResponse.deploy.contract_address)
    

    // Deploy maSTRKToken
    const maStrkTokenConstructor: Calldata = erc20Calldata.compile("constructor", {
        name: maSTRKToken.name,
        symbol: maSTRKToken.symbol,
        initial_supply: maSTRKToken.initialSupply,
        recipient: account0Address
    })

    const maStrkTokenResponse = await account0.declareAndDeploy({
        contract: compiledERC20Sierra,
        casm: compiledERC20Casm,
        constructorCalldata: maStrkTokenConstructor,
    })
    console.log("🚀 ~ deploy ~ maStrkTokenResponse:", maStrkTokenResponse.deploy.contract_address)
}

deploy()