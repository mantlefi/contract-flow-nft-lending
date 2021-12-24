import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import Evolution from 0xEVOLUTIONADDRESS

// This transaction let lender lend the flow to borrower
transaction(BorrowerAddress: Address, LenderAddress: Address, Uuid: UInt64, LendAmount: UFix64) {

    let temporaryVault: @FlowToken.Vault

    prepare(acct: AuthAccount) {

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's vault reference")

        self.temporaryVault <- vaultRef.withdraw(amount: LendAmount) as! @FlowToken.Vault
    }

    execute {

        let borrower = getAccount(BorrowerAddress)

        let lendingPlaceRef = borrower.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        lendingPlaceRef.lend(uuid: Uuid, kind: Type<@Evolution.NFT>(), recipient: LenderAddress, lendAmount: <-self.temporaryVault)
    }
}
