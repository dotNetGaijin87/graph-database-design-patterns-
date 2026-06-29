# 000 — Initial Graph & Diagnostic Tooling

**Script:** [`src/000_initial_graph.cypher`](../../src/000_initial_graph.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
A greenfield app needs a starting graph — and, just as importantly, the introspection tooling every later lesson relies on to *prove* a refactoring actually happened. Unlike a relational database, a property graph has no separate DDL step: the "initial schema" and its seed data are created together, so this one file plays the role of both `000_initial_schema_creation.sql` **and** `seed_db.sql` in the sister repo.

## The solution
Creates the `OnlineStore` graph in a **deliberately naive shape** that carries relational habits into Neo4j, so the 12 migrations have real anti-patterns to fix: no constraints/indexes; relationships faked as id properties (`Review.authorId`, `ORDERED.orderId`); repeated strings instead of nodes (`vendorName`, `state`); a `"/"`-delimited category path; a CSV `wishlist`; orders flattened onto `Customer→Product` edges; and subtype attributes as nullable properties. It then runs a set of diagnostic queries — label/relationship counts, `db.schema.visualization()`, `apoc.meta.stats()`, `SHOW CONSTRAINTS`/`SHOW INDEXES` — to capture the baseline.

## Key techniques
`UNWIND` over lists of maps with `SET n = row`, `date()` literals, naive relationships with properties, deliberately disconnected ("island") nodes, `CALL db.schema.visualization()`, `apoc.meta.stats()`, `SHOW CONSTRAINTS` / `SHOW INDEXES`, a `(:_Migration)` audit node.

## Trade-offs & when *not* to use it
The embedded anti-patterns are teaching scaffolding, not a recommended starting design. The single biggest tell is the disconnected `Review` nodes: storing `authorId`/`productId` as properties means the graph isn't actually a graph yet — there's nothing to traverse until [003](003-ids-to-relationships.md) turns those ids into relationships.

---
[Pattern index](../../README.md#the-12-patterns) · [next → 001 Constraints & node keys](001-constraints-and-keys.md)
