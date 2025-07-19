;; Bonus Delay - Performance Bonus Release Contract
;; A time-locked contract for releasing performance bonuses after specified delays

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-time-not-reached (err u104))
(define-constant err-already-claimed (err u105))
(define-constant err-performance-not-met (err u106))

;; Data Variables
(define-data-var next-bonus-id uint u1)

;; Data Maps
(define-map bonuses
  { bonus-id: uint }
  {
    employee: principal,
    amount: uint,
    performance-target: uint,
    actual-performance: uint,
    release-time: uint,
    created-time: uint,
    claimed: bool,
    active: bool
  }
)

(define-map employee-bonuses
  { employee: principal }
  { bonus-count: uint }
)

;; Private Functions
(define-private (get-current-time)
  block-height
)

;; Read-only Functions
(define-read-only (get-bonus (bonus-id uint))
  (map-get? bonuses { bonus-id: bonus-id })
)

(define-read-only (get-employee-bonus-count (employee principal))
  (default-to u0 
    (get bonus-count 
      (map-get? employee-bonuses { employee: employee })
    )
  )
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (is-bonus-claimable (bonus-id uint))
  (match (map-get? bonuses { bonus-id: bonus-id })
    bonus-data
    (and 
      (get active bonus-data)
      (not (get claimed bonus-data))
      (>= (get-current-time) (get release-time bonus-data))
      (>= (get actual-performance bonus-data) (get performance-target bonus-data))
    )
    false
  )
)

;; Public Functions
(define-public (create-bonus 
  (employee principal) 
  (amount uint) 
  (performance-target uint) 
  (delay-blocks uint)
)
  (let 
    (
      (bonus-id (var-get next-bonus-id))
      (current-time (get-current-time))
      (release-time (+ current-time delay-blocks))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) (err u107))
    (asserts! (> performance-target u0) (err u108))
    (asserts! (> delay-blocks u0) (err u109))
    
    ;; Create bonus entry
    (map-set bonuses
      { bonus-id: bonus-id }
      {
        employee: employee,
        amount: amount,
        performance-target: performance-target,
        actual-performance: u0,
        release-time: release-time,
        created-time: current-time,
        claimed: false,
        active: true
      }
    )
    
    ;; Update employee bonus count
    (map-set employee-bonuses
      { employee: employee }
      { bonus-count: (+ (get-employee-bonus-count employee) u1) }
    )
    
    ;; Increment next bonus ID
    (var-set next-bonus-id (+ bonus-id u1))
    
    (ok bonus-id)
  )
)

(define-public (fund-contract (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (stx-transfer? amount tx-sender (as-contract tx-sender))
  )
)

(define-public (update-performance (bonus-id uint) (actual-performance uint))
  (let 
    (
      (bonus-data (unwrap! (map-get? bonuses { bonus-id: bonus-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active bonus-data) (err u110))
    (asserts! (not (get claimed bonus-data)) err-already-claimed)
    
    (map-set bonuses
      { bonus-id: bonus-id }
      (merge bonus-data { actual-performance: actual-performance })
    )
    
    (ok true)
  )
)

(define-public (claim-bonus (bonus-id uint))
  (let 
    (
      (bonus-data (unwrap! (map-get? bonuses { bonus-id: bonus-id }) err-not-found))
      (employee (get employee bonus-data))
      (amount (get amount bonus-data))
    )
    ;; Check if caller is the employee
    (asserts! (is-eq tx-sender employee) (err u111))
    
    ;; Check if bonus is active and not claimed
    (asserts! (get active bonus-data) (err u112))
    (asserts! (not (get claimed bonus-data)) err-already-claimed)
    
    ;; Check if time has passed
    (asserts! (>= (get-current-time) (get release-time bonus-data)) err-time-not-reached)
    
    ;; Check if performance target is met
    (asserts! (>= (get actual-performance bonus-data) (get performance-target bonus-data)) err-performance-not-met)
    
    ;; Check contract has sufficient balance
    (asserts! (>= (get-contract-balance) amount) err-insufficient-funds)
    
    ;; Mark bonus as claimed
    (map-set bonuses
      { bonus-id: bonus-id }
      (merge bonus-data { claimed: true })
    )
    
    ;; Transfer the bonus
    (as-contract (stx-transfer? amount tx-sender employee))
  )
)

(define-public (cancel-bonus (bonus-id uint))
  (let 
    (
      (bonus-data (unwrap! (map-get? bonuses { bonus-id: bonus-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active bonus-data) (err u113))
    (asserts! (not (get claimed bonus-data)) err-already-claimed)
    
    (map-set bonuses
      { bonus-id: bonus-id }
      (merge bonus-data { active: false })
    )
    
    (ok true)
  )
)

(define-public (withdraw-unused-funds (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= (get-contract-balance) amount) err-insufficient-funds)
    (as-contract (stx-transfer? amount tx-sender contract-owner))
  )
)

;; Initialize contract
(begin
  (print "Bonus Delay Performance Contract deployed successfully")
)