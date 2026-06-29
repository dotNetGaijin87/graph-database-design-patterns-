// ===========================================================================
// Script 011
//
//   SUPERNODE / DENSE-NODE MITIGATION
//
//   A supernode (dense node) is a node with a huge number of relationships of
//   one type — a viral product, a popular category, a country every customer
//   lives in. When a traversal must expand it, the cost grows significantly with
//   the number of relationships visited — modern Neo4j's relationship-group
//   records soften this, but don't eliminate it. This is the graph's version of
//   data skew, with no relational analog as direct as partitioning (014/015).
// ===========================================================================


// ---------------------------------------------------------------------------
// Manufacture a supernode: a flash sale in which 5,000 buyers all wishlist the
// Headphones (P001), spread across 30 days. P001 now has 5,000+ incoming WANTS.
// (These synthetic buyers have no orders, so later patterns are unaffected.)
// ---------------------------------------------------------------------------
UNWIND range(1, 5000) AS i
CREATE (c:Customer {
  customerId: 'F' + toString(i),
  name:       'Flash Buyer ' + toString(i),
  email:      'flash' + toString(i) + '@example.com'
})
WITH c, i
MATCH (p:Product {productId: 'P001'})
CREATE (c)-[:WANTS {addedAt: date('2024-05-01') + duration({days: i % 30})}]->(p);


// ---------------------------------------------------------------------------
// NOTE on the PROFILE numbers below: this is a tiny teaching graph, so the
// db-hit/plan differences are ILLUSTRATIVE of the right shape, not benchmarks.
// Real measurement needs a realistic dataset, a warm page cache, and several
// repeated runs (discard the first) — don't over-read small absolute numbers.
// ---------------------------------------------------------------------------
// MITIGATION 1 — start from the SELECTIVE side.
//   "Did buyer F42 wishlist P001?" Anchoring on the supernode and expanding all
//   5,000 edges is the slow plan; anchoring on the rare buyer and stepping out
//   their single edge is the fast one. Same answer, hugely different db hits —
//   compare these two PROFILEs.
// ---------------------------------------------------------------------------
PROFILE
MATCH (p:Product {productId: 'P001'})<-[:WANTS]-(c:Customer {customerId: 'F42'})
RETURN c.name;                       // expands the supernode's fan-in

PROFILE
MATCH (c:Customer {customerId: 'F42'})-[:WANTS]->(p:Product {productId: 'P001'})
RETURN c.name;                       // steps out the selective node's one edge


// ---------------------------------------------------------------------------
// MITIGATION 2 — a RELATIONSHIP-PROPERTY index, so a predicate on the dense
//   edges can seek instead of scanning all of them. These are specialized:
//   narrower use than node indexes — add one only when a query actually filters
//   those edges by that property (most traversals anchor on a node, not an edge).
// ---------------------------------------------------------------------------
CREATE INDEX wants_addedAt IF NOT EXISTS
  FOR ()-[w:WANTS]-() ON (w.addedAt);

// Anchored purely on the relationship, this uses the relationship index rather
// than expanding P001's 5,000 edges and filtering:
PROFILE
MATCH ()-[w:WANTS]->()
WHERE w.addedAt = date('2024-05-15')
RETURN count(w);


// ---------------------------------------------------------------------------
// MITIGATION 3 — relationship-TYPE partitioning (fan the hot type out).
//   Splitting one scalding-hot type by a stable, low-cardinality discriminator
//   lets the engine prune by type for free (see pattern 009). E.g. partition
//   wishlisting by month so "May wishlisters" never expands April's edges:
//
//     MATCH (c)-[w:WANTS]->(p:Product {productId:'P001'})
//     WITH c, p, w, 'WANTS_' + toString(w.addedAt.year) + '_' +
//                   right('0'+toString(w.addedAt.month), 2) AS relType
//     CALL apoc.create.relationship(c, relType, {addedAt:w.addedAt}, p) YIELD rel
//     DELETE w;
//
//   ADVANCED / LAST RESORT — profile first. This is NOT standard practice: type
//   explosion fragments the schema, makes queries uglier and harder to maintain,
//   and breaks range queries over the discriminator. Exhaust Mitigations 1 and 2
//   (selective start + indexes) before inventing types; reserve this for a
//   genuinely hot edge you almost always traverse a single slice of.
//
// MITIGATION 4 — an intermediate META / vantage node.
//   Insert grouping nodes between the supernode and its neighbours so no single
//   node holds millions of direct edges, e.g.
//     (:Product)<-[:FOR]-(:WishBucket {month})<-[:WANTS]-(:Customer)
//   Each bucket has a bounded fan-out; you traverse only the relevant bucket.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Inspect the densest nodes (find your supernodes before they find you):
// ---------------------------------------------------------------------------
MATCH (p:Product)<-[w:WANTS]-()
RETURN p.productId AS product, count(w) AS wishlistDegree
ORDER BY wishlistDegree DESC
LIMIT 5;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * The cheapest fix is almost always query shape (Mitigation 1) — rewrite to
//     start selective. Reach for structural changes (3/4) only when the hot node
//     is unavoidable on the traversal path.
//   * Every structural mitigation trades write complexity and model clarity for
//     read speed. Measure with PROFILE first; don't pre-partition nodes that
//     aren't actually dense.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 11})
  SET m.description = 'Supernode / dense-node mitigation',
      m.appliedAt   = datetime();
