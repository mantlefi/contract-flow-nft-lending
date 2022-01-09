import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS

// List an NFT in the account storage for lending
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
            ?? panic("Could not borrow borrower's NFT Lending Place resource")

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow borrower's NFT collection resource")

        // Withdraw the NFT to use as collateral
        let token <- collectionRef.withdraw(withdrawID: id)

        // List the NFT as collateral
        lendingPlace.listForLending(owner: acct.address, token: <-token, baseAmount: baseAmount, interest: interest, duration: duration)
    }
}
