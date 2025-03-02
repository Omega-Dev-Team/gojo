use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};

use satoru::test_utils::tests_lib::{setup, teardown, deploy_event_emitter};

#[starknet::interface]
trait ICallbackMock<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
}

#[starknet::contract]
mod CallbackMock {
    use satoru::callback::deposit_callback_receiver::interface::IDepositCallbackReceiver;
    use satoru::callback::withdrawal_callback_receiver::interface::IWithdrawalCallbackReceiver;
    use satoru::callback::order_callback_receiver::interface::IOrderCallbackReceiver;
    use satoru::deposit::deposit::Deposit;
    use satoru::withdrawal::withdrawal::Withdrawal;
    use satoru::order::order::Order;
    use satoru::event::event_utils::LogData;

    #[storage]
    struct Storage {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.counter.write(1);
    }

    #[abi(embed_v0)]
    impl ICallbackMockImpl of super::ICallbackMock<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
    }

    #[abi(embed_v0)]
    impl IDepositCallbackReceiverImpl of IDepositCallbackReceiver<ContractState> {
        fn after_deposit_execution(
            ref self: ContractState, key: felt252, deposit: Deposit, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }

        fn after_deposit_cancellation(
            ref self: ContractState, key: felt252, deposit: Deposit, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }
    }

    #[abi(embed_v0)]
    impl IWithdrawalCallbackReceiverImpl of IWithdrawalCallbackReceiver<ContractState> {
        fn after_withdrawal_execution(
            ref self: ContractState, key: felt252, withdrawal: Withdrawal, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }

        fn after_withdrawal_cancellation(
            ref self: ContractState, key: felt252, withdrawal: Withdrawal, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }
    }

    #[abi(embed_v0)]
    impl IOrderCallbackReceiverImpl of IOrderCallbackReceiver<ContractState> {
        fn after_order_execution(
            ref self: ContractState, key: felt252, order: Order, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }

        fn after_order_cancellation(
            ref self: ContractState, key: felt252, order: Order, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }

        fn after_order_frozen(
            ref self: ContractState, key: felt252, order: Order, log_data: Array<felt252>,
        ) {
            self.counter.write(self.get_counter() + 1);
        }
    }
}

fn deploy_callback_mock() -> ICallbackMockDispatcher {
    let contract = declare('CallbackMock');
    let contract_address = contract.deploy(@array![]).unwrap();
    ICallbackMockDispatcher { contract_address }
}