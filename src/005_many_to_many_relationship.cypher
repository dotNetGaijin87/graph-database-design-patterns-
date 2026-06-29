// ===========================================================================
// Script 005
//
//   MANY-TO-MANY IS JUST A RELATIONSHIP  (killing the CSV wishlist)
//
//   Customer.wishlist is a comma-separated string of product NAMES — the exact
//   anti-pattern the sister repo fixes with a junction table (composite PK +
//   two foreign keys, pattern 010). A graph needs no junction entity at all:
//   a many-to-many is the *default* shape of a relationship.
// ===========================================================================


// ---------------------------------------------------------------------------
// Split each CSV string into product names and create one WANTS relationship
// per item. The TEXT/RANGE index on Product.name from 002 makes each lookup a
// seek; MERGE makes the pair unique (the graph equivalent of the junction
// table's composite primary key — at most one WANTS per customer/product).
// ---------------------------------------------------------------------------
MATCH (c:Customer)
WHERE c.wishlist IS NOT NULL AND c.wishlist <> ''
UNWIND split(c.wishlist, ',') AS rawName
WITH c, trim(rawName) AS wantedName
MATCH (p:Product {name: wantedName})
MERGE (c)-[w:WANTS]->(p)
  SET w.addedAt = date('2024-04-01');   // real timestamp unknown; stamp a placeholder


// ---------------------------------------------------------------------------
// The CSV column has served its purpose — drop it.
// ---------------------------------------------------------------------------
MATCH (c:Customer)
REMOVE c.wishlist;


// ---------------------------------------------------------------------------
// Both directions of the many-to-many are now first-class queries:
// ---------------------------------------------------------------------------

// What does Alice want?
MATCH (c:Customer {customerId: 'C1'})-[:WANTS]->(p:Product)
RETURN c.name AS customer, collect(p.name) AS wishlist;

// Who wants the Headphones? (Unanswerable while it was a CSV of names.)
MATCH (p:Product {name: 'Noise-Cancelling Headphones'})<-[:WANTS]-(c:Customer)
RETURN p.name AS product, collect(c.name) AS wishedBy;

// "Customers who want what you want" — a two-hop recommendation seed that a
// junction table would need two joins for:
MATCH (me:Customer {customerId: 'C1'})-[:WANTS]->(:Product)<-[:WANTS]-(other:Customer)
RETURN DISTINCT other.name AS sharesYourTaste;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * If the association itself needs rich attributes or has to connect more
//     than two parties (an order line = customer + product + quantity + the
//     order it belonged to), a bare relationship is not enough — reify it into
//     a node (pattern 006). WANTS only needs an addedAt, so a relationship with
//     one property is exactly right.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 5})
  SET m.description = 'Many-to-many as a relationship (no junction node)',
      m.appliedAt   = datetime();
