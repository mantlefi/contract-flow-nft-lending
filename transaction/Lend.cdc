// Transaction2.cdc.  0x01專用

import FungibleToken from 0x04
import FlowToken from 0x05 
import NonFungibleToken from 0x03
import Rentplace from 0x01
import Evolution from 0x02

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

        let saleRef = seller.getCapability<&AnyResource{Rentplace.RentPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        saleRef.rent(uuid: Uuid,kind: Type<@Evolution.NFT>(), recipient: BuyerAddress, rentAmount: <-self.temporaryVault)

    }
}
 
