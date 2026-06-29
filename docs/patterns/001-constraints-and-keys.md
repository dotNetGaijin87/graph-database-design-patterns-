# 001 — Constraints & Node Keys (Identity)

**Script:** [`src/001_constraints_and_keys.cypher`](../../src/001_constraints_and_keys.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
The naive graph has no notion of identity — nothing stops two `(:Customer)` nodes sharing a `customerId`, or two products colliding on `productId`. This is the graph equivalent of a table with no primary key.

## The solution
Declares **uniqueness constraints** on the business keys (`Customer.customerId`, `Customer.email`, `Product.productId`, `Review.reviewId`). Each constraint rejects duplicates **and** transparently builds a backing range index, so it does double duty as the fast single-node lookup that every traversal starts from. A commented `CREATE` shows the constraint now rejecting a duplicate.

## Key techniques
`CREATE CONSTRAINT ... IF NOT EXISTS FOR (n:Label) REQUIRE n.prop IS UNIQUE`, `SHOW CONSTRAINTS`, constraint-backed indexes.

## Trade-offs & when *not* to use it
On **Neo4j Community** (what the bundled Docker image runs) you only get uniqueness constraints. **Node key** constraints (composite + mandatory) and property **existence** constraints are Enterprise-only — in Community you compose `IS UNIQUE` with an application-level not-null check. Constraints are also single-label and never span relationships, so cross-node invariants still live in your write queries (usually a `MERGE`).

---
[← 000 Initial graph](000-initial-graph.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 002 Indexing traversal entry points](002-indexing-entry-points.md)
