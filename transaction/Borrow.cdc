// Transaction1.cdc。  0x02

import FungibleToken from 0x04
import NonFungibleToken from 0x03
import Rentplace from 0x01
import FlowToken from 0x05 
import Evolution from 0x02


// This transaction creates a new Lend Collection object,
// lists an NFT for lend, puts it in account storage,
transaction(Id: UInt64,baseAmount: UFix64, interest: UFix64, duration: UFix64){

    prepare(acct: AuthAccount) {
    //init
     if acct.borrow<&AnyResource{Rentplace.RentPublic}>(from: /storage/NFTRent2) == nil {
       let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let sale <- Rentplace.createRentCollection(ownerVault: receiver)
        acct.save(<-sale, to: /storage/NFTRent2)
        acct.link<&Rentplace.RentCollection{Rentplace.RentPublic}>(/public/NFTRent2, target: /storage/NFTRent2)

    }

        let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        let sale = acct.borrow<&Rentplace.RentCollection>(from: /storage/NFTRent2)
            ?? panic("Could not borrow owner's vault reference")

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    
        // Withdraw the NFT from the collection that you want to use as colletaral
        let token <- collectionRef.withdraw(withdrawID: Id)

        // List the token as a colletaral
        sale.listForRent(owner: acct.address,token: <-token,kind: Type<@Evolution.NFT>(),baseAmount: baseAmount, interest: interest, duration: duration)


        acct.link<&Rentplace.RentCollection{Rentplace.RentPublic}>(/public/NFTRent2, target: /storage/NFTRent2)
    }
}
 
