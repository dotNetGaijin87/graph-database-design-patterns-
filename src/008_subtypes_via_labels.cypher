// ===========================================================================
// Script 008
//
//   SUPERTYPE / SUBTYPE VIA MULTIPLE LABELS  (polymorphism)
//
//   Software products carry compatibleOs / requiredRam; hardware products do
//   not. Today every product is a bare (:Product) with those attributes left
//   NULL on the hardware ones. The relational fix is a subtype table per kind
//   plus a reassembly view (patterns 017/018). A graph node can hold SEVERAL
//   labels at once, so the subtype is just an extra label — and the "view" that
//   reunites them is simply the shared :Product label.
// ===========================================================================


// ---------------------------------------------------------------------------
// Tag each product with its subtype label. The software-only properties now
// live exclusively on :Software nodes; :Hardware nodes never carried them.
// ---------------------------------------------------------------------------
MATCH (p:Product)
WHERE p.compatibleOs IS NOT NULL
SET p:Software;

MATCH (p:Product)
WHERE p.compatibleOs IS NULL
SET p:Hardware;


// ---------------------------------------------------------------------------
// Optional: indexes can target a single label, so subtype-specific lookups get
// their own index without touching the supertype.
// ---------------------------------------------------------------------------
CREATE INDEX software_requiredRam IF NOT EXISTS
  FOR (s:Software) ON (s.requiredRam);


// ---------------------------------------------------------------------------
// Polymorphic queries, three altitudes:
// ---------------------------------------------------------------------------

// Supertype — every product, regardless of kind (the implicit "reassembly view"):
MATCH (p:Product)
RETURN p.name AS product, labels(p) AS labels
ORDER BY product;

// Subtype — only software, with its specific attributes:
MATCH (p:Software)
RETURN p.name AS software, p.compatibleOs AS os, p.requiredRam AS ramGB
ORDER BY software;

// Subtype predicate inside a supertype query:
MATCH (p:Product)
WHERE p:Hardware
RETURN count(p) AS hardwareCount;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Labels are set-membership CLASSIFICATIONS (tags), not OO inheritance:
//     there is no method resolution and no guaranteed supertype contract — a
//     node simply carries the labels you give it. Use them to classify, not to
//     model an "is-a" hierarchy you expect the engine to enforce.
//   * Multi-label modeling shines when subtypes mostly share shape and you want
//     one label to address them all. It is also how you model ROLES/MIXINS that
//     a single node plays at once (a node could be both :Customer and :Vendor).
//   * When a subtype has MANY attributes of its own, or its own relationships,
//     prefer a related node — (:Product)-[:HAS_SPEC]->(:SoftwareSpec) — so the
//     supertype node stays lean. Labels are free; sprawling optional properties
//     are not.
//   * Neo4j does not enforce that :Software nodes also carry :Product; that
//     invariant lives in your write queries.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 8})
  SET m.description = 'Supertype/subtype via multiple labels',
      m.appliedAt   = datetime();
