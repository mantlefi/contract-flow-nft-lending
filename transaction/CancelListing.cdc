import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import Evolution from 0xEVOLUTIONADDRESS

// cancel/withdraw the listed NFT from NFTLendingPlace's resource
transaction(Uuid: UInt64){

    prepare(acct: AuthAccount) {

        let sale = acct.borrow<&NFTLendingPlace.LendingCollection>(from: /storage/NFTRent2)
            ?? panic("Could not borrow owner's vault reference")

        // borrow a reference to the NFTCollection in storage
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    

        let token <- sale.withdraw(uuid: Uuid)

        collectionRef.deposit(token: <- token)
    }
}
 
