import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new trade",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(wallet2.address),
        types.uint(1000),
        types.utf8("Shipping to: 123 Trade St")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(0);
  }
});

Clarinet.test({
  name: "Can fund and release escrow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const buyer = accounts.get('wallet_1')!;
    const seller = accounts.get('wallet_2')!;
    
    // Create trade
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(seller.address),
        types.uint(1000),
        types.utf8("Shipping info")
      ], buyer.address)
    ]);

    // Fund escrow
    let escrowBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'fund-escrow', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    escrowBlock.receipts[0].result.expectOk().expectBool(true);

    // Release escrow
    let releaseBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'release-escrow', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    releaseBlock.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Can update trade status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create trade
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(wallet2.address),
        types.uint(1000),
        types.utf8("Shipping info")
      ], wallet1.address)
    ]);

    // Update status
    let statusBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'update-status', [
        types.uint(0),
        types.ascii("SHIPPED")
      ], wallet1.address)
    ]);
    
    statusBlock.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Can raise dispute",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const buyer = accounts.get('wallet_1')!;
    const seller = accounts.get('wallet_2')!;
    
    // Create trade
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(seller.address),
        types.uint(1000),
        types.utf8("Shipping info")
      ], buyer.address)
    ]);

    // Raise dispute
    let disputeBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'raise-dispute', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    disputeBlock.receipts[0].result.expectOk().expectBool(true);
  }
});