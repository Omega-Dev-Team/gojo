import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { RpcProvider, Account, Contract } from 'starknet';
import { sleep, tryInvoke } from "./constants/utils";

const contractAddressesPath = path.join(__dirname, 'constants', 'contractAddresses.json');
const contractAddresses = JSON.parse(fs.readFileSync(contractAddressesPath, 'utf8'));

const classHashesPath = path.join(__dirname, 'constants', 'classHashes.json');
const classHashes = JSON.parse(fs.readFileSync(classHashesPath, 'utf8'));

dotenv.config();

async function deploy() {
    // Connect provider
    const providerUrl = process.env.PROVIDER_URL;
    const provider = new RpcProvider({ nodeUrl: providerUrl! });

    // Connect your account. To adapt to your own account:
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string;
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string;
    const account0 = new Account(provider, account0Address!, privateKey0!);

    // Define the contract address and the storage slot you want to query
    const contractAddress = "0x046072f8542b7a2ddf7f6e37062cef2d2c69053aa641cb909e3520853ebd1f05"
    const storageSlot = '0x050de0025a030d5e59f15fba429a3e1a3b56ae913d296b5ad7af69a5c6fd0b81'; // Replace with the actual storage slot you want to query

    // Get the storage slot value
    const storageValue = await provider.getStorageAt(contractAddress, storageSlot);
    console.log(`Storage value at slot ${storageSlot}:`, storageValue);
}

deploy().catch(console.error);