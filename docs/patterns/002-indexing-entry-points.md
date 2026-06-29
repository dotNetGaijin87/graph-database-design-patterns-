# 002 — Indexing Traversal Entry Points

**Script:** [`src/002_indexing_entry_points.cypher`](../../src/002_indexing_entry_points.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
A graph is cheap to *walk*, but you still have to find somewhere to *start*. That anchor set is located by an index or, failing that, by a full label scan over every node of a label. Anchoring a query on an unindexed property (`Product.name`) plans as a `NodeByLabelScan` + `Filter`.

## The solution
Creates a **range index** on `Product.name` (equality, range and prefix predicates) and a **text index** on the same property (`CONTAINS` / `ENDS WITH` substring search — which a range index can't serve), plus an entry-point index on `Customer.name`. `EXPLAIN` before and `PROFILE` after show the plan flip from `NodeByLabelScan` to `NodeIndexSeek` (verified: the planner reports `RANGE INDEX p:Product(name)`).

## Key techniques
`CREATE INDEX`, `CREATE TEXT INDEX`, `EXPLAIN` vs `PROFILE`, reading db-hits, `SHOW INDEXES`, range vs text index selection.

## Trade-offs & when *not* to use it
Indexes speed reads but cost write throughput and storage — index the **entry points** of your traversals, not every property. Once you've anchored and started following relationships, the graph chases pointers and no index is consulted, so indexing interior properties buys nothing. Relationship-property indexes are a separate, **specialized** tool — add one only when a query actually filters those edges by a property (most traversals anchor on a node, not a relationship) — and matter mainly for dense nodes ([011](011-supernode-mitigation.md)). One caveat on the `EXPLAIN`/`PROFILE` output: on this tiny seed the plan flip is what's illustrative, not the absolute db-hit counts — real measurement needs a warm page cache, repeated runs and a realistic dataset.

---
[← 001 Constraints & node keys](001-constraints-and-keys.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 003 Foreign keys → relationships](003-ids-to-relationships.md)
