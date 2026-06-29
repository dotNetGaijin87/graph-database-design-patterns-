// ===========================================================================
// Script 013  (APPENDIX)
//
//   ANTI-PATTERNS — and when NOT to reach for a graph
//
//   The twelve patterns showed what TO do. This appendix is the mirror: the
//   recurring ways graph models go wrong, plus runnable DIAGNOSTICS that surface
//   each smell in the graph built by 000-012. Every query here is READ-ONLY
//   (it mutates nothing except its own _Migration record), so it is safe to run
//   against any graph — point it at yours.
//
//   The smells:
//     A  Supernodes you didn't notice .................... (pattern 011)
//     B  Label explosion (data encoded as labels) ........ (pattern 008)
//     C  Relationship-type explosion ..................... (patterns 009/011)
//     D  Over-graphing (nodes that should be properties) .. (pattern 004)
//     E  Blob properties (huge values on a node) .........
//     F  Unbounded traversals & graph-for-tabular-analytics
// ===========================================================================


// ---------------------------------------------------------------------------
// A. SUPERNODE DETECTOR — find your densest nodes before a traversal does.
//    A handful of nodes with runaway degree (here: P001 from pattern 011) are
//    the ones to design traversals away from. Rule of thumb: investigate
//    anything orders of magnitude above the median degree.
// ---------------------------------------------------------------------------
MATCH (n)
WHERE NOT n:_Migration
WITH n, COUNT { (n)--() } AS degree
RETURN labels(n) AS labels,
       coalesce(n.productId, n.customerId, n.orderId, n.name, n.code, elementId(n)) AS node,
       degree
ORDER BY degree DESC
LIMIT 10;


// ---------------------------------------------------------------------------
// B. LABEL EXPLOSION — labels are classifications, not a place to stuff data.
//    A handful of labels is healthy. Hundreds usually means a value that should
//    be a property has been encoded as a label (e.g. :Product_Red, :Product_Blue
//    instead of a `color` property) — the graph version of a wide, sparse table.
// ---------------------------------------------------------------------------
CALL db.labels() YIELD label
RETURN count(label) AS distinctLabels;

MATCH (n)
UNWIND labels(n) AS label
RETURN label, count(*) AS nodes
ORDER BY nodes DESC;


// ---------------------------------------------------------------------------
// C. RELATIONSHIP-TYPE EXPLOSION — the cousin of label explosion, and the trap
//    that over-eager "type partitioning" (pattern 011, Mitigation 3) leads to.
//    Encoding data in the type name (WANTS_2024_05, WANTS_2024_06, ...) bloats
//    the type registry and defeats range queries. Prefer a property + index.
// ---------------------------------------------------------------------------
CALL db.relationshipTypes() YIELD relationshipType
RETURN count(relationshipType) AS distinctRelTypes;

MATCH ()-[r]->()
RETURN type(r) AS relationshipType, count(*) AS rels
ORDER BY rels DESC;


// ---------------------------------------------------------------------------
// D. OVER-GRAPHING DETECTOR — nodes that probably should have stayed properties.
//    A node connected by exactly ONE relationship adds a hop without enabling
//    any cross-traversal. It is a CANDIDATE, not a verdict: judgment required.
//      * a degree-1 :State 'TX' or :Currency you never traverse BY  -> suspect
//        (collapse it back into a property — pattern 004 in reverse)
//      * a degree-1 :Customer (the 5,000 flash buyers from 011) -> fine, it's a
//        real entity that just happens to be sparsely connected
// ---------------------------------------------------------------------------
MATCH (n)
WHERE NOT n:_Migration
WITH n, COUNT { (n)--() } AS degree
WHERE degree = 1
RETURN labels(n) AS labels, count(*) AS degreeOneNodes
ORDER BY degreeOneNodes DESC;


// ---------------------------------------------------------------------------
// E. BLOB-PROPERTY DETECTOR — graphs are for connections, not for documents.
//    Large text/JSON/base64 blobs stored as properties bloat the page cache and
//    slow every traversal that loads the node. Keep big payloads in a document
//    store / blob store / object storage and keep a reference. (0 rows here is
//    healthy; on your graph, long matches are the ones to move out.)
// ---------------------------------------------------------------------------
MATCH (n)
UNWIND keys(n) AS k
WITH n, k, toString(n[k]) AS val
WHERE size(val) > 1000
RETURN labels(n) AS labels, k AS property, size(val) AS length
ORDER BY length DESC
LIMIT 10;


// ---------------------------------------------------------------------------
// F. UNBOUNDED TRAVERSALS & GRAPH-FOR-TABULAR-ANALYTICS (guidance, not queries)
//
//   * Unbounded variable-length traversals are a foot-gun on a connected graph:
//
//         MATCH (a:Customer)-[*]->(b)   RETURN b      // DON'T: explores the
//                                                     // whole component
//         MATCH (a:Customer)-[:WANTS*1..3]->(b)       // DO: bound length AND
//                RETURN b                             //     pin relationship types
//
//   * Wrong-tool smell: if your workload is mostly full-label scans with
//     aggregation and NO relationships are traversed —
//
//         MATCH (p:Product) RETURN avg(p.listPrice)   // pure tabular analytics
//
//     — a columnar/relational/OLAP store will do that faster. A graph earns its
//     keep when queries follow relationships (joins-at-write-time). Count how
//     much of your query log actually traverses before committing to a graph.
//
//   * Other smells worth a periodic audit: storing arrays that should be related
//     nodes; modeling time as one node per second; using the graph as a queue.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 13})
  SET m.description = 'Anti-patterns & when not to reach for a graph (appendix)',
      m.appliedAt   = datetime();
