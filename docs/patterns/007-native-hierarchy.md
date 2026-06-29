# 007 — Native Hierarchies

**Script:** [`src/007_native_hierarchy.cypher`](../../src/007_native_hierarchy.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
`Product.category` is a `"/"`-delimited path string — `"Electronics/Audio/Headphones"`. The sister repo models this tree three relational ways (adjacency list, materialized path, `hierarchyid` — pattern 016), each needing awkward recursive SQL for "all descendants" or "move this subtree".

## The solution
Builds the tree out of the path strings: a `(:Category)` node per segment, child→parent `[:SUBCATEGORY_OF]` relationships, and each product wired to its leaf via `[:IN_CATEGORY]`. Ancestor / descendant / "all products under X" become **variable-length traversals** (`[:SUBCATEGORY_OF*0..]`) that read like the question being asked, and reparenting a whole subtree is a **single relationship rewrite** — every descendant moves with it because the hierarchy is structure, not a denormalized string on each node.

## Key techniques
`split()` into segments, `UNWIND range()` to link consecutive levels, `MERGE` nodes and relationships, variable-length patterns `*0..`, root detection (`WHERE NOT (n)-[:SUBCATEGORY_OF]->()`), breadcrumb extraction with `nodes(path)`.

## Trade-offs & when *not* to use it
Keying a category by `name` assumes names are globally unique; if `"Accessories"` can sit under two parents, key it by an id or full path or the `MERGE` collapses them into one node. Unbounded `*0..` traversals over very deep/wide trees still cost what they visit — bound the depth (`*1..5`) when you can, and watch for dense category hubs ([011](011-supernode-mitigation.md)). A graph doesn't make *every* hierarchy free: very deep or frequently-reparented trees can still be costly, and a materialized path or cached-ancestor relationship (a graph "closure") is sometimes worth maintaining for hot read paths — the denormalization bargain of [012](012-denormalization-shortcuts.md).

---
[← 006 Intermediate (reified) nodes](006-intermediate-node.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 008 Supertype/subtype via labels](008-subtypes-via-labels.md)
