# 006 — Intermediate (Reified) Nodes

**Script:** [`src/006_intermediate_node.cypher`](../../src/006_intermediate_node.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
In the naive graph an order is a set of `(:Customer)-[:ORDERED]->(:Product)` edges that merely repeat an `orderId` property. The grouping is lost: you can't ask "what was in order O1002?" without scanning every edge, and there's nowhere to attach a shipment, payment, or status history.

## The solution
Promotes the order to a **node** (a hyperedge). One `(:Order)` is materialized per distinct `orderId` with the buyer connected via `[:PLACED]`, and each line hung off it as `(:Order)-[:CONTAINS {quantity, listPrice}]->(:Product)` — the line-level attributes living **on** the relationship. The old flat edges are deleted. This is the graph form of the relational associative + master/detail tables (010/011): when a relationship needs its own identity, attributes, or must connect 3+ entities, you reify it.

## Key techniques
Aggregation to fold lines into orders (`collect(DISTINCT ...)[0]`, `min()`), `MERGE` the new entity, properties on relationships, `DELETE` the superseded edges, order-total aggregation (`sum(qty * price)`).

## Trade-offs & when *not* to use it
Reifying adds a hop (`Customer → Order → Product`). That's correct when the middle thing is a real concept, and over-engineering when the association is genuinely binary and attribute-free — keep `WANTS` a plain relationship, not a `(:Wish)` node. Rule of thumb: reify when the relationship needs identity, needs its own relationships, or connects three or more entities.

---
[← 005 Many-to-many is just a relationship](005-many-to-many-relationship.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 007 Native hierarchies](007-native-hierarchy.md)
