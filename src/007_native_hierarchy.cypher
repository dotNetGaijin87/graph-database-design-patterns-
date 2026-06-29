// ===========================================================================
// Script 007
//
//   MODELING HIERARCHIES NATIVELY  (the category tree)
//
//   Product.category is a "/"-delimited path string — "Electronics/Audio/
//   Headphones". The sister repo models this tree three relational ways
//   (adjacency list, materialized path, hierarchyid — pattern 016), each with
//   awkward recursive SQL. In a graph a hierarchy is just relationships, and
//   ancestor / descendant / subtree-move become variable-length traversals.
// ===========================================================================


CREATE CONSTRAINT category_name_unique IF NOT EXISTS
  FOR (c:Category) REQUIRE c.name IS UNIQUE;


// ---------------------------------------------------------------------------
// 1. Create a (:Category) node for every distinct path segment.
// ---------------------------------------------------------------------------
MATCH (p:Product)
WHERE p.category IS NOT NULL
WITH DISTINCT split(p.category, '/') AS parts
UNWIND parts AS segment
MERGE (:Category {name: segment});


// ---------------------------------------------------------------------------
// 2. Link each segment to its parent with SUBCATEGORY_OF (child -> parent).
// ---------------------------------------------------------------------------
MATCH (p:Product)
WHERE p.category IS NOT NULL
WITH DISTINCT split(p.category, '/') AS parts
UNWIND range(1, size(parts) - 1) AS i
MATCH (child:Category  {name: parts[i]})
MATCH (parent:Category {name: parts[i - 1]})
MERGE (child)-[:SUBCATEGORY_OF]->(parent);


// ---------------------------------------------------------------------------
// 3. Connect each product to its LEAF category, then drop the path string.
// ---------------------------------------------------------------------------
MATCH (p:Product)
WHERE p.category IS NOT NULL
WITH p, split(p.category, '/') AS parts
MATCH (leaf:Category {name: parts[size(parts) - 1]})
MERGE (p)-[:IN_CATEGORY]->(leaf)
REMOVE p.category;


// ---------------------------------------------------------------------------
// The payoff — variable-length traversal does what recursive CTEs did, but
// reads like the question you are asking:
// ---------------------------------------------------------------------------

// All descendant categories of Electronics (any depth, *0.. includes itself):
MATCH (root:Category {name: 'Electronics'})<-[:SUBCATEGORY_OF*0..]-(sub:Category)
RETURN sub.name AS category ORDER BY category;

// Every product anywhere under Electronics, however deep the category sits:
MATCH (root:Category {name: 'Electronics'})<-[:SUBCATEGORY_OF*0..]-(:Category)<-[:IN_CATEGORY]-(p:Product)
RETURN DISTINCT p.name AS product ORDER BY product;

// Ancestors of Headphones (its breadcrumb trail to the root):
MATCH path = (leaf:Category {name: 'Headphones'})-[:SUBCATEGORY_OF*0..]->(root:Category)
WHERE NOT (root)-[:SUBCATEGORY_OF]->()
RETURN [n IN nodes(path) | n.name] AS breadcrumb;


// ---------------------------------------------------------------------------
// Reparenting a whole subtree is a SINGLE relationship rewrite — no path-string
// rebuild, no recursive update. (Shown as an example; left commented so the
// canonical tree is preserved.)
//
//   MATCH (sub:Category {name: 'Headphones'})-[r:SUBCATEGORY_OF]->(:Category)
//   MATCH (newParent:Category {name: 'Peripherals'})
//   DELETE r
//   MERGE (sub)-[:SUBCATEGORY_OF]->(newParent);
//
// Every descendant of Headphones moves with it automatically, because the
// hierarchy is structure, not a denormalized string on each node.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Keying a category by name (as here) assumes names are globally unique. If
//     "Accessories" can appear under two parents, key it by an id or full path
//     instead, or the MERGE in step 1 will collapse them into one node.
//   * Unbounded *0.. traversals over very deep / wide trees still cost what they
//     visit — bound the depth (*1..5) when you can, and watch for dense category
//     hubs (pattern 011).
//   * A graph doesn't make EVERY hierarchy free: very deep or frequently-
//     reparented trees can still be expensive, and a materialized path or a
//     cached-ancestor relationship (a graph "closure") is sometimes worth
//     maintaining for hot read paths — the denormalization bargain of pattern 012.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 7})
  SET m.description = 'Native hierarchy (category tree)',
      m.appliedAt   = datetime();
