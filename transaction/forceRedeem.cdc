// Transaction1.cdc。  0x02

import FungibleToken from 0x04
import NonFungibleToken from 0x03
import Rentplace from 0x01
import FlowToken from 0x05 
import Evolution from 0x02


// This transaction let lender force get the borrower nft
transaction(Uuid: UInt64,SellerAddress: Address){


    prepare(acct: AuthAccount) {
    
        let seller = getAccount(SellerAddress)

        let saleRef = seller.getCapability<&AnyResource{Rentplace.RentPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")


         let returnNft <- saleRef.forcedRedeem(uuid: Uuid,kind: Type<@Evolution.NFT>())

    
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
        collectionRef.deposit(token: <- returnNft)

    }
}
 
