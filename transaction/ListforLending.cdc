import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS 
import Evolution from 0xEVOLUTIONADDRESS
// lists an NFT for lend, puts it in account storage,
transaction(Id: UInt64,baseAmount: UFix64, interest: UFix64, duration: UFix64){

    prepare(acct: AuthAccount) {
    //init
     if acct.borrow<&AnyResource{NFTLendingPlace.LendingPublic}>(from: /storage/NFTRent2) == nil {
       let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let sale <- NFTLendingPlace.createLendingCollection(ownerVault: receiver)
        acct.save(<-sale, to: /storage/NFTRent2)
        acct.link<&NFTLendingPlace.LendingCollection{NFTLendingPlace.LendingPublic}>(/public/NFTRent2, target: /storage/NFTRent2)
    }

        let receiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        let sale = acct.borrow<&NFTLendingPlace.LendingCollection>(from: /storage/NFTRent2)
            ?? panic("Could not borrow owner's vault reference")

        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    
        // Withdraw the NFT from the collection that you want to use as colletaral
        let token <- collectionRef.withdraw(withdrawID: Id)

        // List the token as a colletaral
        sale.listForLending(owner: acct.address,token: <-token,kind: Type<@Evolution.NFT>(),baseAmount: baseAmount, interest: interest, duration: duration)


        acct.link<&NFTLendingPlace.LendingCollection{NFTLendingPlace.LendingPublic}>(/public/NFTRent2, target: /storage/NFTRent2)
    }
}
 
