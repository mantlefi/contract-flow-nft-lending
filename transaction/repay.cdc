import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS

// Let the borrower to repay FLOW
transaction(Uuid: UInt64, RepayAmount: UFix64) {

    let temporaryVault: @FlowToken.Vault
    let collectionRef: &NonFungibleToken.Collection
    let landingPlaceRef: &NFTLendingPlace.LendingCollection

    prepare(acct: AuthAccount) {

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow borrower's vault reference")

        self.temporaryVault <- vaultRef.withdraw(amount: RepayAmount) as! @FlowToken.Vault

        self.collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow borrower's NFT collection reference")

         self.landingPlaceRef =  acct.borrow<&NFTLendingPlace.LendingCollection>(from: /storage/NFTLendingPlace2)
            ?? panic("Could not borrow borrower's LenderTicket reference")
    }

    execute {
        let returnNft <- self.landingPlaceRef.repay(uuid: Uuid, repayAmount: <-self.temporaryVault)

        self.collectionRef.deposit(token: <-returnNft)
    }
}