;; Independent Author Publishing Platform Smart Contract
;; A platform for writers to showcase published works, peer reviews, and literary collaborations

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-scope (err u104))

;; Publication scope levels
(define-constant SCOPE-PUBLIC u0)
(define-constant SCOPE-PUBLISHED-AUTHORS u1)
(define-constant SCOPE-PRIVATE u2)

;; Data Variables
(define-data-var royalty-fee uint u750) ;; 0.075% fee in basis points

;; Data Maps

;; Author profiles
(define-map author-profiles
  { author: principal }
  {
    pen-name: (string-ascii 100),
    writing-genres: (string-ascii 200),
    author-location: (string-ascii 100),
    profile-scope: uint,
    debut-date: uint,
    is-published: bool
  }
)

;; Published works
(define-map published-works
  { author: principal, work-id: uint }
  {
    book-title: (string-ascii 100),
    genre-category: (string-ascii 100),
    publication-date: uint,
    draft-date: (optional uint),
    work-summary: (string-ascii 500),
    scope-level: uint,
    archived-at: uint
  }
)

;; Author work counters
(define-map author-work-count
  { author: principal }
  { count: uint }
)

;; Writing credentials
(define-map writing-credentials
  { author: principal, credential-id: uint }
  {
    award-title: (string-ascii 100),
    granting-institution: (string-ascii 100),
    awarded-date: uint,
    valid-until: (optional uint),
    credential-hash: (buff 32),
    scope-level: uint,
    is-verified: bool,
    archived-at: uint
  }
)

;; Author credential counters
(define-map author-credential-count
  { author: principal }
  { count: uint }
)

;; Peer reviews
(define-map peer-reviews
  { author: principal, review-id: uint }
  {
    genre-focus: (string-ascii 50),
    reviewing-author: principal,
    review-content: (string-ascii 300),
    reviewed-at: uint
  }
)

;; Author review counters
(define-map author-review-count
  { author: principal }
  { count: uint }
)

;; Literary collaborations
(define-map literary-collaborations
  { author1: principal, author2: principal }
  {
    collaboration-status: (string-ascii 20), ;; "pending", "active", "completed"
    initiated-by: principal,
    started-at: uint
  }
)

;; Genre endorsement counts
(define-map genre-endorsements
  { author: principal, genre: (string-ascii 50) }
  { count: uint }
)

;; Read-only functions

;; Get author profile
(define-read-only (get-author-profile (author principal))
  (map-get? author-profiles { author: author })
)

;; Get published work
(define-read-only (get-published-work (author principal) (work-id uint))
  (map-get? published-works { author: author, work-id: work-id })
)

;; Get writing credential
(define-read-only (get-writing-credential (author principal) (credential-id uint))
  (map-get? writing-credentials { author: author, credential-id: credential-id })
)

;; Get peer review
(define-read-only (get-peer-review (author principal) (review-id uint))
  (map-get? peer-reviews { author: author, review-id: review-id })
)

;; Get collaboration status
(define-read-only (get-collaboration-status (author1 principal) (author2 principal))
  (map-get? literary-collaborations { author1: author1, author2: author2 })
)

;; Get genre endorsement count
(define-read-only (get-genre-endorsement-count (author principal) (genre (string-ascii 50)))
  (default-to u0 (get count (map-get? genre-endorsements { author: author, genre: genre })))
)

;; Check if authors are collaborating
(define-read-only (are-authors-collaborating (author1 principal) (author2 principal))
  (let ((collaboration1 (map-get? literary-collaborations { author1: author1, author2: author2 }))
        (collaboration2 (map-get? literary-collaborations { author1: author2, author2: author1 })))
    (or
      (and (is-some collaboration1) (is-eq (get collaboration-status (unwrap-panic collaboration1)) "active"))
      (and (is-some collaboration2) (is-eq (get collaboration-status (unwrap-panic collaboration2)) "active"))
    )
  )
)

;; Check if author can view private content
(define-read-only (can-view-private-content (owner principal) (viewer principal) (scope-level uint))
  (or
    (is-eq owner viewer)
    (is-eq scope-level SCOPE-PUBLIC)
    (and 
      (is-eq scope-level SCOPE-PUBLISHED-AUTHORS)
      (are-authors-collaborating owner viewer)
    )
  )
)

;; Public functions

;; Create author profile
(define-public (create-author-profile (pen-name (string-ascii 100)) (writing-genres (string-ascii 200)) (author-location (string-ascii 100)) (profile-scope uint))
  (begin
    (asserts! (<= profile-scope SCOPE-PRIVATE) err-invalid-scope)
    (ok (map-set author-profiles
      { author: tx-sender }
      {
        pen-name: pen-name,
        writing-genres: writing-genres,
        author-location: author-location,
        profile-scope: profile-scope,
        debut-date: block-height,
        is-published: false
      }
    ))
  )
)

