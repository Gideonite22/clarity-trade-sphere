;; TradeSphere - Decentralized International Trade Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-trade (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-state (err u103))
(define-constant err-invalid-token (err u104))
(define-constant err-already-funded (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-expired (err u107))

;; Trade Status Values
(define-constant STATUS-CREATED "CREATED")
(define-constant STATUS-FUNDED "FUNDED")
(define-constant STATUS-COMPLETED "COMPLETED")
(define-constant STATUS-CANCELLED "CANCELLED")
(define-constant STATUS-EXPIRED "EXPIRED")

;; Configuration
(define-constant TRADE-EXPIRY-BLOCKS u1440) ;; ~10 days at 10min/block

;; Data Variables
(define-map trades
    { trade-id: uint }
    {
        buyer: principal,
        seller: principal,
        amount: uint,
        token-contract: principal,
        status: (string-ascii 20),
        shipping-info: (string-utf8 500),
        documents: (string-utf8 1000),
        dispute: bool,
        created-at: uint
    }
)

(define-map escrow
    { trade-id: uint }
    {
        amount: uint,
        token-contract: principal, 
        released: bool,
        funded: bool,
        funded-at: uint
    }
)

;; Trade Counter
(define-data-var trade-counter uint u0)

;; Supported Token List
(define-map supported-tokens
    { token: principal }
    { active: bool }
)

;; Private Functions
(define-private (is-trade-participant (trade-id uint) (participant principal))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) false))
    )
    (or 
        (is-eq (get buyer trade) participant)
        (is-eq (get seller trade) participant)
    ))
)

(define-private (transfer-token (token principal) (amount uint) (sender principal) (recipient principal))
    (contract-call? token transfer amount sender recipient none)
)

(define-private (is-trade-expired (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) false))
        (current-block block-height)
    )
    (> current-block (+ (get created-at trade) TRADE-EXPIRY-BLOCKS))
    )
)

;; Admin Functions
(define-public (add-supported-token (token-contract principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (print { event: "token-added", token: token-contract })
        (ok (map-set supported-tokens 
            {token: token-contract}
            {active: true}
        ))
    )
)

(define-public (remove-supported-token (token-contract principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (print { event: "token-removed", token: token-contract })
        (ok (map-set supported-tokens
            {token: token-contract}
            {active: false}  
        ))
    )
)

;; Public Functions

;; Create new trade with specified token
(define-public (create-trade (seller principal) (amount uint) (token-contract principal) (shipping-info (string-utf8 500)))
    (let (
        (trade-id (var-get trade-counter))
        (token-support (unwrap! (map-get? supported-tokens {token: token-contract}) err-invalid-token))
    )
    (asserts! (get active token-support) err-invalid-token)
    (asserts! (> amount u0) err-invalid-amount)
    (begin
        (print { event: "trade-created", trade-id: trade-id, buyer: tx-sender, seller: seller, amount: amount })
        (map-set trades
            {trade-id: trade-id}
            {
                buyer: tx-sender,
                seller: seller,
                amount: amount,
                token-contract: token-contract,
                status: STATUS-CREATED,
                shipping-info: shipping-info,
                documents: "",
                dispute: false,
                created-at: block-height
            }
        )
        (map-set escrow
            {trade-id: trade-id}
            {
                amount: u0,
                token-contract: token-contract,
                released: false,
                funded: false,
                funded-at: u0
            }
        )
        (var-set trade-counter (+ trade-id u1))
        (ok trade-id)
    ))
)

;; Fund escrow with specified token
(define-public (fund-escrow (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
        (escrow-data (unwrap! (map-get? escrow {trade-id: trade-id}) err-invalid-trade))
    )
    (asserts! (not (get funded escrow-data)) err-already-funded)
    (asserts! (is-eq (get status trade) STATUS-CREATED) err-invalid-state)
    (asserts! (not (is-trade-expired trade-id)) err-expired)
    (if (is-eq tx-sender (get buyer trade))
        (begin
            (try! (transfer-token (get token-contract trade) (get amount trade) tx-sender (as-contract tx-sender)))
            (print { event: "escrow-funded", trade-id: trade-id, amount: (get amount trade) })
            (map-set escrow
                {trade-id: trade-id}
                {
                    amount: (get amount trade),
                    token-contract: (get token-contract trade),
                    released: false,
                    funded: true,
                    funded-at: block-height
                }
            )
            (map-set trades
                {trade-id: trade-id}
                (merge trade { status: STATUS-FUNDED })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Release escrow
(define-public (release-escrow (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
        (escrow-data (unwrap! (map-get? escrow {trade-id: trade-id}) err-invalid-trade))
    )
    (asserts! (get funded escrow-data) err-invalid-state)
    (asserts! (is-eq (get status trade) STATUS-FUNDED) err-invalid-state)
    (if (and (is-eq tx-sender (get buyer trade)) (not (get released escrow-data)))
        (begin
            (try! (as-contract (transfer-token 
                (get token-contract escrow-data)
                (get amount escrow-data)
                tx-sender
                (get seller trade)
            )))
            (print { event: "escrow-released", trade-id: trade-id, amount: (get amount escrow-data) })
            (map-set escrow
                {trade-id: trade-id}
                (merge escrow-data {released: true})
            )
            (map-set trades
                {trade-id: trade-id}
                (merge trade { status: STATUS-COMPLETED })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Cancel expired trade and refund
(define-public (cancel-expired-trade (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
        (escrow-data (unwrap! (map-get? escrow {trade-id: trade-id}) err-invalid-trade))
    )
    (asserts! (is-trade-expired trade-id) err-invalid-state)
    (asserts! (get funded escrow-data) err-invalid-state)
    (asserts! (not (get released escrow-data)) err-invalid-state)
    (begin
        (try! (as-contract (transfer-token
            (get token-contract escrow-data)
            (get amount escrow-data)
            tx-sender
            (get buyer trade)
        )))
        (print { event: "trade-expired", trade-id: trade-id })
        (map-set trades
            {trade-id: trade-id}
            (merge trade { status: STATUS-EXPIRED })
        )
        (ok true)
    ))
)

;; Read-only functions

(define-read-only (get-trade (trade-id uint))
    (ok (map-get? trades {trade-id: trade-id}))
)

(define-read-only (get-escrow (trade-id uint))
    (ok (map-get? escrow {trade-id: trade-id}))
)

(define-read-only (is-token-supported (token principal))
    (ok (map-get? supported-tokens {token: token}))
)
