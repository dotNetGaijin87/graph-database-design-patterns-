// ---------------------------------------------------------------------------
// Naming conventions
// ---------------------------------------------------------------------------
// A property graph has three kinds of building blocks — node labels, relationship
// types and properties — and a different idiom for each. These are the Neo4j /
// openCypher community conventions, and they are used consistently throughout
// this repo. (The sister relational repo uses snake_case for everything; Cypher
// deliberately distinguishes the three kinds by casing, which is itself a small
// design lesson — see pattern 003.)
// ---------------------------------------------------------------------------
// Node label              : PascalCase, singular noun
//                         : (:Customer), (:Product), (:Order), (:Category)
// ---------------------------------------------------------------------------
// Secondary / sub labels  : PascalCase, stacked on the primary label
//                         : (:Product:Software), (:Product:Hardware)
// ---------------------------------------------------------------------------
// Relationship type       : UPPER_SNAKE_CASE, a verb phrase read left-to-right
//                         : (:Customer)-[:PLACED]->(:Order)
//                         : (:Order)-[:CONTAINS]->(:Product)
//                         : (:Product)-[:IN_CATEGORY]->(:Category)
// ---------------------------------------------------------------------------
// Property key            : camelCase, singular
//                         : customerId, listPrice, firstName, orderDate
// ---------------------------------------------------------------------------
// Business / identity key : <entity>Id, made unique with a constraint (001)
//                         : customerId, productId, orderId
// ---------------------------------------------------------------------------
// Constraint name         : <entity>_<property>_<kind>
//                         : customer_email_unique, product_productId_unique
// ---------------------------------------------------------------------------
// Index name              : <entity>_<property(ies)> [ _ <kind> ]
//                         : product_name, customer_lastName_text
// ---------------------------------------------------------------------------
// Relationship-property   : ()-[r:CONTAINS]-() ON (r.quantity)
// index                   : index name -> contains_quantity
// ---------------------------------------------------------------------------
//
// Migration history
// -----------------
// The sister relational repo records each applied migration in a
// dbo.migration_history TABLE. A graph has no tables, so we record the same
// audit trail as a chain of (:_Migration) nodes — itself a tiny taste of the
// "model everything as a graph" mindset.

CREATE CONSTRAINT migration_id_unique IF NOT EXISTS
  FOR (m:_Migration) REQUIRE m.id IS UNIQUE;

// Usage (every src/0NN script ends with a line like this):
//   MERGE (m:_Migration {id: 1})
//     SET m.description = 'Constraints & node keys',
//         m.appliedAt   = datetime();
