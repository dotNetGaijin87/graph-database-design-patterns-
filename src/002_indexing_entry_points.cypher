// ===========================================================================
// Script 002
//
//   INDEXING TRAVERSAL ENTRY POINTS
//
//   A graph query is cheap to walk but you still have to FIND somewhere to
//   start. That starting set — the "anchor" of the traversal — is located by
//   an index, or, if none exists, by a full label scan. The unique constraints
//   from 001 already index the id keys; this script indexes the *non-key*
//   properties people actually search by (a product name, a customer surname).
// ===========================================================================


// ---------------------------------------------------------------------------
// Before: with no index on name, anchoring on it forces a NodeByLabelScan over
// every (:Product) followed by a Filter. EXPLAIN shows the plan without running.
// ---------------------------------------------------------------------------
EXPLAIN
MATCH (p:Product {name: 'Mechanical Keyboard'})
RETURN p;


// ---------------------------------------------------------------------------
// A RANGE index — the default — serves equality and range/prefix predicates.
// ---------------------------------------------------------------------------
CREATE INDEX product_name IF NOT EXISTS
  FOR (p:Product) ON (p.name);

// A TEXT index additionally serves CONTAINS / ENDS WITH substring predicates
// (a range index cannot). The two coexist on the same property.
CREATE TEXT INDEX product_name_text IF NOT EXISTS
  FOR (p:Product) ON (p.name);

// Customers are looked up by surname once names are split (pattern 005 era),
// but the whole `name` blob is what we have today — index it as the entry point.
CREATE INDEX customer_name IF NOT EXISTS
  FOR (c:Customer) ON (c.name);


// ---------------------------------------------------------------------------
// After: the same anchor now plans as a NodeIndexSeek. PROFILE runs it and
// reports the db hits — compare against the label-scan plan above.
// ---------------------------------------------------------------------------
PROFILE
MATCH (p:Product {name: 'Mechanical Keyboard'})
RETURN p;

// Substring search now uses the TEXT index instead of scanning + filtering:
PROFILE
MATCH (p:Product)
WHERE p.name CONTAINS 'Webcam'
RETURN p.productId, p.name;


// ---------------------------------------------------------------------------
// Inventory of indexes (the constraint-backed ones from 001 appear here too).
// ---------------------------------------------------------------------------
SHOW INDEXES;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Indexes speed reads but cost write throughput and storage, exactly as in
//     a relational store. Index the *entry points* of your traversals, not
//     every property — once you have anchored and started walking relationships,
//     the graph follows pointers and no index is consulted.
//   * Relationship-property indexes exist too, but are specialized: add one only
//     when a query filters those edges by that property (most traversals anchor
//     on a node, not a relationship). They matter mainly for dense nodes (011).
//   * The PROFILE numbers here are illustrative on this tiny seed, not a
//     benchmark — the plan SHAPE is the lesson. Real measurement needs a warm
//     page cache, repeated runs and a realistic dataset; don't over-read small
//     absolute db-hit differences.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 2})
  SET m.description = 'Indexing traversal entry points',
      m.appliedAt   = datetime();
