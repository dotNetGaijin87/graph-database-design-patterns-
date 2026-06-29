// ===========================================================================
// Script 003
//
//   FOREIGN KEYS -> RELATIONSHIPS  (relationships as first-class citizens)
//
//   This is THE defining graph pattern. The naive Review nodes are islands:
//   they point at their author and product with id PROPERTIES (authorId,
//   productId) — foreign keys copied straight out of a relational schema. In a
//   graph that connection should be a real relationship you can traverse in
//   either direction, in constant time, with no join.
// ===========================================================================


// ---------------------------------------------------------------------------
// Before: "give me the reviews of product P001" cannot traverse — it has to
// scan every Review and compare a string property. (No path exists in the graph.)
// ---------------------------------------------------------------------------
EXPLAIN
MATCH (rv:Review)
WHERE rv.productId = 'P001'
RETURN rv.reviewId, rv.rating;


// ---------------------------------------------------------------------------
// Turn the two id properties into two relationships:
//     (:Customer)-[:WROTE]->(:Review)-[:REVIEWS]->(:Product)
// then drop the now-redundant id properties.
// ---------------------------------------------------------------------------
MATCH (rv:Review)
MATCH (author:Customer {customerId: rv.authorId})
MATCH (product:Product {productId: rv.productId})
MERGE (author)-[:WROTE]->(rv)
MERGE (rv)-[:REVIEWS]->(product)
REMOVE rv.authorId, rv.productId;


// ---------------------------------------------------------------------------
// After: the same question is now a single hop, and it works both ways —
// product -> its reviews, or customer -> everything they reviewed.
// ---------------------------------------------------------------------------
MATCH (p:Product {productId: 'P001'})<-[:REVIEWS]-(rv:Review)<-[:WROTE]-(author:Customer)
RETURN p.name AS product, author.name AS author, rv.rating AS rating, rv.content AS review
ORDER BY rv.rating DESC;


// ---------------------------------------------------------------------------
// A modeling aside (the casing convention is itself a design tell):
//   Customer / Product / Review  -> PascalCase LABELS  (the nouns / entities)
//   WROTE / REVIEWS              -> UPPER_SNAKE TYPES   (the verbs / facts)
//   rating / content             -> camelCase KEYS      (attributes of a node)
//   An "authorId" attribute that merely names another node is the smell this
//   pattern removes: if a property is really a reference, make it a relationship.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Relationships are stored as direct pointers, so traversing them does not
//     get slower as the graph grows — unlike a relational join whose cost rises
//     with table size. That locality is the whole reason to prefer a graph for
//     deeply connected data.
//   * The flip side: a relationship connects exactly two nodes. The moment a
//     "connection" needs its own attributes or has to tie together more than
//     two things, you reify it into a node — see pattern 006.
//   * Don't reflexively delete every id. Keep a foreign-key-like id ALONGSIDE the
//     relationship when an external integration, event log, audit trail or
//     immutable snapshot needs a stable reference that survives independently of
//     the graph — e.g. a (:Payment) that records customerId for reconciliation
//     even though (:Customer)-[:MADE]->(:Payment) also exists.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 3})
  SET m.description = 'Foreign keys to relationships (first-class relationships)',
      m.appliedAt   = datetime();
