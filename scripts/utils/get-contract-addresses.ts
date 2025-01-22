import fs from "fs";
import path from "path";
import { ContractAddresses } from "./types";
import dotenv from 'dotenv';
dotenv.config();
export const getClassHashPath = () => {
    const devEnv = process.env.ENV as string;
    if (devEnv === "development") {
        return path.join(__dirname, '../constants', 'classHashes-development.json');
    }
    if(devEnv === "production") { 
        return path.join(__dirname, '../constants', 'classHashes-production.json');
    }
    throw new Error("Invalid environment");
};

export const getContractPath = () => {
    const devEnv = process.env.ENV as string;
    if (devEnv === "development") {
        return path.join(__dirname, '../constants', 'contractAddresses-development.json');
    }
    if(devEnv === "production") { 
        return path.join(__dirname, '../constants', 'contractAddresses-production.json');
    }
    throw new Error("Invalid environment");
};

export const getContractAddresses = (): ContractAddresses => {
    const contractAddresses = JSON.parse(fs.readFileSync(getContractPath(), 'utf8'));
    return contractAddresses;
};