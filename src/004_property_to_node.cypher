// ===========================================================================
// Script 004
//
//   PROPERTY -> NODE  (extracting repeated values; the lookup/reference table)
//
//   "Acme Audio" is repeated as a vendorName string on three products; "CA" is
//   repeated as a state string on three customers. In a relational schema you
//   would pull each into a lookup/reference table and point a foreign key at it
//   (sister-repo patterns 007/008). In a graph you promote the value to a NODE
//   and point a relationship at it — and now you can traverse *by* it.
// ===========================================================================


// ---------------------------------------------------------------------------
// Vendors: repeated free-text -> shared (:Vendor) nodes
// ---------------------------------------------------------------------------
CREATE CONSTRAINT vendor_name_unique IF NOT EXISTS
  FOR (v:Vendor) REQUIRE v.name IS UNIQUE;

MATCH (p:Product)
WHERE p.vendorName IS NOT NULL
MERGE (v:Vendor {name: p.vendorName})
MERGE (p)-[:SUPPLIED_BY]->(v)
REMOVE p.vendorName;


// ---------------------------------------------------------------------------
// States: a controlled vocabulary -> (:State) nodes. We seed the full names
// (the lookup payload) and rewire each customer's state string into a relationship.
// ---------------------------------------------------------------------------
CREATE CONSTRAINT state_code_unique IF NOT EXISTS
  FOR (s:State) REQUIRE s.code IS UNIQUE;

UNWIND [
  {code: 'CA', name: 'California'},
  {code: 'NY', name: 'New York'},
  {code: 'TX', name: 'Texas'}
] AS row
MERGE (s:State {code: row.code})
  SET s.name = row.name;

MATCH (c:Customer)
WHERE c.state IS NOT NULL
MATCH (s:State {code: c.state})
MERGE (c)-[:LIVES_IN]->(s)
REMOVE c.state;


// ---------------------------------------------------------------------------
// The payoff — questions that were impossible against a string property are now
// plain traversals, in either direction:
// ---------------------------------------------------------------------------

// Every product a vendor supplies:
MATCH (v:Vendor {name: 'Acme Audio'})<-[:SUPPLIED_BY]-(p:Product)
RETURN v.name AS vendor, collect(p.name) AS products;

// Every customer in a state (the reference node enforces a clean vocabulary):
MATCH (s:State {code: 'CA'})<-[:LIVES_IN]-(c:Customer)
RETURN s.name AS state, collect(c.name) AS customers;


// ---------------------------------------------------------------------------
// When to KEEP a value as a property instead:
//   Promote a value to a node when it is shared, when you want to traverse by
//   it, or when it will grow attributes/relationships of its own (a Vendor has
//   an address, a rating, other products...). Leave it inline when it is a leaf
//   attribute owned by exactly one node (listPrice, createdAt) — turning those
//   into nodes just creates traffic and dense hubs for no query benefit.
//   Likewise, don't over-graph a low-cardinality code you only ever DISPLAY
//   (countryCode, currencyCode, languageCode) — make it a node only once you
//   actually traverse BY it. (See the anti-patterns appendix, pattern 013.)
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 4})
  SET m.description = 'Property to node (lookup/reference extraction)',
      m.appliedAt   = datetime();
