import FlowToken from 0x05
import NonFungibleToken from 0x03
import FungibleToken from 0x04

// Marketplace.cdc。   
//
// The Marketplace contract is a sample implementation of an NFT Marketplace on Flow.
//
// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
//
// Learn more about marketplaces in this tutorial: https://docs.onflow.org/docs/composable-smart-contracts-marketplace

pub contract Rentplace {

    // Event that is emitted when a new NFT is put up for sale
    pub event ForRent(id: UInt64, baseAmount: UFix64, interest: UFix64, expiredTime: UFix64)

    // Event that is emitted when the price of an NFT changes
    pub event BaseAmountChanged(id: UInt64, newBaseAmount: UFix64)

    pub event InterestChanged(id: UInt64, newInterest: UFix64)

    pub event ExpiredBloockChanged(id: UInt64, newExpiredTime: UFix64)
    
    // Event that is emitted when a token is purchased
    pub event NFTRented(id: UInt64, BaseAmount: UFix64, Interest: UFix64, ExpiredTime: UFix64)

    // Event that is emitted when a token is 
    pub event Repay(id: UInt64, repayAmount: UFix64, block: UInt64)

    // Event that is emitted when a token is 
    pub event ForcedRedeem(id: UInt64, block: UInt64)

    // Event that is emitted when a holder withdraws their NFT from the rent
    pub event CaseWithdrawn(id: UInt64)

    // Interface that users will publish for their Sale collection
    // that only exposes the methods that are supposed to be public
    //
    pub resource interface RentPublic {
        pub fun rent(tokenID: UInt64, recipient: Address, rentAmount: @FlowToken.Vault)
        pub fun repay(tokenID: UInt64, repayAmount: @FlowToken.Vault)
        pub fun forcedRedeem(tokenID: UInt64): @NonFungibleToken.NFT
        pub fun idBaseAmounts(tokenID: UInt64): UFix64?
        pub fun idInterests(tokenID: UInt64): UFix64?
        pub fun idExpiredTime(tokenID: UInt64): UFix64?
        pub fun idLenders(tokenID: UInt64): Address?
        pub fun getIDs(): [UInt64]
    }

    // SaleCollection
    //
    // NFT Collection object that allows a user to put their NFT up for sale
    // where others can send fungible tokens to purchase it
    //
    pub resource RentCollection: RentPublic {

        // Dictionary of the NFTs that the user is putting up for sale
        pub var forRent: @{UInt64: NonFungibleToken.NFT}

        // Dictionary of the prices for each NFT by ID
        pub var baseAmounts: {UInt64: UFix64}
        pub var interests: {UInt64: UFix64} 
        pub var expiredTime: {UInt64: UFix64}
        pub var beginningTime: {UInt64: UFix64}
        pub var lenders: {UInt64: Address}

        // The fungible token vault of the owner of this sale.
        // When someone buys a token, this resource can deposit
        // tokens into their account.
        access(account) let ownerVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

        init (vault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
            self.forRent <- {}

            self.ownerVault = vault
            self.baseAmounts = {}
            self.interests = {}
            self.beginningTime = {}
            self.expiredTime = {} //ex: 5000秒

            self.lenders = {}
        }

        // listForSale lists an NFT for sale in this collection
        pub fun listForRent(token: @NonFungibleToken.NFT, baseAmount: UFix64, interest: UFix64, expiredTime: UFix64) {
            let id = token.uuid

            // store the price in the price array
            self.baseAmounts[id] = baseAmount

            self.interests[id] = interest

            self.expiredTime[id] = expiredTime

            // put the NFT into the the forSale dictionary
            let oldToken <- self.forRent[id] <- token
            destroy oldToken

            emit ForRent(id: id, baseAmount: baseAmount, interest: interest, expiredTime: expiredTime)
        }

        // withdraw gives the owner the opportunity to remove a sale from the collection
        pub fun withdraw(tokenID: UInt64): @NonFungibleToken.NFT {
            pre { self.lenders[tokenID] == nil : "must not lenders in hosue"}

            self.baseAmounts.remove(key: tokenID)

            self.expiredTime.remove(key: tokenID)
            
            self.interests.remove(key: tokenID)

            self.lenders.remove(key: tokenID)

            emit CaseWithdrawn(id: tokenID)

            // remove and return the token
            let token <- self.forRent.remove(key: tokenID) ?? panic("missing NFT")
            return <-token
        }

        // changePrice changes the price of a token that is currently for sale
        pub fun changebaseAmount(tokenID: UInt64, newBaseAmount: UFix64) {
            pre { self.lenders[tokenID] == nil : "must not lenders in hosue"}

            self.baseAmounts[tokenID] = newBaseAmount

            emit BaseAmountChanged(id: tokenID, newBaseAmount: newBaseAmount)
        }

        pub fun changeInterest(tokenID: UInt64, newInterest: UFix64) {
            pre { self.lenders[tokenID] == nil : "must not lenders in hosue"}

            self.interests[tokenID] = newInterest

            emit InterestChanged(id: tokenID, newInterest: newInterest)
        }

        pub fun changeExpiredBlock(tokenID: UInt64, newExpiredTime: UFix64) {
            pre { self.lenders[tokenID] == nil : "must not lenders in hosue"}

            self.expiredTime[tokenID] = newExpiredTime

            emit ExpiredBloockChanged(id: tokenID, newExpiredTime: newExpiredTime)
        }

        // purchase lets a user send tokens to purchase an NFT that is for sale
        pub fun rent(tokenID: UInt64, recipient: Address, rentAmount: @FlowToken.Vault) {
            pre {
                self.forRent[tokenID] != nil && self.forRent[tokenID] != nil:
                    "No token matching this ID for rent!"

                rentAmount.balance >= (self.baseAmounts[tokenID] ?? 0.0):
                    "Not enough tokens to lend the NFT!"

                self.lenders[tokenID] == nil : "must no lender for this nft"

                self.beginningTime[tokenID] == nil : "must no beginning block for this nft"
            }


            self.beginningTime[tokenID] = getCurrentBlock().timestamp

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            
            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <-rentAmount)

            // deposit the NFT into the buyers collection
            self.lenders[tokenID] = recipient

            emit NFTRented(id: tokenID, BaseAmount: self.baseAmounts[tokenID]!, Interest: self.interests[tokenID]!, ExpiredTime: self.expiredTime[tokenID]!)
        }

        //贖回
        pub fun repay(tokenID: UInt64, repayAmount: @FlowToken.Vault){
            pre {
                self.forRent[tokenID] != nil && self.forRent[tokenID] != nil:
                    "No token matching this ID for sale!"

                repayAmount.balance >= (self.baseAmounts[tokenID] ?? 0.0) + (self.interests[tokenID] ?? 0.0):
                    "Not enough tokens to repay this NFT!"

                self.lenders[tokenID] != nil : "case must have a lender"

                self.beginningTime[tokenID] != nil : "case must begon"

                (self.expiredTime[tokenID] ?? 0.0 as UFix64) + (self.beginningTime[tokenID] ?? 0.0 as UFix64) >= getCurrentBlock().timestamp : "repay must under certain numbers of block"
            }

            //付錢
            let vaultRef = getAccount(self.lenders[tokenID]!).getCapability<&{FungibleToken.Receiver}>(/public/MainReceiver)
            .borrow() ?? panic("Could not borrow receiver reference")
            
            self.lenders[tokenID] = nil
            self.beginningTime[tokenID] = nil

            let _repayAmount = repayAmount.balance

            vaultRef.deposit(from: <-repayAmount)

            emit Repay(id: tokenID, repayAmount: _repayAmount, block: getCurrentBlock().height)
        }

        //強制清算
        pub fun forcedRedeem(tokenID: UInt64): @NonFungibleToken.NFT{
            pre {
                self.forRent[tokenID] != nil && self.forRent[tokenID] != nil:
                    "No token matching this ID for sale!"

                self.lenders[tokenID] != nil : "case must have a lender"

                self.beginningTime[tokenID] != nil : "case must begon"

                (self.expiredTime[tokenID] ?? 0.0 as UFix64) + (self.beginningTime[tokenID] ?? 0.0 as UFix64) < getCurrentBlock().timestamp : "ForcedRedeem must higher than certain numbers of block"
            }

            //直接整坨拿走
            //let vaultRef = getAccount(self.lenders[tokenID]!).getCapability<&{NonFungibleToken.NFTReceiver}>(/public/NFTReceiver)
            //.borrow()
            //?? panic("Could not borrow nft receiver reference")

            //vaultRef.deposit(token: <-self.withdraw(tokenID: tokenID))
            //let tokenref <-self.withdraw(tokenID: tokenID)

            emit ForcedRedeem(id: tokenID, block: getCurrentBlock().height)

            return <- self.withdraw(tokenID: tokenID)
        }

        // idPrice returns the price of a specific token in the sale
        pub fun idBaseAmounts(tokenID: UInt64): UFix64? {
            return self.baseAmounts[tokenID]
        }

        pub fun idInterests(tokenID: UInt64): UFix64? {
            return self.interests[tokenID]
        }

        pub fun idExpiredTime(tokenID: UInt64): UFix64? {
            return self.expiredTime[tokenID]
        }

        pub fun idLenders(tokenID: UInt64): Address? {
            return self.lenders[tokenID]
        }

        // getIDs returns an array of token IDs that are for sale
        pub fun getIDs(): [UInt64] {
            return self.forRent.keys
        }

        destroy() {
            destroy self.forRent
        }
    }

    // createCollection returns a new collection resource to the caller
    pub fun createRentCollection(ownerVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>): @RentCollection {
        return <- create RentCollection(vault: ownerVault)
    }
}
 