// ===========================================================================
// Script 000
//
//   INITIAL GRAPH & DIAGNOSTIC TOOLING
//
//   Creates the OnlineStore property graph in a deliberately naive shape, so
//   the 12 later migrations have real anti-patterns to fix. Unlike a relational
//   schema, a graph has no separate DDL step — the "initial schema" and its
//   seed data are one and the same, so this single file plays the role of both
//   000_initial_schema_creation.sql AND seed_db.sql in the sister repo.
//
//   Baked-in anti-patterns (and where each is fixed):
//     * no constraints or indexes at all .................. fixed in 001 / 002
//     * relationships faked as id properties
//         - Review.authorId / Review.productId ............ fixed in 003
//         - ORDERED.orderId (no Order entity) ............. fixed in 006
//     * repeated strings instead of nodes
//         - Product.vendorName, Customer.state ............ fixed in 004
//     * a delimited string instead of a real hierarchy
//         - Product.category = "Electronics/Audio/..." .... fixed in 004 / 007
//     * a CSV string instead of relationships
//         - Customer.wishlist = "A,B,C" ................... fixed in 005
//     * orders flattened onto Customer->Product edges ..... fixed in 006
//     * sub-type attributes as nullable properties
//         - Product.compatibleOs / requiredRam ............ fixed in 008
//     * PII inlined on the customer (Customer.creditCard)
// ===========================================================================


// ---------------------------------------------------------------------------
// Customers — name is one blob, state is a bare string, the wishlist is a CSV
// string of product NAMES (not ids), and the credit card is inlined PII.
// ---------------------------------------------------------------------------
UNWIND [
  {customerId:'C1', name:'Alice Johnson',  email:'alice@example.com', state:'CA', creditCard:'4111-1111-1111-1111', wishlist:'Noise-Cancelling Headphones,4K Webcam'},
  {customerId:'C2', name:'Bob Smith',      email:'bob@example.com',   state:'NY', creditCard:'4111-2222-3333-4444', wishlist:'Mechanical Keyboard'},
  {customerId:'C3', name:'Carol Williams', email:'carol@example.com', state:'CA', creditCard:'4111-5555-6666-7777', wishlist:'Noise-Cancelling Headphones,Photo Editor Pro'},
  {customerId:'C4', name:'David Brown',    email:'david@example.com', state:'TX', creditCard:'4111-8888-9999-0000', wishlist:''},
  {customerId:'C5', name:'Eve Davis',      email:'eve@example.com',   state:'NY', creditCard:'4111-1212-3434-5656', wishlist:'Gaming Mouse,Mechanical Keyboard'},
  {customerId:'C6', name:'Frank Miller',   email:'frank@example.com', state:'CA', creditCard:'4111-7878-9090-1212', wishlist:'4K Webcam'}
] AS row
CREATE (c:Customer) SET c = row;


// ---------------------------------------------------------------------------
// Products — category is a "/"-delimited path string, the vendor is a repeated
// free-text name, and software-only attributes sit as nullable properties on
// the same node shape as the hardware products.
// ---------------------------------------------------------------------------
UNWIND [
  {productId:'P001', name:'Noise-Cancelling Headphones', category:'Electronics/Audio/Headphones',     vendorName:'Acme Audio',  listPrice:299.00},
  {productId:'P002', name:'4K Webcam',                   category:'Electronics/Video/Webcams',        vendorName:'Acme Audio',  listPrice:129.00},
  {productId:'P003', name:'Mechanical Keyboard',         category:'Electronics/Peripherals/Keyboards', vendorName:'KeyWorks',    listPrice:89.00},
  {productId:'P004', name:'Gaming Mouse',                category:'Electronics/Peripherals/Mice',      vendorName:'KeyWorks',    listPrice:59.00},
  {productId:'P005', name:'Photo Editor Pro',            category:'Software/Creative',                 vendorName:'PixelSoft',   listPrice:199.00, compatibleOs:'Windows, macOS', requiredRam:8.0},
  {productId:'P006', name:'Office Suite',                category:'Software/Productivity',             vendorName:'PixelSoft',   listPrice:149.00, compatibleOs:'Windows, macOS, Linux', requiredRam:4.0},
  {productId:'P007', name:'USB-C Hub',                   category:'Electronics/Peripherals/Adapters',  vendorName:'ConnectCo',   listPrice:39.00},
  {productId:'P008', name:'Studio Microphone',           category:'Electronics/Audio/Microphones',     vendorName:'Acme Audio',  listPrice:179.00},
  {productId:'P009', name:'Webcam Light',                category:'Electronics/Video/Lighting',        vendorName:'ConnectCo',   listPrice:49.00},
  {productId:'P010', name:'Antivirus Plus',              category:'Software/Security',                 vendorName:'PixelSoft',   listPrice:79.00, compatibleOs:'Windows', requiredRam:2.0}
] AS row
CREATE (p:Product) SET p = row;


