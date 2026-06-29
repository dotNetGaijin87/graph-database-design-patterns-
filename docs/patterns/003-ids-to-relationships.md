# 003 — Foreign Keys → Relationships

**Script:** [`src/003_ids_to_relationships.cypher`](../../src/003_ids_to_relationships.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
The naive `Review` nodes are islands: they point at their author and product with id **properties** (`authorId`, `productId`) — foreign keys copied straight out of a relational schema. "Give me the reviews of product P001" can't traverse; it has to scan every `Review` and compare a string. There is no path in the graph.

## The solution
Turns the two id properties into two real relationships — `(:Customer)-[:WROTE]->(:Review)-[:REVIEWS]->(:Product)` — then drops the redundant properties. The same question is now a single hop that works in **both** directions (product → its reviews, customer → everything they reviewed). This is the defining graph pattern: **relationships are first-class citizens**, not strings.

## Key techniques
`MATCH` by indexed key, `MERGE` relationships, `REMOVE` properties, bidirectional traversal, the casing convention (`PascalCase` labels / `UPPER_SNAKE` types / `camelCase` keys) as a design smell test.

## Trade-offs & when *not* to use it
Relationships are stored as direct pointers, so traversing them doesn't slow down as the graph grows — unlike a relational join, whose cost rises with table size. The flip side: a relationship connects exactly two nodes. The moment a "connection" needs its own attributes or has to tie together more than two things, you reify it into a node — see [006](006-intermediate-node.md). And don't reflexively delete *every* id: keep a foreign-key-like id alongside the relationship when an external integration, event log, audit trail or immutable snapshot needs a stable reference independent of the graph — a `(:Payment)` may legitimately keep `customerId` for reconciliation even though `(:Customer)-[:MADE]->(:Payment)` exists.

---
[← 002 Indexing traversal entry points](002-indexing-entry-points.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 004 Property → node](004-property-to-node.md)
