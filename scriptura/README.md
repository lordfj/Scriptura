# 📚 Scriptura

**Scriptura** is a decentralized smart contract platform that empowers independent authors to publish literary works, manage writing credentials, receive peer reviews, and collaborate with fellow writers. Built on Clarity for secure and transparent author-driven publishing.

---

## ✨ Features

- 📖 **Author Profiles**: Register pen names, genres, and literary background with flexible visibility.
- 📘 **Published Works**: Track published and draft works with visibility controls and archival support.
- 🏅 **Writing Credentials**: Showcase verified literary awards or credentials.
- ✍️ **Peer Reviews**: Writers can review one another’s work in a structured and transparent manner.
- 🤝 **Literary Collaborations**: Facilitate creative partnerships with status tracking.
- 📈 **Genre Endorsements**: Allow community recognition of genre expertise.

---

## 📐 Data Structures

- **`author-profiles`**: Stores pen name, genres, location, and scope.
- **`published-works`**: Stores title, genre, summary, publication/draft dates, and scope level.
- **`writing-credentials`**: Stores awards or credentials, issuing body, date, hash, and verification state.
- **`peer-reviews`**: Stores genre, review content, and reviewer details.
- **`literary-collaborations`**: Tracks collaboration status between two authors.
- **`genre-endorsements`**: Tracks how often an author is endorsed per genre.

---

## 🧠 Access Control & Privacy

- **Scope Levels**:
  - `SCOPE-PUBLIC (u0)`: Visible to all.
  - `SCOPE-PUBLISHED-AUTHORS (u1)`: Only visible to verified published authors.
  - `SCOPE-PRIVATE (u2)`: Private to the author.

- **Owner-Only Actions**: Some admin functions are restricted to the contract deployer.

---

## 🛠 Deployment

```clarity
(define-constant contract-owner tx-sender)
