// CheckSetupScript.cdc

import FungibleToken from 0x01
import Evolution from 0x02
import NonFungibleToken from 0x05


// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// 需要去搜集各式各樣 NFT 的 Receiver

pub fun main():[UInt64] {
    // Get the accounts' public account objects
    let acct2 = getAccount(0xe330b1fb14aa8818)


    // Find the public Receiver capability for their Collections
    let acct2Capability = acct2.getCapability<&{Evolution.EvolutionCollectionPublic}>(/public/EvolutionCollection)

//        let acct2Capability = acct2.getCapability(/public/EvolutionCollection).borrow<&{Evolution.EvolutionCollectionPublic}>()



    let nft2Ref = acct2Capability.borrow()
        ?? panic("Could not borrow acct2 nft collection reference")

    // Print both collections as arrays of IDs


    log("Account 2 NFTs")
    log(nft2Ref.getIDs())

    return nft2Ref.getIDs()
}
