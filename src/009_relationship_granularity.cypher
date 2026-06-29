// ===========================================================================
// Script 009
//
//   RELATIONSHIP GRANULARITY & PROPERTIES ON RELATIONSHIPS
//
//   A graph gives you three places to put information about a connection: a
//   property ON the relationship, the relationship's TYPE, or a whole reified
//   NODE. Choosing well is a real design decision with query-performance
//   consequences. Here we extract the numeric rating signal out of the rich
//   Review nodes into a lightweight (:Customer)-[:RATED {stars}]->(:Product)
//   relationship — keeping the heavyweight Review for content.
// ===========================================================================


// ---------------------------------------------------------------------------
// Derive a RATED relationship from each existing review. The rich Review node
// stays (it owns the prose, and one day replies/images); the coarse numeric
// signal moves onto a relationship where it is cheap to aggregate.
// ---------------------------------------------------------------------------
MATCH (c:Customer)-[:WROTE]->(rv:Review)-[:REVIEWS]->(p:Product)
MERGE (c)-[r:RATED]->(p)
  SET r.stars   = rv.rating,
      r.ratedAt = rv.createdAt;


// ---------------------------------------------------------------------------
// Why a relationship property here? Average stars is now a one-hop aggregate
// that never has to touch the (heavier) Review content nodes:
// ---------------------------------------------------------------------------
MATCH (p:Product)<-[r:RATED]-(:Customer)
RETURN p.name AS product, round(avg(r.stars), 2) AS avgStars, count(r) AS numRatings
ORDER BY avgStars DESC;


// ---------------------------------------------------------------------------
// TYPE vs PROPERTY — the granularity dial.
//
//   Filtering by relationship TYPE is free: the engine stores relationships
//   grouped by type, so MATCH (c)-[:RATED]->(p) prunes without an index. A
//   PROPERTY predicate (WHERE r.stars = 5) must be evaluated per relationship.
//
//   So: encode a dimension in the TYPE when it is low-cardinality, stable, and
//   you frequently traverse just one value of it (e.g. :WROTE vs :RATED). Keep
//   it as a PROPERTY when it is high-cardinality or you filter on ranges
//   (r.stars, r.ratedAt). Do NOT explode types into RATED_5STAR / RATED_4STAR —
//   that is type-cardinality abuse that defeats range queries.
// ---------------------------------------------------------------------------

// Free, type-pruned traversal — "everything Alice rated":
MATCH (:Customer {customerId: 'C1'})-[r:RATED]->(p:Product)
RETURN p.name, r.stars;

// Property-filtered traversal — "Alice's 5-star products" (predicate evaluated):
MATCH (:Customer {customerId: 'C1'})-[r:RATED]->(p:Product)
WHERE r.stars = 5
RETURN p.name;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * We now hold the rating in TWO places (the Review node and the RATED edge).
//     That redundancy buys cheap aggregation but must be kept in sync on every
//     new/edited review — the same maintenance bargain as any denormalization
//     (formalized in pattern 012).
//   * Coarse, frequently-aggregated signal -> relationship property. Rich,
//     standalone content with its own future relationships -> node. The dividing
//     line is exactly the reification question from pattern 006.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 9})
  SET m.description = 'Relationship granularity & properties on relationships',
      m.appliedAt   = datetime();
