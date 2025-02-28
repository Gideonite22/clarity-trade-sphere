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
- Trade expiration and automatic refund mechanism
- Comprehensive status tracking
- Event emission for important state changes

## Trade Lifecycle
1. Trade Creation (STATUS-CREATED)
2. Escrow Funding (STATUS-FUNDED)
3. Trade Completion (STATUS-COMPLETED)
4. Optional: Expiration (STATUS-EXPIRED) or Cancellation (STATUS-CANCELLED)

## Safety Features
- Prevention of double-funding escrow accounts
- Trade expiration after 1440 blocks (~10 days)
- Automatic refund mechanism for expired trades
- Status validation for all operations
- Amount validation
- Event tracking for all major state changes

## Contract Functions
### Admin Functions
- `add-supported-token`: Add new supported token
- `remove-supported-token`: Remove token from supported list

### Trade Functions
- `create-trade`: Create new trade agreement
- `fund-escrow`: Fund trade escrow
- `release-escrow`: Release funds to seller
- `cancel-expired-trade`: Cancel and refund expired trade

### Read Functions
- `get-trade`: Get trade details
- `get-escrow`: Get escrow details
- `is-token-supported`: Check if token is supported

## Event Tracking
The contract emits events for:
- Token management
- Trade creation
- Escrow funding
- Trade completion
- Trade expiration
