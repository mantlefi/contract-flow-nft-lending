import NonFungibleToken from 0x03
import Evolution from 0x02

// Let users mint an NFT, and deposit into their own collection
transaction {

    prepare(acct: AuthAccount) {

        if acct.borrow<&{Evolution.EvolutionCollectionPublic}>(from: /storage/EvolutionCollection) == nil {

            // Create a new flowToken vault into the storage
            acct.save(<-Evolution.createEmptyCollection(), to: /storage/EvolutionCollection)
        }

        // Create a public capability to the vault, 
        // which only exposes the deposit function by the receiver interface
        acct.link<&{Evolution.EvolutionCollectionPublic, NonFungibleToken.CollectionPublic}>(/public/EvolutionCollection, target: /storage/EvolutionCollection)
    }

    execute {
        log("NFT")
    }
}
