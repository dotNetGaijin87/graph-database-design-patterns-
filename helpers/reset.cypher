// ---------------------------------------------------------------------------
// reset.cypher — tear the graph back down to an empty database
// ---------------------------------------------------------------------------
// Run this to wipe every node, relationship, constraint and index so you can
// re-apply the sequence from src/000 again. (To wipe the data volume entirely
// instead, use `docker compose down -v`.)
// ---------------------------------------------------------------------------

// 1. Delete all data. For a small teaching graph a single DETACH DELETE is fine;
//    on a large graph you would batch this with apoc.periodic.iterate.
MATCH (n) DETACH DELETE n;

// 2. Drop every constraint and index (these survive a DETACH DELETE).
CALL apoc.schema.assert({}, {}, true) YIELD label, key
RETURN label, key;
