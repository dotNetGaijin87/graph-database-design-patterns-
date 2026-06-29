# Diagram sources

Before/after pictures of the `OnlineStore` graph, in the Neo4j property-graph style
(blue circles + labeled relationships). Each `.dot` is the editable [Graphviz](https://graphviz.org)
source; the `.svg` is the render embedded in the main README.

| File | Shows |
| ---- | ----- |
| `graph-neo4j-before.{dot,svg}` | the naive starting graph (anti-patterns baked in) |
| `graph-neo4j-after.{dot,svg}`  | the evolved graph after all 12 migrations |

## Regenerate (needs [Graphviz](https://graphviz.org) `dot` on PATH)

```bash
dot -Tsvg graph-neo4j-before.dot -o graph-neo4j-before.svg
dot -Tsvg graph-neo4j-after.dot  -o graph-neo4j-after.svg
```

Swap `-Tsvg x.svg` for `-Tpng -Gdpi=150 x.png` to produce PNGs instead.
