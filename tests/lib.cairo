#[cfg(test)]
mod bank {
    mod test_bank;
    mod test_strict_bank;
}

#[cfg(test)]
mod chain {
    mod test_chain;
}

#[cfg(test)]
mod config {
    mod test_config;
}

#[cfg(test)]
mod deposit {
    mod test_deposit;
    mod test_deposit_utils;
    mod test_deposit_vault;
}

#[cfg(test)]
mod gas {
    mod test_gas_utils;
}

#[cfg(test)]
mod liquidation {
    mod test_liquidation;
}

#[cfg(test)]
mod nonce {
    mod test_nonce_utils;
}

#[cfg(test)]
mod referral {
    mod test_referral;
}

#[cfg(test)]
mod role {
    mod role_test;
}

#[cfg(test)]
mod withdrawal {
    mod test_withdrawal;
    mod test_withdrawal_utils;
    mod test_withdrawal_vault;
}

#[cfg(test)]
mod price {
    mod price_test;
}