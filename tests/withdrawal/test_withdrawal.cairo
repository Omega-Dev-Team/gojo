use satoru::withdrawal::withdrawal::Withdrawal;
use starknet::contract_address_const;

#[test]
fn test_default_withdrawal() {
    let default_withdrawal: Withdrawal = Default::default();
    let default_contract_address = contract_address_const::<0>();
    assert(default_withdrawal.key == 0, 'invalid key');
    assert(default_withdrawal.market_token_amount == 0, 'invalid market_token_amount');
    assert(default_withdrawal.min_long_token_amount == 0, 'invalid min long token amount');
    assert(default_withdrawal.min_short_token_amount == 0, 'invalid min_short_token_amount');
    assert(default_withdrawal.account == default_contract_address, 'invalid account');
    assert(default_withdrawal.receiver == default_contract_address, 'invalid receiver');
    assert(default_withdrawal.callback_contract == default_contract_address, 'invalid callback_contract');
    assert(default_withdrawal.ui_fee_receiver == default_contract_address, 'invalid ui_fee_receiver');
    assert(default_withdrawal.market == default_contract_address, 'invalid market');
}