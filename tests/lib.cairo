#[cfg(test)]
mod callback {
    mod test_callback_utils;
}

#[cfg(test)]
mod chain {
    mod test_chain;
}

#[cfg(test)]
mod role {
    mod role_test;
}

#[cfg(test)]
mod config {
    mod test_config;
}

#[cfg(test)]
mod bank {
    mod test_bank;
    mod test_strict_bank;
}

#[cfg(test)]
mod deposit {
    mod test_deposit;
    mod test_deposit_utils;
    mod test_deposit_vault; 
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
mod liquidation {
    mod test_liquidation;
}
