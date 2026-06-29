# 011 — Supernode / Dense-Node Mitigation

**Script:** [`src/011_supernode_mitigation.cypher`](../../src/011_supernode_mitigation.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
A **supernode** (dense node) has a huge number of relationships of one type — a viral product, a popular category, a country every customer lives in. Any traversal that has to expand it touches *all* of those edges, so the cost grows significantly with the number of relationships visited — modern Neo4j's relationship-group records soften this but don't eliminate it. It's the graph's version of data skew, with no relational analog as direct as partitioning (014/015).

## The solution
Manufactures a supernode (a flash sale where 5,000 buyers all wishlist one product), then demonstrates four mitigations: **(1)** start traversals from the *selective* side, not the supernode — same answer, hugely different db-hits (shown with two `PROFILE`s); **(2)** a **relationship-property index** so a predicate on the dense edges can seek; **(3)** relationship-**type partitioning**, fanning the hot type out by a low-cardinality discriminator so the engine prunes by type for free; **(4)** an intermediate **meta / vantage node** that caps any single node's fan-out.

## Key techniques
`UNWIND range()` to bulk-generate, `PROFILE` to compare plans/db-hits, relationship-property index (`FOR ()-[r:WANTS]-() ON (r.addedAt)`), relationship anchoring vs node anchoring, type partitioning (`apoc.create.relationship`), degree inspection to find supernodes.

## Trade-offs & when *not* to use it
The cheapest fix is almost always **query shape** — rewrite to start selective. Relationship-property indexes are a specialized, query-driven tool (add one only when a predicate actually filters those edges); relationship-**type partitioning** is an *advanced, profile-first* optimization that fragments the schema, makes queries uglier and breaks range queries over the discriminator — so exhaust the cheaper options before inventing types. And read the `PROFILE` db-hits in the script as *illustrative* on this tiny seed, not as benchmarks: real measurement needs a warm cache, repeated runs and a realistic dataset. Don't pre-partition nodes that aren't actually dense.

---
[← 010 Temporal modeling](010-temporal-modeling.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 012 Denormalization & shortcuts](012-denormalization-shortcuts.md)
