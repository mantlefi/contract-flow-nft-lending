import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS

// Let the NFT owner unlist NFT from NFTLendingPlace's resource
transaction(Uuid: UInt64) {

    prepare(acct: AuthAccount) {

        let lending = acct.borrow<&NFTLendingPlace.LendingCollection>(from: /storage/NFTLendingPlace)
            ?? panic("Could not borrow owner's vault reference")

        // Borrow a reference to the NFTCollection in storage
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's NFT collection reference")

        let NFTtoken <- lending.withdraw(uuid: Uuid)

        collectionRef.deposit(token: <- NFTtoken)
    }
}
