#[cfg(test)]
mod chain {
    mod test_chain;
}

#[cfg(test)]
mod role {
    mod role_test;
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
}