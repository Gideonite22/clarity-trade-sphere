;; TradeSphere - Decentralized International Trade Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-trade (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-state (err u103))

;; Data Variables
(define-map trades
    { trade-id: uint }
    {
        buyer: principal,
        seller: principal,
        amount: uint,
        status: (string-ascii 20),
        shipping-info: (string-utf8 500),
        documents: (string-utf8 1000),
        dispute: bool
    }
)

(define-map escrow
    { trade-id: uint }
    {
        amount: uint,
        released: bool
    }
)

;; Trade Counter
(define-data-var trade-counter uint u0)

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

;; Public Functions

;; Create new trade
(define-public (create-trade (seller principal) (amount uint) (shipping-info (string-utf8 500)))
    (let (
        (trade-id (var-get trade-counter))
    )
    (begin
        (map-set trades
            {trade-id: trade-id}
            {
                buyer: tx-sender,
                seller: seller,
                amount: amount,
                status: "CREATED",
                shipping-info: shipping-info,
                documents: "",
                dispute: false
            }
        )
        (map-set escrow
            {trade-id: trade-id}
            {
                amount: u0,
                released: false
            }
        )
        (var-set trade-counter (+ trade-id u1))
        (ok trade-id)
    ))
)

;; Fund escrow
(define-public (fund-escrow (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
    )
    (if (is-eq tx-sender (get buyer trade))
        (begin
            (try! (stx-transfer? (get amount trade) tx-sender (as-contract tx-sender)))
            (map-set escrow
                {trade-id: trade-id}
                {
                    amount: (get amount trade),
                    released: false
                }
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Update shipping status
(define-public (update-status (trade-id uint) (new-status (string-ascii 20)))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
    )
    (if (is-trade-participant trade-id tx-sender)
        (begin
            (map-set trades
                {trade-id: trade-id}
                (merge trade {status: new-status})
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Add trade documents
(define-public (add-documents (trade-id uint) (documents (string-utf8 1000)))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
    )
    (if (is-trade-participant trade-id tx-sender)
        (begin
            (map-set trades
                {trade-id: trade-id}
                (merge trade {documents: documents})
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
    (if (and (is-eq tx-sender (get buyer trade)) (not (get released escrow-data)))
        (begin
            (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get seller trade))))
            (map-set escrow
                {trade-id: trade-id}
                (merge escrow-data {released: true})
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Raise dispute
(define-public (raise-dispute (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
    )
    (if (is-trade-participant trade-id tx-sender)
        (begin
            (map-set trades
                {trade-id: trade-id}
                (merge trade {dispute: true})
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Read-only functions

(define-read-only (get-trade (trade-id uint))
    (ok (map-get? trades {trade-id: trade-id}))
)

(define-read-only (get-escrow (trade-id uint))
    (ok (map-get? escrow {trade-id: trade-id}))
)