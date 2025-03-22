use core::traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::withdrawal::withdrawal_vault::{IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait};

fn OWNER() -> ContractAddress{
    contract_address_const::<1>()
}
const TOKEN_AMOUNT: u256 = 1000_u256;


// mock ERC20
#[starknet::interface]
trait IERC20<T> {
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256) -> bool;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::contract]
mod MockERC20 {
    use starknet::{ContractAddress, get_caller_address};
    use core::zeroable::Zeroable;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};
    

    #[storage]
    struct Storage {
        balances: Map<ContractAddress, u256>,
        total_supply: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_supply: u256, owner: ContractAddress) {
        self.total_supply.write(initial_supply);
        self.balances.write(owner, initial_supply);
    }

    #[abi(embed_v0)]
    impl IERC20Impl of super::IERC20<ContractState> {
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            true
        }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn transfer_from(
            ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) -> bool {
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            true
        }
    }
}

fn deploy_mock_contracts() -> (IDataStoreDispatcher, IRoleStoreDispatcher, IERC20Dispatcher, IWithdrawalVaultDispatcher) {
    // Deploy contracts and mock contract
    let role_store_class = declare('RoleStore');
    let role_store_address = role_store_class.deploy(@ArrayTrait::new()).unwrap();
    
    let data_store = declare('DataStore');
    let data_store_address = data_store.deploy(@array![role_store_address.into()]).unwrap();

    let withdrawal_vault = declare('WithdrawalVault');
    let withdrawal_vault_address = withdrawal_vault.deploy(@array![data_store_address.into(),role_store_address.into(), ]).unwrap();

    let mock_erc20 = declare('MockERC20');
    let mut calldata: Array<felt252> = array![withdrawal_vault_address.into(), TOKEN_AMOUNT.try_into().unwrap()];
    let mock_erc20_address = mock_erc20.deploy(@calldata).unwrap();

    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let mock_erc20 = IERC20Dispatcher { contract_address: mock_erc20_address };
    let withdrawal_vault = IWithdrawalVaultDispatcher { contract_address: withdrawal_vault_address };

    (data_store, role_store, mock_erc20, withdrawal_vault)
}



#[test]
fn test_initialize() {
    let (data_store_dispatcher, role_store_dispatcher, _, withdrawal_vault_dispatcher ) = deploy_mock_contracts();
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    withdrawal_vault_dispatcher.initialize(
        data_store_dispatcher.contract_address,
        role_store_dispatcher.contract_address
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    // The initialize function mostly sets up the StrictBank, which we can't directly test
    // but we can verify that the contract doesn't revert
    assert(true, 'initialization should succeed');
}

#[test]
fn test_transfer_out() {
    // Test withdrawal vault transfer out function
    let (data_store_dispatcher, role_store_dispatcher, erc20_dispatcher, withdrawal_vault_dispatcher ) = deploy_mock_contracts();
    let sender = OWNER();
    let receiver = contract_address_const::<0x456>();

    let token_addr = erc20_dispatcher.contract_address;
    let amount: u256 = 500_u256;
    // initialize Vault
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    withdrawal_vault_dispatcher.initialize(
        data_store_dispatcher.contract_address,
        role_store_dispatcher.contract_address
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    
    // Call transfer out function
    start_prank(sender, withdrawal_vault_dispatcher.contract_address);
    // Transfers the token from the withdrawal vault to the receiver
    // Initially, the withdrawal vault has all the total supply of the token.
    // This was done during the deployment.
    // refer to the deploy_mock_contracts() function for more info. 
    withdrawal_vault_dispatcher.transfer_out(
        sender,
        token_addr,
        receiver,
        amount
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    // check the balance of the receiver.
    assert(erc20_dispatcher.balance_of(receiver) == amount, 'Invalid balance');
}

#[test]
fn test_record_transfer_in() {
    // Test withdrawal vault record transfer in function
    let (data_store_dispatcher, role_store_dispatcher, erc20_dispatcher, withdrawal_vault_dispatcher ) = deploy_mock_contracts();
    let token_addr = erc20_dispatcher.contract_address;
    // initialize Vault. needed to access the other functions
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    withdrawal_vault_dispatcher.initialize(
        data_store_dispatcher.contract_address,
        role_store_dispatcher.contract_address
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);

    // call the record_transfer_in function
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    let recorded_amount = withdrawal_vault_dispatcher.record_transfer_in(
        token_addr
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    // according to the logic, the StrickBank contract keeps the record of tokens
    // as the amount token of the mockERC20 contract that the StrictBank contract has is zero,
    // the recorded amount would be 0.
    assert(recorded_amount == 0, 'recorded amount should return 0');
    
}
    
#[test]
fn test_sync_token_balance() {
    // Test withdrawal vault sync token balance function
    // similar to the record_transfer_in function, just return next_balance
    // instead of the next_balance - prev_balance
    let (data_store_dispatcher, role_store_dispatcher, erc20_dispatcher, withdrawal_vault_dispatcher ) = deploy_mock_contracts();
    let token_addr = erc20_dispatcher.contract_address;
    // initialize Vault. needed to access the other functions
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    withdrawal_vault_dispatcher.initialize(
        data_store_dispatcher.contract_address,
        role_store_dispatcher.contract_address
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    // call the record_transfer_in function
    start_prank(OWNER(), withdrawal_vault_dispatcher.contract_address);
    let recorded_amount = withdrawal_vault_dispatcher.sync_token_balance(
        token_addr
    );
    stop_prank(withdrawal_vault_dispatcher.contract_address);
    // the recorded amount would be 0 
    // as StrickBank token balance of MockERC20 token is 0. 
    assert(recorded_amount == 0, 'recorded amount should return 0');
}