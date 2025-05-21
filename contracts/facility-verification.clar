;; Facility Verification Contract
;; Validates commercial buildings for participation in the energy efficiency marketplace

(define-data-var admin principal tx-sender)

;; Facility data structure
(define-map facilities
  { facility-id: uint }
  {
    owner: principal,
    location: (string-utf8 100),
    square-footage: uint,
    building-type: (string-utf8 50),
    verified: bool,
    verifier: (optional principal),
    verification-date: (optional uint)
  }
)

;; Authorized verifiers
(define-map verifiers
  { verifier: principal }
  { authorized: bool }
)

;; Events
(define-public (register-facility (facility-id uint) (location (string-utf8 100)) (square-footage uint) (building-type (string-utf8 50)))
  (let
    ((caller tx-sender))
    (asserts! (not (default-to false (get verified (map-get? facilities { facility-id: facility-id })))) (err u1))
    (ok (map-set facilities
      { facility-id: facility-id }
      {
        owner: caller,
        location: location,
        square-footage: square-footage,
        building-type: building-type,
        verified: false,
        verifier: none,
        verification-date: none
      }
    ))
  )
)

(define-public (verify-facility (facility-id uint))
  (let
    ((caller tx-sender)
     (facility (unwrap! (map-get? facilities { facility-id: facility-id }) (err u2)))
     (is-verifier (default-to false (get authorized (map-get? verifiers { verifier: caller })))))

    (asserts! is-verifier (err u3))
    (asserts! (not (get verified facility)) (err u4))

    (ok (map-set facilities
      { facility-id: facility-id }
      (merge facility {
        verified: true,
        verifier: (some caller),
        verification-date: (some block-height)
      })
    ))
  )
)

;; Admin functions
(define-public (add-verifier (verifier principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u5))
    (ok (map-set verifiers { verifier: verifier } { authorized: true }))
  )
)

(define-public (remove-verifier (verifier principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u6))
    (ok (map-set verifiers { verifier: verifier } { authorized: false }))
  )
)

(define-public (transfer-admin (new-admin principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u7))
    (ok (var-set admin new-admin))
  )
)

;; Read-only functions
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id })
)

(define-read-only (is-facility-verified (facility-id uint))
  (default-to false (get verified (map-get? facilities { facility-id: facility-id })))
)

(define-read-only (is-verifier (address principal))
  (default-to false (get authorized (map-get? verifiers { verifier: address })))
)
