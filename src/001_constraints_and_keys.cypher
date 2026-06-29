// ===========================================================================
// Script 001
//
//   CONSTRAINTS & NODE KEYS  —  identity in a graph
//
//   The naive graph has no notion of identity: nothing stops two (:Customer)
//   nodes sharing a customerId, or two products colliding on productId. The
//   relational analog is the PRIMARY KEY. In Neo4j you declare identity with a
//   uniqueness CONSTRAINT, which also transparently builds a backing index, so
//   it does double duty as the fast lookup that every traversal starts from.
// ===========================================================================


// ---------------------------------------------------------------------------
// Business-key uniqueness constraints. Each one rejects duplicate values AND
// creates a range index behind the scenes (so MATCH (:Product {productId:...})
// becomes a single-node seek instead of a label scan).
// ---------------------------------------------------------------------------
CREATE CONSTRAINT customer_customerId_unique IF NOT EXISTS
  FOR (c:Customer) REQUIRE c.customerId IS UNIQUE;

CREATE CONSTRAINT customer_email_unique IF NOT EXISTS
  FOR (c:Customer) REQUIRE c.email IS UNIQUE;

CREATE CONSTRAINT product_productId_unique IF NOT EXISTS
  FOR (p:Product) REQUIRE p.productId IS UNIQUE;

CREATE CONSTRAINT review_reviewId_unique IF NOT EXISTS
  FOR (rv:Review) REQUIRE rv.reviewId IS UNIQUE;


// ---------------------------------------------------------------------------
// Confirm they exist.
// ---------------------------------------------------------------------------
SHOW CONSTRAINTS;


// ---------------------------------------------------------------------------
// Proof the constraint now protects identity. Run this in Neo4j Browser and it
// fails with "already exists with label `Customer` and property `customerId`":
//
//   CREATE (:Customer {customerId: 'C1', email: 'dupe@example.com'});
//
// (It is left commented so this migration file still runs end-to-end.)
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Trade-off note — what Community edition does NOT give you:
//   * NODE KEY constraints (composite + mandatory) are Enterprise-only. In
//     Community you compose "unique" + an application-level not-null check.
//   * Property EXISTENCE constraints are likewise Enterprise-only.
//   * A uniqueness constraint is single-label / single-or-composite-property;
//     it does not span relationships, so cross-node invariants still live in
//     your write queries (usually a MERGE).
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 1})
  SET m.description = 'Constraints & node keys (identity)',
      m.appliedAt   = datetime();
