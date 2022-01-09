import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS

// Let the lender lend FLOW to borrower
transaction(BorrowerAddress: Address, LenderAddress: Address, Uuid: UInt64, LendAmount: UFix64) {

    let temporaryVault: @FlowToken.Vault

    let ticketRef:  &NFTLendingPlace.LenderTicket

    prepare(acct: AuthAccount) {

        // Init
        if acct.borrow<&NFTLendingPlace.LenderTicket>(from: /storage/NFTLendingPlaceLenderTicket) == nil {
            let lendingTicket <- NFTLendingPlace.createLenderTicket()
            acct.save(<-lendingTicket, to: /storage/NFTLendingPlaceLenderTicket)
        }

        self.ticketRef = acct.borrow<&NFTLendingPlace.LenderTicket>(from: /storage/NFTLendingPlaceLenderTicket)
            ?? panic("Could not borrow owner's LenderTicket reference")

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's vault reference")

        self.temporaryVault <- vaultRef.withdraw(amount: LendAmount) as! @FlowToken.Vault
    }

    execute {

        let borrower = getAccount(BorrowerAddress)

        let lendingPlaceRef = borrower.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTLendingPlace)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        lendingPlaceRef.lend(uuid: Uuid, recipient: LenderAddress, lendAmount: <-self.temporaryVault, ticket:  self.ticketRef)
    }
}
