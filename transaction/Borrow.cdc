// Transaction1.cdc。  0x02

import FungibleToken from 0x04
import NonFungibleToken from 0x03
import Rentplace from 0x01
import FlowToken from 0x05 
import Evolution from 0x02


// This transaction creates a new Sale Collection object,
// lists an NFT for sale, puts it in account storage,
// and creates a public capability to the sale so that others can buy the token.
transaction(Id: UInt64,baseAmount: UFix64, interest: UFix64, duration: UFix64){

    prepare(acct: AuthAccount) {
    //init
     if acct.borrow<&AnyResource{Rentplace.RentPublic}>(from: /storage/NFTRent) == nil {
       let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let sale <- Rentplace.createRentCollection(ownerVault: receiver)
        acct.save(<-sale, to: /storage/NFTRent)
        acct.link<&Rentplace.RentCollection{Rentplace.RentPublic}>(/public/NFTRent, target: /storage/NFTRent)

    }

        // Borrow a reference to the stored Vault
        let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        // Create a new Sale object, 
        // initializing it with the reference to the owner's vault

        let sale = acct.borrow<&Rentplace.RentCollection>(from: /storage/NFTRent)
            ?? panic("Could not borrow owner's vault reference")

        // borrow a reference to the NFTCollection in storage
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    
        // Withdraw the NFT from the collection that you want to sell
        // and move it into the transaction's context
        let token <- collectionRef.withdraw(withdrawID: Id)

        // List the token for sale by moving it into the sale object
        sale.listForRent(owner: acct.address,token: <-token,kind: Type<@Evolution.NFT>(),baseAmount: baseAmount, interest: interest, duration: duration)

        // Store the sale object in the account storage 
        //acct.save(<-sale, to: /storage/NFTSale)

        // Create a public capability to the sale so that others can call its methods
        acct.link<&Rentplace.RentCollection{Rentplace.RentPublic}>(/public/NFTRent, target: /storage/NFTRent)

        log("Rent Created for account 1")
    }
}
 
