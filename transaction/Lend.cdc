// Transaction2.cdc.  0x01專用

import FungibleToken from 0x04
import FlowToken from 0x05 
import NonFungibleToken from 0x03
import Rentplace from 0x01
import Evolution from 0x02

// This transaction uses the signers Vault tokens to purchase an NFT
// from the Sale collection of account 0x01.
transaction(SellerAddress: Address,BuyerAddress: Address, Uuid: UInt64, RentAmount: UFix64) {

    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    // Vault that will hold the tokens that will be used to
    // but the NFT
    let temporaryVault: @FlowToken.Vault

    prepare(acct: AuthAccount) {

        // get the references to the buyer's fungible token Vault and NFT Collection Receiver
        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's vault reference")

        // withdraw tokens from the buyers Vault
        self.temporaryVault <- vaultRef.withdraw(amount: RentAmount) as! @FlowToken.Vault
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(SellerAddress)

        // get the reference to the seller's sale
        let saleRef = seller.getCapability<&AnyResource{Rentplace.RentPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        // purchase the NFT the the seller is selling, giving them the reference
        // to your NFT collection and giving them the tokens to buy it
        saleRef.rent(uuid: Uuid,kind: Type<@Evolution.NFT>(), recipient: BuyerAddress, rentAmount: <-self.temporaryVault)

        log("Token 1 has been bought by account 2!")
    }
}
 