;; Add published work
(define-public (add-published-work (book-title (string-ascii 100)) (genre-category (string-ascii 100)) (publication-date uint) (draft-date (optional uint)) (work-summary (string-ascii 500)) (scope-level uint))
  (let ((current-count (default-to u0 (get count (map-get? author-work-count { author: tx-sender })))))
    (begin
      (asserts! (<= scope-level SCOPE-PRIVATE) err-invalid-scope)
      (map-set published-works
        { author: tx-sender, work-id: current-count }
        {
          book-title: book-title,
          genre-category: genre-category,
          publication-date: publication-date,
          draft-date: draft-date,
          work-summary: work-summary,
          scope-level: scope-level,
          archived-at: block-height
        }
      )
      (map-set author-work-count
        { author: tx-sender }
        { count: (+ current-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Add writing credential
(define-public (add-writing-credential (award-title (string-ascii 100)) (granting-institution (string-ascii 100)) (awarded-date uint) (valid-until (optional uint)) (credential-hash (buff 32)) (scope-level uint))
  (let ((current-count (default-to u0 (get count (map-get? author-credential-count { author: tx-sender })))))
    (begin
      (asserts! (<= scope-level SCOPE-PRIVATE) err-invalid-scope)
      (map-set writing-credentials
        { author: tx-sender, credential-id: current-count }
        {
          award-title: award-title,
          granting-institution: granting-institution,
          awarded-date: awarded-date,
          valid-until: valid-until,
          credential-hash: credential-hash,
          scope-level: scope-level,
          is-verified: false,
          archived-at: block-height
        }
      )
      (map-set author-credential-count
        { author: tx-sender }
        { count: (+ current-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Send collaboration request
(define-public (send-collaboration-request (target-author principal))
  (begin
    (asserts! (not (is-eq tx-sender target-author)) err-unauthorized)
    (asserts! (is-none (map-get? literary-collaborations { author1: tx-sender, author2: target-author })) err-already-exists)
    (asserts! (is-none (map-get? literary-collaborations { author1: target-author, author2: tx-sender })) err-already-exists)
    (ok (map-set literary-collaborations
      { author1: tx-sender, author2: target-author }
      {
        collaboration-status: "pending",
        initiated-by: tx-sender,
        started-at: block-height
      }
    ))
  )
)

;; Accept collaboration request
(define-public (accept-collaboration-request (requesting-author principal))
  (let ((collaboration (map-get? literary-collaborations { author1: requesting-author, author2: tx-sender })))
    (begin
      (asserts! (is-some collaboration) err-not-found)
      (asserts! (is-eq (get collaboration-status (unwrap-panic collaboration)) "pending") err-unauthorized)
      (ok (map-set literary-collaborations
        { author1: requesting-author, author2: tx-sender }
        {
          collaboration-status: "active",
          initiated-by: requesting-author,
          started-at: (get started-at (unwrap-panic collaboration))
        }
      ))
    )
  )
)

;; Submit peer review
(define-public (submit-peer-review (author principal) (genre-focus (string-ascii 50)) (review-content (string-ascii 300)))
  (let ((current-count (default-to u0 (get count (map-get? author-review-count { author: author }))))
        (current-genre-count (default-to u0 (get count (map-get? genre-endorsements { author: author, genre: genre-focus })))))
    (begin
      (asserts! (not (is-eq tx-sender author)) err-unauthorized)
      (asserts! (are-authors-collaborating tx-sender author) err-unauthorized)
      (map-set peer-reviews
        { author: author, review-id: current-count }
        {
          genre-focus: genre-focus,
          reviewing-author: tx-sender,
          review-content: review-content,
          reviewed-at: block-height
        }
      )
      (map-set author-review-count
        { author: author }
        { count: (+ current-count u1) }
      )
      (map-set genre-endorsements
        { author: author, genre: genre-focus }
        { count: (+ current-genre-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Verify writing credential (admin only)
(define-public (verify-writing-credential (author principal) (credential-id uint))
  (let ((credential (map-get? writing-credentials { author: author, credential-id: credential-id })))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (is-some credential) err-not-found)
      (ok (map-set writing-credentials
        { author: author, credential-id: credential-id }
        (merge (unwrap-panic credential) { is-verified: true })
      ))
    )
  )
)

;; Verify published author (admin only)
(define-public (verify-published-author (author principal))
  (let ((profile (map-get? author-profiles { author: author })))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (is-some profile) err-not-found)
      (ok (map-set author-profiles
        { author: author }
        (merge (unwrap-panic profile) { is-published: true })
      ))
    )
  )
)

;; Update royalty fee (admin only)
(define-public (update-royalty-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set royalty-fee new-fee)
    (ok true)
  )
)