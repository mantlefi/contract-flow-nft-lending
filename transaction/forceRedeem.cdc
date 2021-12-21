// Transaction1.cdc。  0x02

import FungibleToken from 0x04
import NonFungibleToken from 0x03
import Rentplace from 0x01
import FlowToken from 0x05 
import Evolution from 0x02


// This transaction creates a new Sale Collection object,
// lists an NFT for sale, puts it in account storage,
// and creates a public capability to the sale so that others can buy the token.
transaction(Uuid: UInt64,SellerAddress: Address){


    prepare(acct: AuthAccount) {
    
 // get the read-only account storage of the seller
        let seller = getAccount(SellerAddress)

        // get the reference to the seller's sale
        let saleRef = seller.getCapability<&AnyResource{Rentplace.RentPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        // purchase the NFT the the seller is selling, giving them the reference
        // to your NFT collection and giving them the tokens to buy it
         let returnNft <- saleRef.forcedRedeem(uuid: Uuid,kind: Type<@Evolution.NFT>())

    
        // borrow a reference to the NFTCollection in storage
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    
        // Withdraw the NFT from the collection that you want to sell
        // and move it into the transaction's context
        collectionRef.deposit(token: <- returnNft)

    }
}
 