// ---------------------------------------------------------------------------
// Orders — there is no Order node. Each order LINE is a Customer->Product edge,
// and the only thing tying the two lines of order O1002 together is a repeated
// orderId *property*. You cannot ask "what was in order O1002?" without scanning
// every edge. This is foreign-key thinking carried into a graph.
// ---------------------------------------------------------------------------
UNWIND [
  {customerId:'C1', productId:'P001', orderId:'O1001', quantity:1, orderDate:date('2024-01-15'), status:'DELIVERED',  listPrice:299.00},
  {customerId:'C1', productId:'P007', orderId:'O1001', quantity:1, orderDate:date('2024-01-15'), status:'DELIVERED',  listPrice:39.00},
  {customerId:'C2', productId:'P003', orderId:'O1002', quantity:1, orderDate:date('2024-02-03'), status:'DELIVERED',  listPrice:89.00},
  {customerId:'C2', productId:'P004', orderId:'O1002', quantity:2, orderDate:date('2024-02-03'), status:'DELIVERED',  listPrice:59.00},
  {customerId:'C3', productId:'P001', orderId:'O1003', quantity:1, orderDate:date('2024-02-20'), status:'SHIPPED',    listPrice:299.00},
  {customerId:'C3', productId:'P005', orderId:'O1003', quantity:1, orderDate:date('2024-02-20'), status:'SHIPPED',    listPrice:199.00},
  {customerId:'C4', productId:'P008', orderId:'O1004', quantity:1, orderDate:date('2024-03-01'), status:'DELIVERED',  listPrice:179.00},
  {customerId:'C5', productId:'P003', orderId:'O1005', quantity:1, orderDate:date('2024-03-10'), status:'PROCESSING', listPrice:89.00},
  {customerId:'C5', productId:'P004', orderId:'O1005', quantity:1, orderDate:date('2024-03-10'), status:'PROCESSING', listPrice:59.00},
  {customerId:'C6', productId:'P002', orderId:'O1006', quantity:1, orderDate:date('2024-03-12'), status:'DELIVERED',  listPrice:129.00},
  {customerId:'C6', productId:'P009', orderId:'O1006', quantity:1, orderDate:date('2024-03-12'), status:'DELIVERED',  listPrice:49.00},
  {customerId:'C1', productId:'P002', orderId:'O1007', quantity:1, orderDate:date('2024-04-02'), status:'DELIVERED',  listPrice:129.00},
  {customerId:'C3', productId:'P008', orderId:'O1008', quantity:1, orderDate:date('2024-04-15'), status:'DELIVERED',  listPrice:179.00}
] AS line
MATCH (c:Customer {customerId: line.customerId})
MATCH (p:Product  {productId:  line.productId})
CREATE (c)-[r:ORDERED]->(p)
SET r.orderId   = line.orderId,
    r.quantity  = line.quantity,
    r.orderDate = line.orderDate,
    r.status    = line.status,
    r.listPrice = line.listPrice;


// ---------------------------------------------------------------------------
// Reviews — created as ISLAND nodes. They reference the author and the product
// by id *properties* (authorId / productId) instead of by relationships, so
// they are not actually connected to anything in the graph. Traversing from a
// product to its reviews is impossible until 003 turns these ids into edges.
// ---------------------------------------------------------------------------
UNWIND [
  {reviewId:'R1', authorId:'C1', productId:'P001', rating:5, content:'Incredible noise cancellation.', createdAt:date('2024-02-01')},
  {reviewId:'R2', authorId:'C3', productId:'P001', rating:4, content:'Great, but pricey.',            createdAt:date('2024-03-05')},
  {reviewId:'R3', authorId:'C2', productId:'P003', rating:5, content:'Best keyboard I have owned.',   createdAt:date('2024-02-20')},
  {reviewId:'R4', authorId:'C5', productId:'P004', rating:3, content:'The mouse is just okay.',       createdAt:date('2024-03-25')},
  {reviewId:'R5', authorId:'C4', productId:'P008', rating:4, content:'Crisp, clean audio.',           createdAt:date('2024-03-20')},
  {reviewId:'R6', authorId:'C6', productId:'P002', rating:5, content:'Razor-sharp 4K image.',         createdAt:date('2024-03-30')}
] AS row
CREATE (rv:Review) SET rv = row;


// ===========================================================================
// Diagnostic tooling
// ---------------------------------------------------------------------------
// Every later lesson proves an improvement actually happened, so we need a way
// to introspect the graph. These are the graph equivalents of the relational
// repo's DBCC / sys.dm_* diagnostic procedures — run them now to capture the
// naive baseline, then again after any migration to see what changed.
// ===========================================================================

// -- Node counts per label
MATCH (n)
RETURN labels(n) AS labels, count(*) AS count
ORDER BY count DESC;

// -- Relationship counts per type
MATCH ()-[r]->()
RETURN type(r) AS relationshipType, count(*) AS count
ORDER BY count DESC;

// -- The live schema as Neo4j infers it (note how Review is an island here)
CALL db.schema.visualization();

// -- Whole-graph statistics (APOC core, shipped with the Docker image)
CALL apoc.meta.stats()
YIELD nodeCount, relCount, labelCount, relTypeCount, labels
RETURN nodeCount, relCount, labelCount, relTypeCount, labels;

// -- Constraints & indexes: both empty at this point (the gap 001 / 002 close)
SHOW CONSTRAINTS;
SHOW INDEXES;


// ---------------------------------------------------------------------------
// Record this migration (see helpers/conventions.cypher for the convention)
// ---------------------------------------------------------------------------
MERGE (m:_Migration {id: 0})
  SET m.description = 'Initial naive graph & diagnostic tooling',
      m.appliedAt   = datetime();
