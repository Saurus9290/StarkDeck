use core::traits::TryInto;
use starknet::{SyscallResult, Store};
use starknet::storage_access::StorageBaseAddress;
use starkdeck_contracts::models::{HoleCards, CommunityCards};
use alexandria_storage::list::{List, ListTrait};


pub impl StoreHoleCardsArray of Store<Array<HoleCards>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<HoleCards>> {
        StoreHoleCardsArray::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Array<HoleCards>
    ) -> SyscallResult<()> {
        StoreHoleCardsArray::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Array<HoleCards>> {
        let mut arr: Array<HoleCards> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<HoleCards>::read_at_offset(address_domain, base, offset).unwrap();
            arr.append(value);
            offset += Store::<HoleCards>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8, mut value: Array<HoleCards>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                Store::<HoleCards>::write_at_offset(address_domain, base, offset, element).unwrap();
                offset += Store::<HoleCards>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * Store::<HoleCards>::size()
    }
}

pub impl StoreCommunityCardsArray of Store<Array<CommunityCards>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<CommunityCards>> {
        StoreCommunityCardsArray::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Array<CommunityCards>
    ) -> SyscallResult<()> {
        StoreCommunityCardsArray::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Array<CommunityCards>> {
        let mut arr: Array<CommunityCards> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<CommunityCards>::read_at_offset(address_domain, base, offset)
                .unwrap();
            arr.append(value);
            offset += Store::<CommunityCards>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32,
        base: StorageBaseAddress,
        mut offset: u8,
        mut value: Array<CommunityCards>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                Store::<CommunityCards>::write_at_offset(address_domain, base, offset, element)
                    .unwrap();
                offset += Store::<CommunityCards>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * Store::<CommunityCards>::size()
    }
}

pub impl StoreFelt252Array of Store<Array<felt252>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<felt252>> {
        StoreFelt252Array::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Array<felt252>
    ) -> SyscallResult<()> {
        StoreFelt252Array::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Array<felt252>> {
        let mut arr: Array<felt252> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<felt252>::read_at_offset(address_domain, base, offset).unwrap();
            arr.append(value);
            offset += Store::<felt252>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8, mut value: Array<felt252>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                Store::<felt252>::write_at_offset(address_domain, base, offset, element).unwrap();
                offset += Store::<felt252>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * Store::<felt252>::size()
    }
}

pub impl PartialOrdFelt of PartialOrd<felt252> {
    #[inline(always)]
    fn le(lhs: felt252, rhs: felt252) -> bool {
        !(rhs < lhs)
    }
    #[inline(always)]
    fn ge(lhs: felt252, rhs: felt252) -> bool {
        !(lhs < rhs)
    }
    #[inline(always)]
    fn lt(lhs: felt252, rhs: felt252) -> bool {
        let rhs: u256 = rhs.into();
        let lhs: u256 = lhs.into();
        lhs < rhs
    }
    #[inline(always)]
    fn gt(lhs: felt252, rhs: felt252) -> bool {
        rhs < lhs
    }
}
