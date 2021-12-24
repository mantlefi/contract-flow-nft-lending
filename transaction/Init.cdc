import NonFungibleToken from 0x03
import FungibleToken from 0x04
import Evolution from 0x02

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection

transaction {

    prepare(acct: AuthAccount) {

        if acct.borrow<&{Evolution.EvolutionCollectionPublic}>(from: /storage/EvolutionCollection) == nil {

            // Create a new flowToken Vault and put it in storage
            acct.save(<-Evolution.createEmptyCollection(), to: /storage/EvolutionCollection)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
        }

        acct.link<&{Evolution.EvolutionCollectionPublic, NonFungibleToken.CollectionPublic}>(/public/EvolutionCollection, target: /storage/EvolutionCollection)
    }

    execute {
        // Use the minter reference to mint an NFT, which deposits
        // the NFT into the collection that is sent as a parameter

        log("NFT")
    }
}
