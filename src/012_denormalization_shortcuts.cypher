// ===========================================================================
// Script 012
//
//   DENORMALIZATION: MATERIALIZED RELATIONSHIPS & MAINTAINED AGGREGATES
//
//   The graph equivalent of the sister repo's JSON denormalization (021) and
//   computed/persisted column (022). Two moves: (A) precompute an aggregate and
//   cache it ON the node, and (B) materialize the result of a multi-hop
//   traversal as a direct "shortcut" relationship, so a hot read becomes one
//   hop instead of a runtime walk.
// ===========================================================================


// ---------------------------------------------------------------------------
// A) Maintained aggregates — cache numReviews / avgRating on each Product so a
//    product card doesn't re-traverse all its reviews on every page view.
// ---------------------------------------------------------------------------
MATCH (p:Product)
OPTIONAL MATCH (p)<-[:REVIEWS]-(rv:Review)
WITH p, count(rv) AS numReviews, avg(rv.rating) AS avgRating
SET p.numReviews = numReviews,
    p.avgRating  = CASE WHEN numReviews = 0 THEN null ELSE round(avgRating, 2) END;

// Index the cached aggregate so "top-rated products" is an index-backed read:
CREATE INDEX product_avgRating IF NOT EXISTS
  FOR (p:Product) ON (p.avgRating);


// ---------------------------------------------------------------------------
// B) Materialized co-purchase shortcut — "customers who bought X also bought Y".
//    Computed once from the two-hop pattern through orders, stored as a direct
//    weighted (:Product)-[:ALSO_BOUGHT]->(:Product) edge.
// ---------------------------------------------------------------------------
MATCH (p1:Product)<-[:CONTAINS]-(:Order)-[:CONTAINS]->(p2:Product)
WHERE p1 <> p2
WITH p1, p2, count(*) AS coPurchases
MERGE (p1)-[r:ALSO_BOUGHT]->(p2)
  SET r.weight = coPurchases;


// ---------------------------------------------------------------------------
// The hot read is now a single hop instead of a 2-hop aggregation at query time:
// ---------------------------------------------------------------------------

// Recommendations for the Mechanical Keyboard, precomputed:
MATCH (:Product {productId: 'P003'})-[r:ALSO_BOUGHT]->(rec:Product)
RETURN rec.name AS alsoBought, r.weight AS strength
ORDER BY strength DESC, alsoBought;

// Top-rated products, served straight from the cached aggregate:
MATCH (p:Product)
WHERE p.avgRating IS NOT NULL
RETURN p.name AS product, p.avgRating AS rating, p.numReviews AS reviews
ORDER BY rating DESC, reviews DESC;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Denormalization trades write cost + staleness for read speed — identical
//     to the relational bargain. The cached avgRating and ALSO_BOUGHT edges are
//     wrong the instant a new review or order lands; you must refresh them
//     (application logic, a scheduled job, or APOC triggers) and accept a
//     staleness window. Don't materialize what you can afford to compute live.
//   * For real recommendations, hand-rolled ALSO_BOUGHT is a teaching stand-in.
//     In production use the Graph Data Science library — node similarity,
//     personalized PageRank — which computes these relationships for you and can
//     write them back to the graph (gds.nodeSimilarity.write, etc.).
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 12})
  SET m.description = 'Denormalization: materialized relationships & aggregates',
      m.appliedAt   = datetime();
