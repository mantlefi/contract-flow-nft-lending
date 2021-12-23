import FungibleToken from 0xFUNGIBLETOKENADDRESS
import NonFungibleToken from 0xNONFUNGIBLETOKENADDRESS
import NFTLendingPlace from 0xNFTLENDINGPLACEADDRESS
import FlowToken from 0xFLOWTOKENADDRESS 
import Evolution from 0xEVOLUTIONADDRESS

// This transaction let lender lend the flow to borrower
transaction(SellerAddress: Address,BuyerAddress: Address, Uuid: UInt64, RentAmount: UFix64) {

    let temporaryVault: @FlowToken.Vault

    prepare(acct: AuthAccount) {

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's vault reference")

        self.temporaryVault <- vaultRef.withdraw(amount: RentAmount) as! @FlowToken.Vault
    }

    execute {
        let seller = getAccount(SellerAddress)

        let saleRef = seller.getCapability<&AnyResource{NFTLendingPlace.LendingPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        saleRef.lend(uuid: Uuid,kind: Type<@Evolution.NFT>(), recipient: BuyerAddress, lendAmount: <-self.temporaryVault)

    }
}
 
