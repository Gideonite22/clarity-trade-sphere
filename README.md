# TradeSphere

A decentralized platform for international trade built on the Stacks blockchain.

## Features
- Create and manage trade agreements between parties
- Handle escrow payments in multiple tokens (STX and supported fungible tokens)
- Track shipment status
- Dispute resolution mechanism
- Trade documentation storage
- Token whitelisting for supported currencies
- Enhanced escrow safety with double-funding prevention

## Usage
The contract provides functionality for:
- Creating trade deals with multiple currency options
- Managing escrow payments in various tokens
- Updating shipment status
- Resolving disputes
- Storing and retrieving trade documents
- Managing supported tokens through admin functions

## Supported Tokens
The platform supports multiple currencies for trade settlement:
- STX (native token)
- Any fungible token added to the supported tokens list by contract admin

### Token Management
- Contract owner can add new supported tokens
- Contract owner can remove tokens from supported list
- Only whitelisted tokens can be used for trades

## Escrow Safety Features
- Prevention of double-funding escrow accounts
- State tracking for funded escrow accounts
- Required funding validation before release

## Contract Functions
See the contract documentation for details on available functions and their usage.
