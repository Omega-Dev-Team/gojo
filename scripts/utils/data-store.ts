import { dataStoreContract } from "./contracts";
import * as dataStoreKeys from "./../constants/dataStoreKeys";

export const get_max_pnl_factor = async (pnl_factor_type: string, market: string, is_long: boolean) => {
    const key = dataStoreKeys.maxPnlFactorKey(pnl_factor_type, market, is_long);
    const max_pnl_factor = await dataStoreContract.get_u256(key);
    return max_pnl_factor;
 }