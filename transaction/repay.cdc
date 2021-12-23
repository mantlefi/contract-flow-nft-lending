
import FungibleToken from 0x04
import FlowToken from 0x05 
import NonFungibleToken from 0x03
import Rentplace from 0x01
import Evolution from 0x02

// This transaction let borrower repay the Flow
transaction(SellerAddress: Address, Uuid: UInt64, RepayAmount: UFix64) {

    let temporaryVault: @FlowToken.Vault
    let collectionRef: &NonFungibleToken.Collection
    prepare(acct: AuthAccount) {

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's vault reference")

        self.temporaryVault <- vaultRef.withdraw(amount: RepayAmount) as! @FlowToken.Vault

        self.collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    }

    execute {
        let seller = getAccount(SellerAddress)

        let saleRef = seller.getCapability<&AnyResource{Rentplace.RentPublic}>(/public/NFTRent2)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        let returnNft <- saleRef.repay(uuid: Uuid,kind: Type<@Evolution.NFT>(), repayAmount: <-self.temporaryVault)

       
    
        self.collectionRef.deposit(token: <- returnNft)

    }
}
 
