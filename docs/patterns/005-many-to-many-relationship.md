# 005 — Many-to-Many Is Just a Relationship

**Script:** [`src/005_many_to_many_relationship.cypher`](../../src/005_many_to_many_relationship.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
`Customer.wishlist` is a comma-separated string of product **names** — the exact anti-pattern the sister repo fixes with a junction table (composite PK + two foreign keys, pattern 010). It's unqueryable ("who wants product X?"), unvalidated, and has no referential integrity.

## The solution
Splits each CSV into product names and creates one `(:Customer)-[:WANTS]->(:Product)` relationship per item, then drops the column. A graph needs **no junction entity at all** — a many-to-many is the default shape of a relationship. `MERGE` makes each pair unique (the graph equivalent of the junction table's composite primary key), and the `Product.name` index from [002](002-indexing-entry-points.md) makes each lookup a seek. Both directions, plus a two-hop "customers who want what you want", become trivial queries.

## Key techniques
`split()` + `trim()`, `UNWIND` to fan a list into rows, `MERGE` for idempotent unique pairs, relationship property (`addedAt`), two-hop traversal for shared-interest recommendations.

## Trade-offs & when *not* to use it
If the association itself needs rich attributes or has to connect more than two parties (an order line = customer + product + quantity + the order it belonged to), a bare relationship isn't enough — reify it into a node ([006](006-intermediate-node.md)). `WANTS` only needs an `addedAt`, so a relationship with one property is exactly right.

---
[← 004 Property → node](004-property-to-node.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 006 Intermediate (reified) nodes](006-intermediate-node.md)
