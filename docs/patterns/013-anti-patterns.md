# 013 — Anti-Patterns & When *Not* to Reach for a Graph (Appendix)

**Script:** [`src/013_anti_patterns.cypher`](../../src/013_anti_patterns.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
The twelve patterns showed what *to* do. But the fastest way to a slow, tangled graph is to over-apply them: graph every value, encode data in labels and relationship types, store documents as properties, and traverse without bounds. These mistakes don't throw errors — they quietly erode the performance and clarity a graph is supposed to buy.

## The solution
A **read-only diagnostic** pass that surfaces each smell in the graph built by 000–012, with guidance on how to read the results:
- **Supernodes** — densest nodes by degree ([011](011-supernode-mitigation.md)).
- **Label explosion** — hundreds of labels usually means a value that should be a property has been encoded as a label ([008](008-subtypes-via-labels.md)).
- **Relationship-type explosion** — the trap that over-eager type partitioning leads to ([009](009-relationship-granularity.md)/[011](011-supernode-mitigation.md)).
- **Over-graphing** — degree-1 nodes that may belong back inline as properties ([004](004-property-to-node.md) in reverse). A *candidate* list, not a verdict: a sparse `:Customer` is a real entity, but a degree-1 `:State` you never traverse *by* is suspect.
- **Blob properties** — oversized text/JSON/base64 values that belong in a document or object store.
- **Unbounded traversals & tabular analytics** — guidance on bounding variable-length paths and recognizing when a graph is simply the wrong tool.

## Key techniques
`COUNT { (n)--() }` degree counting, `db.labels()` / `db.relationshipTypes()` cardinality, degree-1 detection, blob detection via `size(toString(...))`, bounded vs unbounded variable-length patterns.

## Trade-offs & when *not* to use it
These are heuristics, not laws — each has a legitimate exception (a genuine supernode you can't avoid, a deliberately denormalized shortcut from [012](012-denormalization-shortcuts.md)). The real takeaway is the meta-point: a graph database earns its keep when queries *follow relationships*. If most of your workload is tabular aggregation that never traverses, the most valuable "pattern" is choosing a different store.

---
[← 012 Denormalization & shortcuts](012-denormalization-shortcuts.md) · [Pattern index](../../README.md#the-12-patterns)
