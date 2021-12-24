import FlowToken from 0x05
import NonFungibleToken from 0x03
import FungibleToken from 0x04

pub contract NFTLendingPlace {

    // Event that is emitted when a new NFT is put up as a colletaral
    pub event ForLend(address: Address, kind: Type, id: UInt64,uuid:UInt64, baseAmount: UFix64, interest: UFix64, duration: UFix64)

    // Event that is emitted when the borrowing amount of an NFT changes
    pub event BaseAmountChanged(id: UInt64, newBaseAmount: UFix64)

    // Event that is emitted when the borrowing fee of an NFT changes
    pub event InterestChanged(id: UInt64, newInterest: UFix64)

    // Event that is emitted when the timers of an NFT changes
    pub event DurationChanged(id: UInt64, newDuration: UFix64)
    
    // Event that is emitted when a token been use as a colleteral
    pub event NFTLent(address: Address, kind: Type,uuid: UInt64, baseAmount: UFix64, interest: UFix64, beginningTime: UFix64, duration: UFix64)

    // Event that is emitted when user repay
    pub event Repay(kind:Type, uuid: UInt64, repayAmount: UFix64, time: UFix64)

    // Event that is emitted when user force redeem
    pub event ForcedRedeem(kind:Type, uuid: UInt64, time: UFix64)

    // Event that is emitted when a holder withdraws their NFT from the lending resource
    pub event CaseWithdrawn(id: UInt64)

    // Interface that users will publish for their Lending collection
    // that only exposes the methods that are supposed to be public
    //
    pub resource interface LendingPublic {
        pub fun lend(uuid: UInt64, kind: Type, recipient: Address, lendAmount: @FlowToken.Vault)
        pub fun repay(uuid: UInt64, kind: Type, repayAmount: @FlowToken.Vault): @NonFungibleToken.NFT
        pub fun forcedRedeem(uuid: UInt64, kind: Type): @NonFungibleToken.NFT
        pub fun idBaseAmounts(uuid: UInt64): UFix64?
        pub fun idInterests(uuid: UInt64): UFix64?
        pub fun idDuration(uuid: UInt64): UFix64?
        pub fun idLenders(uuid: UInt64): Address?
        pub fun getIDs(): [UInt64]
    }

    // LendingCollection
    //
    // NFT Collection object that allows a user to put their NFT as a colletaral
    // where others can send fungible tokens to lending it
    //
    pub resource LendingCollection: LendingPublic {

        // Dictionary of the NFTs that the user is putting up for lending
        pub var forLend: @{UInt64: NonFungibleToken.NFT}

        // Dictionary of the prices for each NFT by ID
        pub var baseAmounts: {UInt64: UFix64}
        pub var interests: {UInt64: UFix64} 
        pub var duration: {UInt64: UFix64}
        pub var beginningTime: {UInt64: UFix64}
        pub var lenders: {UInt64: Address}

        // The fungible token vault of the owner of this lending.
        // When someone lend a token, this resource can deposit
        // tokens into their account.
        access(account) let ownerVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

        init (vault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
            self.forLend <- {}

            self.ownerVault = vault
            self.baseAmounts = {}
            self.interests = {}
            self.beginningTime = {}
            self.duration = {} //ex: 5000 seconds

            self.lenders = {}
        }

        // listForLending lists an NFT as a colleteral
        pub fun listForLending(owner: Address, token: @NonFungibleToken.NFT, kind: Type, baseAmount: UFix64, interest: UFix64, duration: UFix64) {
            let uuid = token.uuid

            // store the price in the price array
            self.baseAmounts[uuid] = baseAmount

            self.interests[uuid] = interest

            self.duration[uuid] = duration

            emit ForLend( address: owner ,kind: kind, id:token.id, uuid: uuid, baseAmount: baseAmount, interest: interest, duration: duration)

            // put the NFT into the the ForLend dictionary
            let oldToken <- self.forLend[uuid] <- token
            destroy oldToken

        }

        // withdraw gives the owner the opportunity to remove a nft as a colleteral
        pub fun withdraw(uuid: UInt64): @NonFungibleToken.NFT {
            pre { self.lenders[uuid] == nil : "must not lenders in hosue"}

            self.baseAmounts.remove(key: uuid)

            self.duration.remove(key: uuid)
            
            self.interests.remove(key: uuid)

            self.lenders.remove(key: uuid)

            emit CaseWithdrawn(id: uuid)

            // remove and return the token
            let token <- self.forLend.remove(key: uuid) ?? panic("missing NFT")
            return <-token
        }

        // changebaseAmount changes the amount of a token that is currently for lending
        pub fun changebaseAmount(uuid: UInt64, newBaseAmount: UFix64) {
            pre { self.lenders[uuid] == nil : "must not lenders in hosue"}

            self.baseAmounts[uuid] = newBaseAmount

            emit BaseAmountChanged(id: uuid, newBaseAmount: newBaseAmount)
        }

        pub fun changeInterest(uuid: UInt64, newInterest: UFix64) {
            pre { self.lenders[uuid] == nil : "must not lenders in hosue"}

            self.interests[uuid] = newInterest

            emit InterestChanged(id: uuid, newInterest: newInterest)
        }

        pub fun changeExpiredBlock(uuid: UInt64, newDuration: UFix64) {
            pre { self.lenders[uuid] == nil : "must not lenders in hosue"}

            self.duration[uuid] = newDuration

            emit DurationChanged(id: uuid, newDuration: newDuration)
        }

        // lend lets a user send tokens to lend an NFT 
        pub fun lend(uuid: UInt64, kind: Type, recipient: Address, lendAmount: @FlowToken.Vault) {
            pre {
                self.forLend[uuid] != nil && self.forLend[uuid] != nil:
                    "No token matching this ID for lending!"

                lendAmount.balance >= (self.baseAmounts[uuid] ?? 0.0):
                    "Not enough tokens to lend the NFT!"

                self.lenders[uuid] == nil : "must no lender for this nft"

                self.beginningTime[uuid] == nil : "must no beginning block for this nft"
            }


            self.beginningTime[uuid] = getCurrentBlock().timestamp

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            
            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <- lendAmount)

            self.lenders[uuid] = recipient

            emit NFTLent(address: recipient, kind: kind, uuid:uuid, baseAmount: self.baseAmounts[uuid]!, interest: self.interests[uuid]!, beginningTime: self.beginningTime[uuid]! , duration: self.duration[uuid]!)
        }

        //repay
        pub fun repay(uuid: UInt64, kind: Type, repayAmount: @FlowToken.Vault): @NonFungibleToken.NFT{
            pre {
                self.forLend[uuid] != nil && self.forLend[uuid] != nil:
                    "No token matching this ID for leding!"

                repayAmount.balance >= (self.baseAmounts[uuid] ?? 0.0) + (self.interests[uuid] ?? 0.0):
                    "Not enough tokens to repay this NFT!"

                self.lenders[uuid] != nil : "case must have a lender"

                self.beginningTime[uuid] != nil : "case must begon"

                (self.duration[uuid] ?? 0.0 as UFix64) + (self.beginningTime[uuid] ?? 0.0 as UFix64) >= getCurrentBlock().timestamp : "repay must under certain numbers of block"
            }

            //pay
            let vaultRef = getAccount(self.lenders[uuid]!).getCapability(/public/flowTokenReceiver)
                      .borrow<&FlowToken.Vault{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference")
            
            self.lenders[uuid] = nil
            self.beginningTime[uuid] = nil

            let _repayAmount = repayAmount.balance

            vaultRef.deposit(from: <-repayAmount)

            emit Repay(kind:kind,uuid: uuid, repayAmount: _repayAmount, time: getCurrentBlock().timestamp)

            return <- self.withdraw(uuid: uuid)
        }

        //forcedRedeem
        pub fun forcedRedeem(uuid: UInt64, kind: Type): @NonFungibleToken.NFT{
            pre {
                self.forLend[uuid] != nil && self.forLend[uuid] != nil:
                    "No token matching this ID for lending!"

                self.lenders[uuid] != nil : "case must have a lender"

                self.beginningTime[uuid] != nil : "case must begon"

                (self.duration[uuid] ?? 0.0 as UFix64) + (self.beginningTime[uuid] ?? 0.0 as UFix64) < getCurrentBlock().timestamp : "ForcedRedeem must higher than certain numbers of block"
            }

            emit ForcedRedeem(kind:kind, uuid: uuid, time: getCurrentBlock().timestamp)

            self.lenders[uuid] = nil

            self.beginningTime[uuid] = nil

            return <- self.withdraw(uuid: uuid)
        }

        // idBaseAmounts returns the amouny of a specific token in the lending
        pub fun idBaseAmounts(uuid: UInt64): UFix64? {
            return self.baseAmounts[uuid]
        }

        pub fun idInterests(uuid: UInt64): UFix64? {
            return self.interests[uuid]
        }

        pub fun idDuration(uuid: UInt64): UFix64? {
            return self.duration[uuid]
        }

        pub fun idLenders(uuid: UInt64): Address? {
            return self.lenders[uuid]
        }

        // getIDs returns an array of token IDs that are colleteral
        pub fun getIDs(): [UInt64] {
            return self.forLend.keys
        }

        destroy() {
            destroy self.forLend
        }
    }

    // createCollection returns a new collection resource to the caller
    pub fun createLendingCollection(ownerVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>): @LendingCollection {
        return <- create LendingCollection(vault: ownerVault)
    }
}
 