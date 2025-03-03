;; TradeSphere - Decentralized International Trade Platform

[Previous constants and data structures remain unchanged...]

;; Modified cancel-expired-trade function with security fix
(define-public (cancel-expired-trade (trade-id uint))
    (let (
        (trade (unwrap! (map-get? trades {trade-id: trade-id}) err-invalid-trade))
        (escrow-data (unwrap! (map-get? escrow {trade-id: trade-id}) err-invalid-trade))
    )
    (asserts! (is-trade-expired trade-id) err-invalid-state)
    (asserts! (get funded escrow-data) err-invalid-state)
    (asserts! (not (get released escrow-data)) err-invalid-state)
    (asserts! (is-eq (get status trade) STATUS-FUNDED) err-invalid-state)
    (begin
        (try! (as-contract (transfer-token
            (get token-contract escrow-data)
            (get amount escrow-data)
            (as-contract tx-sender)  ;; Fixed: Using contract address as sender
            (get buyer trade)
        )))
        (print { event: "trade-expired", trade-id: trade-id })
        (map-set trades
            {trade-id: trade-id}
            (merge trade { status: STATUS-EXPIRED })
        )
        (map-set escrow
            {trade-id: trade-id}
            (merge escrow-data { released: true })  ;; Prevent double-release
        )
        (ok true)
    ))
)

[Rest of contract remains unchanged...]
