import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import Evolution from 0xEVOLUTIONADDRESS

// lists an NFT for lend, puts it in account storage
transaction(id: UInt64, baseAmount: UFix64, interest: UFix64, duration: UFix64) {

    prepare(acct: AuthAccount) {

        // Init
        if acct.borrow<&AnyResource{NFTLendingPlace.LendingPublic}>(from: /storage/NFTLendingPlace) == nil {
            let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            let lendingPlace <- NFTLendingPlace.createLendingCollection(ownerVault: receiver)
            acct.save(<-lendingPlace, to: /storage/NFTLendingPlace)
            acct.link<&NFTLendingPlace.LendingCollection{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace, target: /storage/NFTLendingPlace)
        }

        let lendingPlace = acct.borrow<&NFTLendingPlace.LendingCollection>(from: /storage/NFTLendingPlace)
            ?? panic("Could not borrow owner's vault reference")

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")

        // Withdraw the NFT from the collection that you want to use as colletaral
        let token <- collectionRef.withdraw(withdrawID: id)

        // List the token as a colletaral
        lendingPlace.listForLending(owner: acct.address, token: <-token, baseAmount: baseAmount, interest: interest, duration: duration)

        acct.link<&NFTLendingPlace.LendingCollection{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace, target: /storage/NFTLendingPlace)
    }
}
