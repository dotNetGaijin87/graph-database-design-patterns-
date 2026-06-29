# 008 — Supertype / Subtype via Multiple Labels

**Script:** [`src/008_subtypes_via_labels.cypher`](../../src/008_subtypes_via_labels.cypher) · [Pattern index](../../README.md#the-12-patterns)

## The problem
Software products carry `compatibleOs` / `requiredRam`; hardware products don't. Today every product is a bare `(:Product)` with those attributes left `NULL` on the hardware ones. The relational fix is a subtype table per kind plus a reassembly view (patterns 017/018).

## The solution
A graph node can hold **several labels at once**, so the subtype is just an extra label: tag the software products `:Software` and the rest `:Hardware`, giving `(:Product:Software)` and `(:Product:Hardware)`. The software-only properties now live exclusively on `:Software` nodes, the "reassembly view" that reunites them is simply the shared `:Product` label, and indexes can target a single subtype label.

## Key techniques
`SET n:Label` to add a label, label-scoped indexes (`FOR (s:Software) ON ...`), polymorphic queries at three altitudes (supertype `:Product`, subtype `:Software`, subtype predicate `WHERE p:Hardware`), `labels(n)`.

## Trade-offs & when *not* to use it
Labels are set-membership **classifications** (tags), not OO inheritance — there's no method resolution and no guaranteed supertype contract, so use them to classify rather than to model an "is-a" hierarchy you expect the engine to enforce. Multi-label modeling shines when subtypes mostly share shape, and it's also how you model **roles/mixins** a node plays at once (a node could be both `:Customer` and `:Vendor`). When a subtype has *many* attributes of its own or its own relationships, prefer a related node — `(:Product)-[:HAS_SPEC]->(:SoftwareSpec)` — so the supertype stays lean. Neo4j doesn't enforce that every `:Software` is also a `:Product`; that invariant lives in your writes.

---
[← 007 Native hierarchies](007-native-hierarchy.md) · [Pattern index](../../README.md#the-12-patterns) · [next → 009 Relationship granularity](009-relationship-granularity.md)
