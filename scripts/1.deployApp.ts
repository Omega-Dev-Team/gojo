import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
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

    if (!contractAddresses.RoleStore) {
        const compiledRoleStoreCasm = json.parse(fs.readFileSync("./target/dev/satoru_RoleStore.compiled_contract_class.json").toString("ascii"))
        const compiledRoleStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_RoleStore.contract_class.json").toString("ascii"))
        const roleStoreCallData: CallData = new CallData(compiledRoleStoreSierra.abi)
        const roleStoreConstructor: Calldata = roleStoreCallData.compile("constructor", { admin: account0.address })
        const deployRoleStoreResponse = await account0.declareAndDeploy({
            contract: compiledRoleStoreSierra,
            casm: compiledRoleStoreCasm,
            constructorCalldata: roleStoreConstructor
        })

        contractAddresses.RoleStore = deployRoleStoreResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }
    if (!contractAddresses.DataStore) {

        const compiledDataStoreCasm = json.parse(fs.readFileSync("./target/dev/satoru_DataStore.compiled_contract_class.json").toString("ascii"))
        const compiledDataStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_DataStore.contract_class.json").toString("ascii"))
        const dataStoreCallData: CallData = new CallData(compiledDataStoreSierra.abi)
        const dataStoreConstructor: Calldata = dataStoreCallData.compile("constructor", {
            role_store_address: contractAddresses.RoleStore
        })
        const deployDataStoreResponse = await account0.declareAndDeploy({
            contract: compiledDataStoreSierra,
            casm: compiledDataStoreCasm,
            constructorCalldata: dataStoreConstructor,
        })

        contractAddresses.DataStore = deployDataStoreResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }
    if (!contractAddresses.EventEmitter) {
        const compiledEventEmitterCasm = json.parse(fs.readFileSync("./target/dev/satoru_EventEmitter.compiled_contract_class.json").toString("ascii"))
        const compiledEventEmitterSierra = json.parse(fs.readFileSync("./target/dev/satoru_EventEmitter.contract_class.json").toString("ascii"))
        const eventEmitterCallData: CallData = new CallData(compiledEventEmitterSierra.abi)
        const eventEmitterConstructor: Calldata = eventEmitterCallData.compile("constructor", {})
        const deployEventEmitterResponse = await account0.declareAndDeploy({
            contract: compiledEventEmitterSierra,
            casm: compiledEventEmitterCasm,
            constructorCalldata: eventEmitterConstructor,
        })

        contractAddresses.EventEmitter = deployEventEmitterResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }
    if (!contractAddresses.OracleStore) {
        const compiledOracleStoreCasm = json.parse(fs.readFileSync("./target/dev/satoru_OracleStore.compiled_contract_class.json").toString("ascii"))
        const compiledOracleStoreSierra = json.parse(fs.readFileSync("./target/dev/satoru_OracleStore.contract_class.json").toString("ascii"))
        const oracleStoreCallData: CallData = new CallData(compiledOracleStoreSierra.abi)
        const oracleStoreConstructor: Calldata = oracleStoreCallData.compile("constructor", {
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter
        })
        const deployOracleStoreResponse = await account0.declareAndDeploy({
            contract: compiledOracleStoreSierra,
            casm: compiledOracleStoreCasm,
            constructorCalldata: oracleStoreConstructor,
        })

        contractAddresses.OracleStore = deployOracleStoreResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.Oracle) {
        const compiledOracleCasm = json.parse(fs.readFileSync("./target/dev/satoru_Oracle.compiled_contract_class.json").toString("ascii"))
        const compiledOracleSierra = json.parse(fs.readFileSync("./target/dev/satoru_Oracle.contract_class.json").toString("ascii"))
        const oracleCallData: CallData = new CallData(compiledOracleSierra.abi)
        const oracleConstructor: Calldata = oracleCallData.compile("constructor", {
            role_store_address: contractAddresses.RoleStore,
            oracle_store_address: contractAddresses.OracleStore,
            pragma_address: account0.address
        })
        const deployOracleResponse = await account0.declareAndDeploy({
            contract: compiledOracleSierra,
            casm: compiledOracleCasm,
            constructorCalldata: oracleConstructor,
        })

        contractAddresses.Oracle = deployOracleResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.OrderVault) {
        const compiledOrderVaultCasm = json.parse(fs.readFileSync("./target/dev/satoru_OrderVault.compiled_contract_class.json").toString("ascii"))
        const compiledOrderVaultSierra = json.parse(fs.readFileSync("./target/dev/satoru_OrderVault.contract_class.json").toString("ascii"))
        const orderVaultCallData: CallData = new CallData(compiledOrderVaultSierra.abi)
        const orderVaultConstructor: Calldata = orderVaultCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
        })
        const deployOrderVaultResponse = await account0.declareAndDeploy({
            contract: compiledOrderVaultSierra,
            casm: compiledOrderVaultCasm,
            constructorCalldata: orderVaultConstructor,
        })

        contractAddresses.OrderVault = deployOrderVaultResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.SwapHandler) {
        const compiledSwapHandlerCasm = json.parse(fs.readFileSync("./target/dev/satoru_SwapHandler.compiled_contract_class.json").toString("ascii"))
        const compiledSwapHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_SwapHandler.contract_class.json").toString("ascii"))
        const swapHandlerCallData: CallData = new CallData(compiledSwapHandlerSierra.abi)
        const swapHandlerConstructor: Calldata = swapHandlerCallData.compile("constructor", {
            role_store_address: contractAddresses.RoleStore,
        })
        const deploySwapHandlerResponse = await account0.declareAndDeploy({
            contract: compiledSwapHandlerSierra,
            casm: compiledSwapHandlerCasm,
            constructorCalldata: swapHandlerConstructor,
        })

        contractAddresses.SwapHandler = deploySwapHandlerResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.ReferralStorage) {
        const compiledReferralStorageCasm = json.parse(fs.readFileSync("./target/dev/satoru_ReferralStorage.compiled_contract_class.json").toString("ascii"))
        const compiledReferralStorageSierra = json.parse(fs.readFileSync("./target/dev/satoru_ReferralStorage.contract_class.json").toString("ascii"))
        const referralStorageCallData: CallData = new CallData(compiledReferralStorageSierra.abi)
        const referralStorageConstructor: Calldata = referralStorageCallData.compile("constructor", {
            event_emitter_address: contractAddresses.EventEmitter,
        })
        const deployReferralStorageResponse = await account0.declareAndDeploy({
            contract: compiledReferralStorageSierra,
            casm: compiledReferralStorageCasm,
            constructorCalldata: referralStorageConstructor,
        })

        contractAddresses.ReferralStorage = deployReferralStorageResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.IncreaseOrderUtils) {
        const compiledIncreaseOrderUtilsCasm = json.parse(fs.readFileSync("./target/dev/satoru_IncreaseOrderUtils.compiled_contract_class.json").toString("ascii"))
        const compiledIncreaseOrderUtilsSierra = json.parse(fs.readFileSync("./target/dev/satoru_IncreaseOrderUtils.contract_class.json").toString("ascii"))
        const increaseOrderUtilsCallData: CallData = new CallData(compiledIncreaseOrderUtilsSierra.abi)
        const increaseOrderUtilsConstructor: Calldata = increaseOrderUtilsCallData.compile("constructor", {})
        const deployIncreaseOrderUtilsResponse = await account0.declareAndDeploy({
            contract: compiledIncreaseOrderUtilsSierra,
            casm: compiledIncreaseOrderUtilsCasm,
        })

        contractAddresses.IncreaseOrderUtils = deployIncreaseOrderUtilsResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
        classHashes.IncreaseOrderUtils = deployIncreaseOrderUtilsResponse.deploy.classHash;
        fs.writeFileSync(classHashesPath, JSON.stringify(classHashes, null, 4), 'utf8');
    }

    if (!contractAddresses.DecreaseOrderUtils) {
        const compiledDecreaseOrderUtilsCasm = json.parse(fs.readFileSync("./target/dev/satoru_DecreaseOrderUtils.compiled_contract_class.json").toString("ascii"))
        const compiledDecreaseOrderUtilsSierra = json.parse(fs.readFileSync("./target/dev/satoru_DecreaseOrderUtils.contract_class.json").toString("ascii"))
        const decreaseOrderUtilsCallData: CallData = new CallData(compiledDecreaseOrderUtilsSierra.abi)
        const decreaseOrderUtilsConstructor: Calldata = decreaseOrderUtilsCallData.compile("constructor", {})
        const deployDecreaseOrderUtilsResponse = await account0.declareAndDeploy({
            contract: compiledDecreaseOrderUtilsSierra,
            casm: compiledDecreaseOrderUtilsCasm,
        })

        contractAddresses.DecreaseOrderUtils = deployDecreaseOrderUtilsResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
        classHashes.DecreaseOrderUtils = deployDecreaseOrderUtilsResponse.deploy.classHash;
        fs.writeFileSync(classHashesPath, JSON.stringify(classHashes, null, 4), 'utf8');
    }

    if (!contractAddresses.SwapOrderUtils) {
        const compiledSwapOrderUtilsCasm = json.parse(fs.readFileSync("./target/dev/satoru_SwapOrderUtils.compiled_contract_class.json").toString("ascii"))
        const compiledSwapOrderUtilsSierra = json.parse(fs.readFileSync("./target/dev/satoru_SwapOrderUtils.contract_class.json").toString("ascii"))
        const swapOrderUtilsCallData: CallData = new CallData(compiledSwapOrderUtilsSierra.abi)
        const swapOrderUtilsConstructor: Calldata = swapOrderUtilsCallData.compile("constructor", {})
        const deploySwapOrderUtilsResponse = await account0.declareAndDeploy({
            contract: compiledSwapOrderUtilsSierra,
            casm: compiledSwapOrderUtilsCasm,
        })

        contractAddresses.SwapOrderUtils = deploySwapOrderUtilsResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
        classHashes.SwapOrderUtils = deploySwapOrderUtilsResponse.deploy.classHash;
        fs.writeFileSync(classHashesPath, JSON.stringify(classHashes, null, 4), 'utf8');
    }

    if (!contractAddresses.OrderUtils) {
        const compiledOrderUtilsCasm = json.parse(fs.readFileSync("./target/dev/satoru_OrderUtils.compiled_contract_class.json").toString("ascii"))
        const compiledOrderUtilsSierra = json.parse(fs.readFileSync("./target/dev/satoru_OrderUtils.contract_class.json").toString("ascii"))
        const orderUtilsCallData: CallData = new CallData(compiledOrderUtilsSierra.abi)
        const orderUtilsConstructor: Calldata = orderUtilsCallData.compile("constructor", {
            increase_order_class_hash: contractAddresses.IncreaseOrderUtils,
            decrease_order_class_hash: contractAddresses.DecreaseOrderUtils,
            swap_order_class_hash: contractAddresses.SwapOrderUtils
        })
        const deployOrderUtilsResponse = await account0.declareAndDeploy({
            contract: compiledOrderUtilsSierra,
            casm: compiledOrderUtilsCasm,
            constructorCalldata: orderUtilsConstructor
        })

        contractAddresses.OrderUtils = deployOrderUtilsResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
        classHashes.OrderUtils = deployOrderUtilsResponse.deploy.classHash;
        fs.writeFileSync(classHashesPath, JSON.stringify(classHashes, null, 4), 'utf8');

    }

    if (!contractAddresses.OrderHandler) {
        const compiledOrderHandlerCasm = json.parse(fs.readFileSync("./target/dev/satoru_OrderHandler.compiled_contract_class.json").toString("ascii"))
        const compiledOrderHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_OrderHandler.contract_class.json").toString("ascii"))
        const orderHandlerCallData: CallData = new CallData(compiledOrderHandlerSierra.abi)
        const orderHandlerConstructor: Calldata = orderHandlerCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            order_vault_address: contractAddresses.OrderVault,
            oracle_address: contractAddresses.Oracle,
            swap_handler_address: contractAddresses.SwapHandler,
            referral_storage_address: contractAddresses.ReferralStorage,
            order_utils_class_hash: classHashes.OrderUtils,
            increase_order_utils_class_hash: classHashes.IncreaseOrderUtils,
            decrease_order_utils_class_hash: classHashes.DecreaseOrderUtils,
            swap_order_utils_class_hash: classHashes.SwapOrderUtils,
        })
        const deployOrderHandlerResponse = await account0.declareAndDeploy({
            contract: compiledOrderHandlerSierra,
            casm: compiledOrderHandlerCasm,
            constructorCalldata: orderHandlerConstructor,
        })
        contractAddresses.OrderHandler = deployOrderHandlerResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.DepositVault) {
        const compiledDepositVaultCasm = json.parse(fs.readFileSync("./target/dev/satoru_DepositVault.compiled_contract_class.json").toString("ascii"))
        const compiledDepositVaultSierra = json.parse(fs.readFileSync("./target/dev/satoru_DepositVault.contract_class.json").toString("ascii"))
        const depositVaultCallData: CallData = new CallData(compiledDepositVaultSierra.abi)
        const depositVaultConstructor: Calldata = depositVaultCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
        })
        const deployDepositVaultResponse = await account0.declareAndDeploy({
            contract: compiledDepositVaultSierra,
            casm: compiledDepositVaultCasm,
            constructorCalldata: depositVaultConstructor,
        })

        contractAddresses.DepositVault = deployDepositVaultResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.DepositHandler) {
        const compiledDepositHandlerCasm = json.parse(fs.readFileSync("./target/dev/satoru_DepositHandler.compiled_contract_class.json").toString("ascii"))
        const compiledDepositHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_DepositHandler.contract_class.json").toString("ascii"))
        const depositHandlerCallData: CallData = new CallData(compiledDepositHandlerSierra.abi)
        const depositHandlerConstructor: Calldata = depositHandlerCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            deposit_vault_address: contractAddresses.DepositVault,
            oracle_address: contractAddresses.Oracle,
        })
        const deployDepositHandlerResponse = await account0.declareAndDeploy({
            contract: compiledDepositHandlerSierra,
            casm: compiledDepositHandlerCasm,
            constructorCalldata: depositHandlerConstructor,
        })

        contractAddresses.DepositHandler = deployDepositHandlerResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.WithdrawalVault) {
        const compiledWithdrawalVaultCasm = json.parse(fs.readFileSync("./target/dev/satoru_WithdrawalVault.compiled_contract_class.json").toString("ascii"))
        const compiledWithdrawalVaultSierra = json.parse(fs.readFileSync("./target/dev/satoru_WithdrawalVault.contract_class.json").toString("ascii"))
        const withdrawalVaultCallData: CallData = new CallData(compiledWithdrawalVaultSierra.abi)
        const withdrawalVaultConstructor: Calldata = withdrawalVaultCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
        })
        const deployWithdrawalVaultResponse = await account0.declareAndDeploy({
            contract: compiledWithdrawalVaultSierra,
            casm: compiledWithdrawalVaultCasm,
            constructorCalldata: withdrawalVaultConstructor,
        })

        contractAddresses.WithdrawalVault = deployWithdrawalVaultResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.WithdrawalHandler) {
        const compiledWithdrawalHandlerCasm = json.parse(fs.readFileSync("./target/dev/satoru_WithdrawalHandler.compiled_contract_class.json").toString("ascii"))
        const compiledWithdrawalHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_WithdrawalHandler.contract_class.json").toString("ascii"))
        const withdrawalHandlerCallData: CallData = new CallData(compiledWithdrawalHandlerSierra.abi)
        const withdrawalHandlerConstructor: Calldata = withdrawalHandlerCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            withdrawal_vault_address: contractAddresses.WithdrawalVault,
            oracle_address: contractAddresses.Oracle,
        })
        const deployWithdrawalHandlerResponse = await account0.declareAndDeploy({
            contract: compiledWithdrawalHandlerSierra,
            casm: compiledWithdrawalHandlerCasm,
            constructorCalldata: withdrawalHandlerConstructor,
        })

        contractAddresses.WithdrawalHandler = deployWithdrawalHandlerResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.LiquidationHandler) { 
        const compiledLiquidationHandlerCasm = json.parse(fs.readFileSync("./target/dev/satoru_LiquidationHandler.compiled_contract_class.json").toString("ascii"))
        const compiledLiquidationHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_LiquidationHandler.contract_class.json").toString("ascii"))
        const liquidationHandlerCallData: CallData = new CallData(compiledLiquidationHandlerSierra.abi)
        const liquidationHandlerConstructor: Calldata = liquidationHandlerCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            oracle_address: contractAddresses.Oracle,
            order_vault_address: contractAddresses.OrderVault,
            swap_handler_address: contractAddresses.SwapHandler,
            referral_storage_address: contractAddresses.ReferralStorage,
            order_utils_class_hash: classHashes.OrderUtils,
            increase_order_utils_class_hash: classHashes.IncreaseOrderUtils,
            decrease_order_utils_class_hash: classHashes.DecreaseOrderUtils,
            swap_order_utils_class_hash: classHashes.SwapOrderUtils,
        })
        const deployLiquidationHandlerResponse = await account0.declareAndDeploy({
            contract: compiledLiquidationHandlerSierra,
            casm: compiledLiquidationHandlerCasm,
            constructorCalldata: liquidationHandlerConstructor,
        })

        contractAddresses.LiquidationHandler = deployLiquidationHandlerResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.MarketFactory) {
        const marketTokenClassHash = classHashes.MarketToken;
        if(!marketTokenClassHash) { 
            try {
                const compiledMarketTokenCasm = json.parse(fs.readFileSync("./target/dev/satoru_MarketToken.compiled_contract_class.json").toString("ascii"))
                const compiledMarketTokenSierra = json.parse(fs.readFileSync("./target/dev/satoru_MarketToken.contract_class.json").toString("ascii"))
                const declare = await account0.declare({
                    contract: compiledMarketTokenSierra,
                    casm: compiledMarketTokenCasm
                })
                classHashes.MarketToken = declare.class_hash;
                fs.writeFileSync(classHashesPath, JSON.stringify(classHashes, null, 4), 'utf8');
            } catch (error) {
            console.log("🚀 ~ deploy ~ error:", error)

                
            }
        }
        

        const compiledMarketFactoryCasm = json.parse(fs.readFileSync("./target/dev/satoru_MarketFactory.compiled_contract_class.json").toString("ascii"))
        const compiledMarketFactorySierra = json.parse(fs.readFileSync("./target/dev/satoru_MarketFactory.contract_class.json").toString("ascii"))
        const marketFactoryCallData: CallData = new CallData(compiledMarketFactorySierra.abi)
        const marketFactoryConstructor: Calldata = marketFactoryCallData.compile("constructor", {
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            market_token_class_hash: marketTokenClassHash
        })
        const deployMarketFactoryResponse = await account0.declareAndDeploy({
            contract: compiledMarketFactorySierra,
            casm: compiledMarketFactoryCasm,
            constructorCalldata: marketFactoryConstructor,
        })
        contractAddresses.MarketFactory = deployMarketFactoryResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }


    if (!contractAddresses.Reader) {
        const compiledReaderCasm = json.parse(fs.readFileSync("./target/dev/satoru_Reader.compiled_contract_class.json").toString("ascii"))
        const compiledReaderSierra = json.parse(fs.readFileSync("./target/dev/satoru_Reader.contract_class.json").toString("ascii"))
        const readerCallData: CallData = new CallData(compiledReaderSierra.abi)
        const readerConstructor: Calldata = readerCallData.compile("constructor", {})
        const deployReaderResponse = await account0.declareAndDeploy({
            contract: compiledReaderSierra,
            casm: compiledReaderCasm,
            constructorCalldata: readerConstructor,
        })

        contractAddresses.Reader = deployReaderResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }

    if (!contractAddresses.Router) {
        const compiledRouterCasm = json.parse(fs.readFileSync("./target/dev/satoru_Router.compiled_contract_class.json").toString("ascii"))
        const compiledRouterSierra = json.parse(fs.readFileSync("./target/dev/satoru_Router.contract_class.json").toString("ascii"))
        const routerCallData: CallData = new CallData(compiledRouterSierra.abi)
        const routerConstructor: Calldata = routerCallData.compile("constructor", {
            role_store_address: contractAddresses.RoleStore,
        })
        const deployRouterResponse = await account0.declareAndDeploy({
            contract: compiledRouterSierra,
            casm: compiledRouterCasm,
            constructorCalldata: routerConstructor,
        })
        contractAddresses.Router = deployRouterResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');
    }


    if (!contractAddresses.ExchangeRouter) {
        const compiledExchangeRouterCasm = json.parse(fs.readFileSync("./target/dev/satoru_ExchangeRouter.compiled_contract_class.json").toString("ascii"))
        const compiledExchangeRouterSierra = json.parse(fs.readFileSync("./target/dev/satoru_ExchangeRouter.contract_class.json").toString("ascii"))
        const exchangeRouterCallData: CallData = new CallData(compiledExchangeRouterSierra.abi)
        const exchangeRouterConstructor: Calldata = exchangeRouterCallData.compile("constructor", {
            router_address: contractAddresses.Router,
            data_store_address: contractAddresses.DataStore,
            role_store_address: contractAddresses.RoleStore,
            event_emitter_address: contractAddresses.EventEmitter,
            deposit_handler_address: contractAddresses.DepositHandler,
            withdrawal_handler_address: contractAddresses.WithdrawalHandler,
            order_handler_address: contractAddresses.OrderHandler
        })
        const deployExchangeRouterResponse = await account0.declareAndDeploy({
            contract: compiledExchangeRouterSierra,
            casm: compiledExchangeRouterCasm,
            constructorCalldata: exchangeRouterConstructor,
        })

        contractAddresses.ExchangeRouter = deployExchangeRouterResponse.deploy.contract_address;
        fs.writeFileSync(contractAddressesPath, JSON.stringify(contractAddresses, null, 4), 'utf8');

    }
    console.log('Contracts Deployed ✅')
}

deploy()