import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS

// Let the lender get borrower's NFT by force
transaction(Uuid: UInt64, BorrowerAddress: Address) {

    prepare(acct: AuthAccount) {

        let borrower = getAccount(BorrowerAddress)

        let lendingPlace = borrower.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace2)
            .borrow()
            ?? panic("Could not borrow borrower's NFT Lending Place resource")

        let ticketRef =  acct.borrow<&NFTLendingPlace.LenderTicket>(from: /storage/NFTLendingPlaceLenderTicket2)
            ?? panic("Could not borrow lender's LenderTicket resource")
           
        let returnNft <- lendingPlace.forcedRedeem(uuid: Uuid, lendticket: ticketRef)

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's NFT collection reference")

        collectionRef.deposit(token: <-returnNft)
    }
}
