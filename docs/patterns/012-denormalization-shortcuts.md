# 012 — Denormalization: Materialized Relationships & Aggregates

**Script:** [`src/012_denormalization_shortcuts.cypher`](../../src/012_denormalization_shortcuts.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
Some reads are hot enough that recomputing them every time hurts: a product card re-traversing all its reviews to show an average, or a recommendation walking two hops through every order on each page view. This is the graph equivalent of the sister repo's JSON denormalization (021) and computed/persisted column (022).

## The solution
Two moves. **(A) Maintained aggregates** — precompute `numReviews` / `avgRating` and cache them on each `(:Product)`, with a range index so "top-rated products" is an index-backed read. **(B) Materialized shortcut relationships** — compute "customers who bought X also bought Y" once from the two-hop pattern through orders and store it as a direct, weighted `(:Product)-[:ALSO_BOUGHT]->(:Product)` edge, so the hot recommendation read is a single hop instead of a runtime aggregation.

## Key techniques
`OPTIONAL MATCH` + aggregation for cached values, `CASE` to null-guard empty aggregates, two-hop co-purchase pattern → `MERGE` with a `weight`, indexing a derived property, a forward pointer to the Graph Data Science library (`gds.nodeSimilarity`, personalized PageRank).

## Trade-offs & when *not* to use it
Denormalization trades write cost + staleness for read speed — identical to the relational bargain. The cached `avgRating` and `ALSO_BOUGHT` edges are wrong the instant a new review or order lands, so you must refresh them (application logic, a scheduled job, or APOC triggers) and accept that they are **eventually consistent**, never automatically kept in sync — a staleness window you design for. Don't materialize what you can afford to compute live, and for real recommendations prefer the Graph Data Science library over hand-rolled shortcut edges.

---
[← 011 Supernode mitigation](011-supernode-mitigation.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 013 Anti-patterns (appendix)](013-anti-patterns.md)
