use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Bookmark {
    label: felt252,
    url: felt252,
}

#[starknet::interface]
pub trait IStarkmark<TContractState> {
    fn store_bookmark(
        ref self: TContractState, bookmark: Bookmark);
    fn get_bookmark(self: @TContractState, address: ContractAddress) -> Array<Bookmark>;
    fn get_owner(self: @TContractState) -> Starkmark::Person;
}

#[starknet::contract]
mod Starkmark {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};
    use alexandria_storage::list::{List, ListTrait};
    use super::Bookmark;

    #[storage]
    struct Storage {
        bookmarks: LegacyMap::<ContractAddress, List<Bookmark>>,
        owner: Person,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredBookmark: StoredBookmark,
    }
    #[derive(Drop, starknet::Event)]
    struct StoredBookmark {
        #[key]
        user: ContractAddress,
        bookmark: Bookmark,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Person {
        address: ContractAddress,
        name: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.owner.write(owner);
    }

    // Public functions inside an impl block
    #[abi(embed_v0)]
    impl Starkmark of super::IStarkmark<ContractState> {
        fn store_bookmark(ref self: ContractState, bookmark: Bookmark) {
            let caller = get_caller_address();
            self._store_bookmark(caller, bookmark);
        }

        fn get_bookmark(self: @ContractState, address: ContractAddress) -> Array<Bookmark> {
            self.bookmarks.read(address).array().unwrap()
        }

        fn get_owner(self: @ContractState) -> Person {
            self.owner.read()
        }
    }

    // Standalone public function
    #[external(v0)]
    fn get_contract_bookmark(self: @ContractState) -> felt252 {
        'bookmark Registry'
    }

    // Could be a group of functions about a same topic
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _store_bookmark(
            ref self: ContractState,
            user: ContractAddress,
            bookmark: Bookmark,
        ) {
            // let total_bookmarks = self.total_bookmarks.read();
            let snapshot = @bookmark;
            let mut old_bookmarks = self.bookmarks.read(user);
            old_bookmarks.append(bookmark).unwrap();
            self.bookmarks.write(user, old_bookmarks);
            self.emit(StoredBookmark { user: user, bookmark: *snapshot });
        }
    }

    // Free function
    fn get_owner_storage_address(self: @ContractState) -> StorageBaseAddress {
        self.owner.address()
    }
}