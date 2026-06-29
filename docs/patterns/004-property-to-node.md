# 004 — Property → Node (Lookup / Reference Extraction)

**Script:** [`src/004_property_to_node.cypher`](../../src/004_property_to_node.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
`"Acme Audio"` is repeated as a `vendorName` string on three products; `"CA"` is repeated as a `state` string on three customers. In a relational schema you'd pull each into a lookup/reference table and point a foreign key at it (sister-repo patterns 007/008). As bare strings they can't be traversed *by*, and nothing enforces a clean vocabulary.

## The solution
Promotes each repeated value to a **node**: `(:Vendor)` linked by `[:SUPPLIED_BY]`, and `(:State)` (seeded with full names — the lookup payload) linked by `[:LIVES_IN]`. Adds uniqueness constraints so the shared node is the single source of truth. Questions that were impossible against a string property ("which products does Acme supply?", "which customers live in California?") become plain traversals in either direction.

## Key techniques
`MERGE` to dedupe shared nodes, `UNWIND` a seed list for the reference payload, uniqueness constraints as a controlled vocabulary, `REMOVE` the original property, bidirectional lookups.

## Trade-offs & when *not* to use it
Promote a value to a node when it's **shared**, when you want to **traverse by it**, or when it will grow attributes/relationships of its own. Leave it inline when it's a leaf attribute owned by exactly one node (`listPrice`, `createdAt`) — turning those into nodes just creates traffic and dense hubs ([011](011-supernode-mitigation.md)) for no query benefit. Likewise, don't over-graph a low-cardinality code you only ever *display* (`countryCode`, `currencyCode`, `languageCode`) — promote it to a node only once you actually traverse *by* it.

---
[← 003 Foreign keys → relationships](003-ids-to-relationships.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 005 Many-to-many is just a relationship](005-many-to-many-relationship.md)
