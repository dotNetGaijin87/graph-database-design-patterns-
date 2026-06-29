# 010 — Temporal Modeling (State History & Time-Tree)

**Script:** [`src/010_temporal_modeling.cypher`](../../src/010_temporal_modeling.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
An order's `status` is a single property — a snapshot that forgets every prior state. The relational answer is a history table or a system-versioned temporal table (patterns 012/013). How do you record *how* an order reached its current state, and slice orders by calendar period without scanning every date?

## The solution
Models time as **structure**, two complementary ways. (A) Order status history becomes a linked list of `(:OrderStatus)` nodes chained by `[:NEXT]`, with a `[:CURRENT_STATUS]` shortcut so "what is it now?" stays one hop while the full timeline is a walk of the chain. (B) A **time-tree** `(:Year)-[:HAS_MONTH]->(:Month)-[:HAS_DAY]->(:Day)` hangs each order off its day, turning "every order in March 2024" into a traversal of a small calendar skeleton instead of a property scan.

## Key techniques
Synthesizing a state progression (`apoc.coll.indexOf`, list comprehension), `[:NEXT]` linked list, a `[:CURRENT_STATUS]` materialized pointer, root/head detection, a `MERGE`-built time-tree, date arithmetic (`date + duration`), temporal accessors (`.year` / `.month`).

## Trade-offs & when *not* to use it
The linked list keeps history immutable and append-only (great for audit), but reading a full timeline is O(chain length) — the `CURRENT_STATUS` shortcut exists precisely so the common read stays O(1). A time-tree pays off when you slice by calendar buckets a lot; if you only ever filter on an exact timestamp, a plain range index on `orderDate` is simpler. Don't build calendar scaffolding you won't traverse.

---
[← 009 Relationship granularity](009-relationship-granularity.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 011 Supernode mitigation](011-supernode-mitigation.md)
