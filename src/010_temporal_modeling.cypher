// ===========================================================================
// Script 010
//
//   TEMPORAL MODELING  (state history & the time-tree)
//
//   An order's status is a single property — a snapshot that forgets every
//   prior state. The relational answer is a history table or a system-versioned
//   temporal table (patterns 012/013). A graph models time as STRUCTURE: a
//   linked list of state nodes with a CURRENT pointer (O(1) "what is it now?"),
//   and a time-tree that turns date-range scans into traversals.
// ===========================================================================


// ---------------------------------------------------------------------------
// PART A — order status history as a linked list of (:OrderStatus) nodes.
//   We only stored the current status, so we synthesize the progression that
//   led to it (PLACED -> PROCESSING -> SHIPPED -> DELIVERED, truncated at the
//   order's actual current status).
// ---------------------------------------------------------------------------

// 1. One OrderStatus node per stage the order has reached, tagged with a seq.
WITH ['PLACED', 'PROCESSING', 'SHIPPED', 'DELIVERED'] AS stages
MATCH (o:Order)
WITH o, [s IN stages WHERE apoc.coll.indexOf(stages, s) <= apoc.coll.indexOf(stages, o.status)] AS reached
UNWIND range(0, size(reached) - 1) AS i
CREATE (st:OrderStatus {status: reached[i], seq: i, at: o.orderDate + duration({days: i * 2})})
CREATE (o)-[:HAS_STATUS]->(st);

// 2. Chain consecutive states with NEXT (the linked list).
MATCH (o:Order)-[:HAS_STATUS]->(a:OrderStatus)
MATCH (o)-[:HAS_STATUS]->(b:OrderStatus)
WHERE b.seq = a.seq + 1
MERGE (a)-[:NEXT]->(b);

// 3. A direct CURRENT_STATUS pointer to the latest state — current state in one
//    hop, no scanning of the chain.
MATCH (o:Order)-[:HAS_STATUS]->(st:OrderStatus)
WITH o, st ORDER BY st.seq DESC
WITH o, head(collect(st)) AS latest
MERGE (o)-[:CURRENT_STATUS]->(latest);

// 4. The snapshot property is now derived data — drop it (a cached copy is the
//    denormalization of pattern 012, deliberately not kept here).
MATCH (o:Order)
REMOVE o.status;


// ---------------------------------------------------------------------------
// PART B — a time-tree: Year -> Month -> Day, with each order hung off its day.
//   Date-range questions become walks of a small calendar skeleton instead of
//   scans/filters over every order's date property.
// ---------------------------------------------------------------------------
MATCH (o:Order)
MERGE (y:Year  {value: o.orderDate.year})
MERGE (m:Month {year: o.orderDate.year, value: o.orderDate.month})
MERGE (d:Day   {date: o.orderDate})
MERGE (y)-[:HAS_MONTH]->(m)
MERGE (m)-[:HAS_DAY]->(d)
MERGE (o)-[:ORDERED_ON]->(d);


// ---------------------------------------------------------------------------
// The payoff:
// ---------------------------------------------------------------------------

// Full status timeline of an order (walk the NEXT chain from its first state):
MATCH (o:Order {orderId: 'O1003'})-[:HAS_STATUS]->(first:OrderStatus)
WHERE NOT ()-[:NEXT]->(first)
MATCH path = (first)-[:NEXT*0..]->(last:OrderStatus)
RETURN o.orderId AS orderId, [s IN nodes(path) | s.status + ' @ ' + toString(s.at)] AS timeline
ORDER BY length(path) DESC LIMIT 1;

// Current status in one hop:
MATCH (o:Order {orderId: 'O1003'})-[:CURRENT_STATUS]->(st:OrderStatus)
RETURN o.orderId AS orderId, st.status AS currentStatus;

// Every order placed in March 2024 — a traversal of the time-tree:
MATCH (:Year {value: 2024})-[:HAS_MONTH]->(:Month {value: 3})-[:HAS_DAY]->(d:Day)<-[:ORDERED_ON]-(o:Order)
RETURN d.date AS day, collect(o.orderId) AS orders
ORDER BY day;


// ---------------------------------------------------------------------------
// Trade-off note:
//   * The linked list keeps history immutable and append-only (good for audit),
//     but reading a full timeline is O(chain length); the CURRENT_STATUS
//     shortcut exists precisely so the common "current state" read stays O(1).
//   * A time-tree pays off when you slice by calendar buckets a lot; if you only
//     ever filter on an exact timestamp, a plain range index on orderDate is
//     simpler. Don't build calendar scaffolding you won't traverse.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 10})
  SET m.description = 'Temporal modeling (state history + time-tree)',
      m.appliedAt   = datetime();
