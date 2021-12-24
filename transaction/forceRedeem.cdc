import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import Evolution from 0xEVOLUTIONADDRESS

// This transaction let lender force get the borrower nft
transaction(Uuid: UInt64, SellerAddress: Address) {

    prepare(acct: AuthAccount) {

        let seller = getAccount(SellerAddress)

        let saleRef = seller.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        let returnNft <- saleRef.forcedRedeem(uuid: Uuid, kind: Type<@Evolution.NFT>())

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")

        collectionRef.deposit(token: <-returnNft)
    }
}
