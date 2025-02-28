import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can add and remove supported tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const tokenContract = accounts.get('wallet_3')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'add-supported-token', [
        types.principal(tokenContract.address)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);

    let removeBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'remove-supported-token', [
        types.principal(tokenContract.address)
      ], deployer.address)
    ]);
    
    removeBlock.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Cannot create trade with zero amount",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    const seller = accounts.get('wallet_2')!;
    const tokenContract = accounts.get('wallet_3')!;
    
    chain.mineBlock([
      Tx.contractCall('trade_sphere', 'add-supported-token', [
        types.principal(tokenContract.address)
      ], deployer.address)
    ]);
    
    let block = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'create-trade', [
        types.principal(seller.address),
        types.uint(0),
        types.principal(tokenContract.address),
        types.utf8("Shipping to: 123 Trade St")
      ], buyer.address)
    ]);
    
    block.receipts[0].result.expectErr(106); // err-invalid-amount
  }
});

Clarinet.test({
  name: "Can create and complete valid trade",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    const seller = accounts.get('wallet_2')!;
    const tokenContract = accounts.get('wallet_3')!;
    
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
    
    createBlock.receipts[0].result.expectOk().expectUint(0);
    
    let fundBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'fund-escrow', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    fundBlock.receipts[0].result.expectOk().expectBool(true);
    
    let releaseBlock = chain.mineBlock([
      Tx.contractCall('trade_sphere', 'release-escrow', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    releaseBlock.receipts[0].result.expectOk().expectBool(true);
  }
});
