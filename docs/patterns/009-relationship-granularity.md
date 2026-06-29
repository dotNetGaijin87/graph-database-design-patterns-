# 009 — Relationship Granularity & Properties on Relationships

**Script:** [`src/009_relationship_granularity.cypher`](../../src/009_relationship_granularity.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
A graph gives you three places to put information about a connection — a property **on** the relationship, the relationship's **type**, or a whole reified **node** — and choosing badly has real performance consequences. The rich `(:Review)` node is the right home for prose, but reaching through it just to average star ratings is needless work.

## The solution
Derives a lightweight `(:Customer)-[:RATED {stars, ratedAt}]->(:Product)` relationship from each review, so "average stars for a product" is a one-hop aggregate that never touches the heavier content nodes. The script then spells out the **granularity dial**: filtering by relationship *type* is free (relationships are stored grouped by type, so `[:RATED]` prunes without an index), while a *property* predicate (`WHERE r.stars = 5`) is evaluated per relationship. Encode a dimension in the type when it's low-cardinality, stable and usually traversed one value at a time; keep it a property when it's high-cardinality or range-queried.

## Key techniques
Deriving a relationship from a traversal, properties on relationships, `round(avg(...), 2)`, type-pruned vs property-filtered traversal, the anti-pattern of exploding `RATED_5STAR` / `RATED_4STAR` types.

## Trade-offs & when *not* to use it
The rating now lives in **two** places (the `Review` node and the `RATED` edge). That redundancy buys cheap aggregation but must be kept in sync on every new or edited review — the same maintenance bargain as any denormalization ([012](012-denormalization-shortcuts.md)). Coarse, frequently-aggregated signal → relationship property; rich, standalone content with its own future relationships → node.

---
[← 008 Supertype/subtype via labels](008-subtypes-via-labels.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 010 Temporal modeling](010-temporal-modeling.md)
