import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS

// Let the lender get borrower's NFT by force
transaction(Uuid: UInt64, BorrowerAddress: Address) {

    prepare(acct: AuthAccount) {

        let seller = getAccount(BorrowerAddress)

        let saleRef = seller.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        let ticketRef =  acct.borrow<&NFTLendingPlace.LenderTicket>(from: /storage/NFTLendingPlaceLenderTicket)
            ?? panic("Could not borrow owner's LenderTicket reference")
           
        let returnNft <- saleRef.forcedRedeem(uuid: Uuid, lendticket: ticketRef)

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's NFT collection reference")

        collectionRef.deposit(token: <-returnNft)
    }
}
