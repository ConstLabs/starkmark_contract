use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarkmark<TContractState> {
    fn store_bookmark(
        ref self: TContractState, bookmark: Starkmark::Bookmark);
    fn get_bookmark(self: @TContractState, address: ContractAddress) -> Starkmark::Bookmark;
    fn get_owner(self: @TContractState) -> Starkmark::Person;
}

#[starknet::contract]
mod Starkmark {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};

    #[storage]
    struct Storage {
        bookmarks: LegacyMap::<ContractAddress, Bookmark>,
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
        bookmark: Bookmark,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub struct Bookmark {
        label: felt252,
        url: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.bookmarks.write(owner.address, owner.bookmark);
        self.owner.write(owner);
    }

    // Public functions inside an impl block
    #[abi(embed_v0)]
    impl Starkmark of super::IStarkmark<ContractState> {
        fn store_bookmark(ref self: ContractState, bookmark: Bookmark) {
            let caller = get_caller_address();
            self._store_bookmark(caller, bookmark);
        }

        fn get_bookmark(self: @ContractState, address: ContractAddress) -> Bookmark {
            self.bookmarks.read(address)
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
            self.bookmarks.write(user, bookmark);
            self.emit(StoredBookmark { user: user, bookmark: *snapshot });
        }
    }

    // Free function
    fn get_owner_storage_address(self: @ContractState) -> StorageBaseAddress {
        self.owner.address()
    }
}