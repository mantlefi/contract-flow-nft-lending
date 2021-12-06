import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TeleportedTetherToken from 0xa527fab3f3bf081a

pub contract LendingController: FungibleToken {
  
  //放進來的代幣數量(Total Supply)
  pub var balanceToken1: UFix64
  pub var balanceToken2: UFix64

  //借出去的代幣數量(Total Borrow)
  pub var borrowAmountToken1: UFix64
  pub var borrowAmountToken2: UFix64

  //代幣價格
  pub var priceToken1: UFix64
  pub var priceToken2: UFix64

  //Deposit Limit
  pub var depositeLimitToken1: UFix64
  pub var depositeLimitToken2: UFix64

  access(contract) let token1Vault: @FlowToken.Vault
  access(contract) let token2Vault: @TeleportedTetherToken.Vault

  pub var totalSupply: UFix64

  pub event TokensInitialized(initialSupply: UFix64)
  pub event TokensWithdrawn(amount: UFix64, from: Address?)
  pub event TokensDeposited(amount: UFix64, to: Address?)
  pub event TokensMinted(amount: UFix64)
  pub event TokensBurned(amount: UFix64)

  // Defines token vault storage path
  pub let TokenStoragePath: StoragePath

  // Defines token vault public balance path
  pub let TokenPublicBalancePath: PublicPath

  // Defines token vault public receiver path
  pub let TokenPublicReceiverPath: PublicPath

  pub struct PoolAmounts {
    pub let token1Amount: UFix64
    pub let token2Amount: UFix64

    init(token1Amount: UFix64, token2Amount: UFix64) {
      self.token1Amount = token1Amount
      self.token2Amount = token2Amount
    }
  }

  pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

    // holds the balance of a users tokens
    pub var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }

    // withdraw
    //
    // Function that takes an integer amount as an argument
    // and withdraws that amount from the Vault.
    // It creates a new temporary Vault that is used to hold
    // the money that is being transferred. It returns the newly
    // created Vault to the context that called so it can be deposited
    // elsewhere.
    //
    pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
      self.balance = self.balance - amount
      emit TokensWithdrawn(amount: amount, from: self.owner?.address)
      return <-create Vault(balance: amount)
    }

    // deposit
    //
    // Function that takes a Vault object as an argument and adds
    // its balance to the balance of the owners Vault.
    // It is allowed to destroy the sent Vault because the Vault
    // was a temporary holder of the tokens. The Vault's balance has
    // been consumed and therefore can be destroyed.
    pub fun deposit(from: @FungibleToken.Vault) {
      let vault <- from as! @LendingController.Vault
      self.balance = self.balance + vault.balance
      emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
      vault.balance = 0.0
      destroy vault
    }

    destroy() {
      LendingController.totalSupply = LendingController.totalSupply - self.balance
    }
  }

  pub fun createEmptyVault(): @FungibleToken.Vault {
    return <-create Vault(balance: 0.0)
  }

  access(contract) fun mintTokens(amount: UFix64): @LendingController.Vault {
    pre {
      amount > UFix64(0): "Amount minted must be greater than zero"
    }
    LendingController.totalSupply = LendingController.totalSupply + amount
    emit TokensMinted(amount: amount)
    return <-create Vault(balance: amount)
  }

  access(contract) fun burnTokens(from: @LendingController.Vault) {
    let vault <- from as! @LendingController.Vault
    let amount = vault.balance
    destroy vault
    emit TokensBurned(amount: amount)
  }

  // Check current pool amounts
  pub fun getPoolAmounts(): PoolAmounts {
    return PoolAmounts(token1Amount: LendingController.token1Vault.balance, token2Amount: LendingController.token2Vault.balance)
  }

  // Get quote for Token1 (given) -> Token2
  pub fun quoteLendingCredit(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token1Amount + amount) * (token2Amount - quote)
    let quote = poolAmounts.token2Amount * amount / (poolAmounts.token1Amount + amount);

    return quote
  }

  //取得借款利率
  pub fun getBorrowingInterest(_ n: Int): UFix64 {
    
    switch n {
      case 1:
          return 0.05 + (self.borrowAmountToken1 / self.balanceToken1)
      case 2:
          return 0.05 + (self.borrowAmountToken2 / self.balanceToken2)
    }

    return 0.05 + (self.borrowAmountToken1 / self.balanceToken1)
  }

  //取得存款利率
  pub fun getSupplingInterest(_ n: Int): UFix64 {
    
    switch n {
      case 1:
          return self.getBorrowingInterest(n) * (self.borrowAmountToken1 / self.balanceToken1)
      case 2:
          return self.getBorrowingInterest(n) * (self.borrowAmountToken2 / self.balanceToken2)
    }

    return self.getBorrowingInterest(n) * (self.borrowAmountToken1 / self.balanceToken1)
  }


  //Supply
  pub fun addLiquidity(_ n: Int, from: @FungibleToken.Vault): @LendingController.Vault {
 
    let liquidityTokenVault <- LendingController.mintTokens(amount: from.balance)

    switch n {
      case 1:
          self.balanceToken1 = self.balanceToken1 + from.balance
          LendingController.token1Vault.deposit(from: <- (from as! @FlowToken.Vault))
          break
      case 2:
          self.balanceToken2 = self.balanceToken2 + from.balance
          LendingController.token2Vault.deposit(from: <- (from as! @TeleportedTetherToken.Vault))
          break
    }

  
    //destroy from
    return <- liquidityTokenVault
  }

  //Withdraw
  pub fun removeLiquidity(_ n: Int, from: @LendingController.Vault): @FungibleToken.Vault {

      //switch n {
      //  case 1:
      //      self.balanceToken1 = self.balanceToken1 - from.balance
      //      return <- LendingController.token1Vault.withdraw(amount: from.balance) 
      //  case 2:
      //      self.balanceToken2 = self.balanceToken2 - from.balance
      //      return <- LendingController.token2Vault.withdraw(amount: from.balance) 
      //}
      
      let a = LendingController.burnTokens(from: <- from)

      

      return <- LendingController.token1Vault.withdraw(amount: 100.0) 
  }

  //Borrow
  pub fun borrowLiquidity(_ n: Int, _ amount: UFix64): @FungibleToken.Vault {
      switch n {
        case 1:
            self.borrowAmountToken1 = self.borrowAmountToken1 + amount
            return <- LendingController.token1Vault.withdraw(amount: amount) 
        case 2:
            self.borrowAmountToken1 = self.borrowAmountToken1 + amount
            return <- LendingController.token2Vault.withdraw(amount: amount) 
      }

      return <- LendingController.token1Vault.withdraw(amount: 100.0) 
  }

  //Repay
  pub fun repayLiquidity(_ n: Int, from: @FungibleToken.Vault){
    switch n {
      case 1:
          self.borrowAmountToken1 = self.borrowAmountToken1 - from.balance
          LendingController.token1Vault.deposit(from: <- (from as! @FlowToken.Vault))
          break
      case 2:
          self.borrowAmountToken1 = self.borrowAmountToken1 - from.balance
          LendingController.token2Vault.deposit(from: <- (from as! @TeleportedTetherToken.Vault))
          break
    }
  }

  //價格更新
  pub fun updateTokenPrice(_ token1price: UFix64,_ token2price: UFix64) {
    self.priceToken1 = token1price
    self.priceToken2 = token2price
  }

  init() {
    self.balanceToken1 = 0.0
    self.balanceToken2 = 0.0

    self.borrowAmountToken1 = 0.0
    self.borrowAmountToken2 = 0.0

    self.priceToken1 = 0.0
    self.priceToken2 = 0.0

    self.depositeLimitToken1 = 1000000.0
    self.depositeLimitToken2 = 1000000.0

    self.totalSupply = 0.0

    self.TokenStoragePath = /storage/LendingControllerVault
    self.TokenPublicBalancePath = /public/LendingControllerBalance
    self.TokenPublicReceiverPath = /public/LendingControllerReceiver

    // Setup internal FlowToken vault
    self.token1Vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault

    // Setup internal TeleportedTetherToken vault
    self.token2Vault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

    // Emit an event that shows that the contract was initialized
    emit TokensInitialized(initialSupply: self.totalSupply)
  }
}