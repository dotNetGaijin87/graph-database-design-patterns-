// ===========================================================================
// Script 006
//
//   INTERMEDIATE (REIFIED) NODES  —  when a relationship becomes a thing
//
//   In the naive graph an order is a set of (:Customer)-[:ORDERED]->(:Product)
//   edges that merely repeat an orderId property. An order is really an ENTITY:
//   it has a date, a status, multiple line items, and later a shipment and a
//   payment. When a relationship needs its own identity, attributes, or has to
//   tie together more than two nodes, you promote it to a node — a hyperedge.
//   This is the graph form of the associative + master/detail tables (010/011).
// ===========================================================================


CREATE CONSTRAINT order_orderId_unique IF NOT EXISTS
  FOR (o:Order) REQUIRE o.orderId IS UNIQUE;


// ---------------------------------------------------------------------------
// 1. Materialize one (:Order) node per distinct orderId and connect the buyer:
//        (:Customer)-[:PLACED]->(:Order)
//    All lines of an order share the same customer / date / status, so we fold
//    them with aggregation.
// ---------------------------------------------------------------------------
MATCH (c:Customer)-[r:ORDERED]->(:Product)
WITH r.orderId                  AS orderId,
     collect(DISTINCT c)[0]     AS customer,
     min(r.orderDate)           AS orderDate,
     collect(DISTINCT r.status)[0] AS status
MERGE (o:Order {orderId: orderId})
  SET o.orderDate = orderDate,
      o.status    = status
MERGE (customer)-[:PLACED]->(o);


// ---------------------------------------------------------------------------
// 2. Hang each line item off its order, carrying the line-level properties
//    (quantity, price-at-purchase) ON the CONTAINS relationship:
//        (:Order)-[:CONTAINS {quantity, listPrice}]->(:Product)
// ---------------------------------------------------------------------------
MATCH (c:Customer)-[r:ORDERED]->(p:Product)
MATCH (o:Order {orderId: r.orderId})
MERGE (o)-[ci:CONTAINS]->(p)
  SET ci.quantity  = r.quantity,
      ci.listPrice = r.listPrice;


// ---------------------------------------------------------------------------
// 3. Remove the old flattened edges.
// ---------------------------------------------------------------------------
MATCH (:Customer)-[r:ORDERED]->(:Product)
DELETE r;


// ---------------------------------------------------------------------------
// The grouping that was lost is back. "What was in order O1002?" is now a hop,
// and an Order is something we can attach status history, shipments, payments
// and refunds to later (patterns 009/010):
// ---------------------------------------------------------------------------
MATCH (cust:Customer)-[:PLACED]->(o:Order {orderId: 'O1002'})-[ci:CONTAINS]->(p:Product)
RETURN o.orderId   AS orderId,
       cust.name   AS customer,
       o.orderDate AS orderDate,
       collect({product: p.name, qty: ci.quantity, price: ci.listPrice}) AS lines;

// Order total — an aggregation over the line relationships:
MATCH (o:Order {orderId: 'O1002'})-[ci:CONTAINS]->(:Product)
RETURN o.orderId AS orderId, sum(ci.quantity * ci.listPrice) AS orderTotal;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * Reifying adds a hop: Customer -> Order -> Product instead of a direct
//     edge. That is the right call when the middle thing is a real concept; it
//     is over-engineering when the association is genuinely binary and
//     attribute-free (keep WANTS a plain relationship, not a (:Wish) node).
//   * Rule of thumb: reify when the relationship needs identity, needs its own
//     relationships, or connects 3+ entities (a hyperedge).
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 6})
  SET m.description = 'Intermediate / reified node (Order entity)',
      m.appliedAt   = datetime();
