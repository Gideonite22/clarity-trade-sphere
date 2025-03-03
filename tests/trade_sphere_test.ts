[Previous test imports and initial tests remain unchanged...]

Clarinet.test({
  name: "Can properly handle expired trade cancellation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    const seller = accounts.get('wallet_2')!;
    const tokenContract = accounts.get('wallet_3')!;
    
    // Setup trade
    chain.mineBlock([
      Tx.contractCall('trade_sphere', 'add-supported-token', [
        types.principal(tokenContract.address)
      ], deployer.address)
    ]);
    
    let createBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(seller.address),
        types.uint(1000),
        types.principal(tokenContract.address),
        types.utf8("Shipping to: 123 Trade St")
      ], buyer.address)
    ]);
    
    // Fund escrow
    let fundBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'fund-escrow', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    // Simulate expiration by mining blocks
    for (let i = 0; i < 1441; i++) {
      chain.mineBlock([]);
    }
    
    // Cancel expired trade
    let cancelBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'cancel-expired-trade', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    cancelBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify cannot cancel again
    let secondCancel = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'cancel-expired-trade', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    secondCancel.receipts[0].result.expectErr(103); // err-invalid-state
  }
});
