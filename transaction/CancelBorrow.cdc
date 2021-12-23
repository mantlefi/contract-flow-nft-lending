import NonFungibleToken from 0x03
import Rentplace from 0x01
import Evolution from 0x02


// cancel the borrow list
transaction(Uuid: UInt64){

    prepare(acct: AuthAccount) {

        let sale = acct.borrow<&Rentplace.RentCollection>(from: /storage/NFTRent2)
            ?? panic("Could not borrow owner's vault reference")

        // borrow a reference to the NFTCollection in storage
        let collectionRef = acct.borrow<&NonFungibleToken.Collection>(from: /storage/EvolutionCollection)
            ?? panic("Could not borrow owner's nft collection reference")
    

        let token <- sale.withdraw(uuid: Uuid)

        collectionRef.deposit(token: <- token)
    }
}
 
