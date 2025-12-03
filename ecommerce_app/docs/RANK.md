# SUMMARY OF THE RANK
Refs:
- https://docs.vespa.ai/en/reference/nativerank.html
- https://docs.vespa.ai/en/ranking/bm25.html
- https://docs.vespa.ai/en/ranking.html

## What is Ranking in Vespa?

**Ranking** determines how relevant each document is to a query and sorts results by relevance. It's the "scoring system" that decides which documents appear first in search results.

Think of it as Vespa's equivalent to:
- **PostgreSQL**: `ORDER BY` with custom scoring functions
- **MongoDB**: `$sort` with `$textScore` or custom scoring
- **Elasticsearch**: `_score` calculation and custom scoring functions

**Key Concept:** Ranking happens **after** documents are matched by your query. It answers: "Of all matching documents, which are most relevant?"

---

## Ranking vs. Other Systems

### Comparison Table

| Concept | Vespa | PostgreSQL | MongoDB | Elasticsearch |
|---------|-------|------------|---------|---------------|
| **Ranking Function** | Rank profiles | `ORDER BY` + custom functions | `$sort` + `$textScore` | `_score` + custom scoring |
| **Text Relevance** | `nativeRank`, `bm25` | `ts_rank`, `ts_rank_cd` | `$meta: "textScore"` | `match` query score |
| **Vector Similarity** | `closeness`, `distance` | `<=>` operator | `$vectorSearch` | `knn` query score |
| **Multiple Phases** | First-phase, second-phase, global-phase | Single phase | Single phase | Rescoring |
| **ML Models** | ONNX, XGBoost, LightGBM | Custom functions | Custom aggregation | Learning to Rank |
| **Configuration** | Rank profiles in schema | SQL functions | Aggregation pipeline | Query DSL |

### Key Differences

1. **Multi-Phase Ranking**: Vespa supports multiple ranking phases for performance optimization
2. **Built-in Functions**: `nativeRank`, `bm25`, `closeness` are built-in and optimized
3. **ML Integration**: Easy integration with ONNX, XGBoost, LightGBM models
4. **Rank Profiles**: Multiple ranking strategies per schema for A/B testing

---

## Rank Profiles

A **rank profile** defines how documents are scored. You can have multiple rank profiles in one schema for different use cases.

### Basic Rank Profile

```vespa
schema product {
    document product {
        field title type string {
            indexing: summary | index
        }
        field description type string {
            indexing: summary | index
        }
    }
    
    rank-profile default {
        first-phase {
            expression: nativeRank(title, description)
        }
    }
}
```

### Multiple Rank Profiles

```vespa
schema product {
    // ... fields ...
    
    rank-profile default {
        first-phase {
            expression: nativeRank(title, description)
        }
    }
    
    rank-profile bm25 {
        first-phase {
            expression: bm25(title) + bm25(description)
        }
    }
    
    rank-profile hybrid {
        first-phase {
            expression {
                0.6 * bm25(title) + 0.4 * closeness(embedding)
            }
        }
    }
}
```

**Using different profiles:**

```bash
# Use default profile
vespa query 'yql=select * from product where userQuery()'

# Use bm25 profile
vespa query 'yql=select * from product where userQuery()' 'ranking=bm25'

# Use hybrid profile
vespa query 'yql=select * from product where userQuery()' 'ranking=hybrid'
```

---

## Ranking Phases

Vespa uses **multi-phase ranking** to balance performance and accuracy:

### 1. First-Phase Ranking

**Purpose:** Quick, efficient ranking of all matching documents

**Characteristics:**
- Runs on **all** matching documents
- Must be **fast** (computationally efficient)
- Uses simple functions: `nativeRank`, `bm25`, `closeness`, `attribute`

**Example:**

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description)
    }
}
```

**Best Practices:**
- Use simple, fast functions
- Avoid complex ML models here
- Focus on speed over precision

### 2. Second-Phase Ranking

**Purpose:** More accurate ranking of top candidates

**Characteristics:**
- Runs on **top N** documents from first phase (default: 100)
- Can be **more expensive** (complex calculations)
- Can use ML models, complex expressions

**Example:**

```vespa
rank-profile advanced {
    first-phase {
        expression: bm25(title) + bm25(description)
    }
    second-phase {
        expression: xgboost("my_model.json")
    }
}
```

**Best Practices:**
- Use for complex ranking logic
- Apply ML models here
- Balance accuracy vs. latency

### 3. Global-Phase Ranking (Advanced)

**Purpose:** Final re-ranking after merging results from all nodes

**Characteristics:**
- Runs **after** merging results from all content nodes
- Useful for **global** features (e.g., popularity across all nodes)
- Most expensive phase

**Example:**

```vespa
rank-profile global {
    first-phase {
        expression: bm25(title)
    }
    global-phase {
        expression: firstPhase + globalPopularity
    }
}
```

**When to Use:**
- Need global statistics
- Cross-node features
- Final re-ranking with expensive models

---

## nativeRank Function

**`nativeRank`** is Vespa's default text ranking function. It considers:
- **Term frequency** - How often query terms appear
- **Term proximity** - How close query terms are to each other
- **Field importance** - Which fields are more important
- **Document length** - Normalizes for document size

### Basic Usage

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description)
    }
}
```

**What it does:**
- Searches in `title` and `description` fields
- Scores based on term matches and proximity
- Higher score = more relevant

### Multiple Fields

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description, tags)
    }
}
```

**All fields weighted equally** by default.

### Weighted Fields

```vespa
rank-profile weighted {
    first-phase {
        expression {
            0.5 * nativeRank(title) +
            0.3 * nativeRank(description) +
            0.2 * nativeRank(tags)
        }
    }
}
```

**Title is most important** (50%), then description (30%), then tags (20%).

### How nativeRank Works

1. **Term Matching**: Finds query terms in specified fields
2. **Frequency**: Counts how many times terms appear
3. **Proximity**: Measures how close terms are to each other
4. **Normalization**: Adjusts for document length
5. **Scoring**: Combines all factors into a relevance score

**Advantages:**
- ✅ Fast and efficient
- ✅ Good default for text search
- ✅ Considers term proximity
- ✅ No configuration needed

**When to Use:**
- Default text search
- Simple use cases
- Need fast ranking
- Good baseline

---

## BM25 Function

**`bm25`** is the **Okapi BM25** algorithm, a widely-used text ranking function. It's based on:
- **Term Frequency (TF)** - How often terms appear
- **Inverse Document Frequency (IDF)** - How rare terms are
- **Field Length Normalization** - Adjusts for field size

### Basic Usage

```vespa
rank-profile bm25 {
    first-phase {
        expression: bm25(title) + bm25(description)
    }
}
```

### Single Field

```vespa
rank-profile bm25-title {
    first-phase {
        expression: bm25(title)
    }
}
```

### Multiple Fields with Weights

```vespa
rank-profile bm25-weighted {
    first-phase {
        expression {
            0.6 * bm25(title) +
            0.4 * bm25(description)
        }
    }
}
```

### BM25 Parameters (Advanced)

BM25 has tunable parameters (usually defaults are fine):

```vespa
rank-profile bm25-tuned {
    first-phase {
        expression: bm25(title)
    }
    constants {
        bm25(title).k1: 1.2
        bm25(title).b: 0.75
    }
}
```

**Parameters:**
- `k1` - Term frequency saturation (default: 1.2)
- `b` - Field length normalization (default: 0.75)

**Tuning Tips:**
- Increase `k1` → More weight to term frequency
- Decrease `k1` → Less weight to term frequency
- Increase `b` → More normalization for long fields
- Decrease `b` → Less normalization

### How BM25 Works

1. **Term Frequency (TF)**: Counts occurrences of query terms
2. **Inverse Document Frequency (IDF)**: Measures how rare/common terms are
3. **Field Length**: Normalizes for field size (longer fields get slight penalty)
4. **Combination**: Combines TF, IDF, and length into score

**Formula (simplified):**
```
score = IDF × (TF × (k1 + 1)) / (TF + k1 × (1 - b + b × (field_length / avg_field_length)))
```

**Advantages:**
- ✅ Industry-standard algorithm
- ✅ Well-tested and proven
- ✅ Good for general text search
- ✅ Tunable parameters

**When to Use:**
- Standard text search
- Need proven algorithm
- Want to match industry standards
- Baseline for comparison

---

## nativeRank vs. BM25

### Comparison

| Feature | nativeRank | BM25 |
|---------|------------|------|
| **Algorithm** | Vespa-specific | Okapi BM25 (industry standard) |
| **Term Proximity** | ✅ Yes | ❌ No |
| **Speed** | ⚡ Very fast | ⚡ Fast |
| **Tunability** | Limited | ✅ Highly tunable |
| **Industry Standard** | ❌ No | ✅ Yes |
| **Best For** | Default, simple cases | Standard text search |

### When to Use Each

**Use nativeRank when:**
- ✅ Need term proximity (terms close together score higher)
- ✅ Want Vespa's optimized default
- ✅ Simple use cases
- ✅ Fast ranking is priority

**Use BM25 when:**
- ✅ Want industry-standard algorithm
- ✅ Need tunable parameters
- ✅ Comparing with other systems
- ✅ Standard text search requirements

### Example: Both in One Profile

```vespa
rank-profile comparison {
    first-phase {
        expression {
            0.5 * nativeRank(title, description) +
            0.5 * bm25(title) + bm25(description)
        }
    }
}
```

---

## Other Ranking Features

### closeness() - Vector Similarity

**For vector/embedding fields:**

```vespa
rank-profile vector {
    first-phase {
        expression: closeness(embedding)
    }
}
```

**How it works:**
- Measures cosine similarity between query vector and document vector
- Higher score = more similar vectors
- Used for semantic search

**Example:**

```vespa
rank-profile semantic {
    first-phase {
        expression: closeness(embedding)
    }
}
```

**Query:**
```bash
vespa query \
  'yql=select * from product where {targetHits: 10}nearestNeighbor(embedding, query_vector)' \
  'input.query(query_vector)=[0.1,0.2,0.3,...]'
```

### distance() - Vector Distance

**Inverse of closeness (lower is better):**

```vespa
rank-profile vector-distance {
    first-phase {
        expression: -distance(embedding)  # Negative because lower distance = higher relevance
    }
}
```

### attribute() - Field Values

**Use attribute values directly in ranking:**

```vespa
rank-profile popularity {
    first-phase {
        expression {
            0.7 * bm25(title) +
            0.3 * attribute(popularity_score)
        }
    }
}
```

**Use cases:**
- Popularity scores
- User ratings
- View counts
- Custom signals

### fieldMatch() - Field Matching Quality

**Measures how well query matches a field:**

```vespa
rank-profile field-match {
    first-phase {
        expression: fieldMatch(title) + fieldMatch(description)
    }
}
```

**Returns:** Score based on query-term matches in the field

---

## Hybrid Ranking (Text + Vector)

**Combine text search and vector search** for best results:

### Example 1: Simple Hybrid

```vespa
rank-profile hybrid {
    first-phase {
        expression {
            0.6 * bm25(title) +
            0.4 * closeness(embedding)
        }
    }
}
```

**Query:**
```bash
vespa query \
  'yql=select * from product where userQuery(title) and {targetHits: 10}nearestNeighbor(embedding, query_vector)' \
  'query=gaming laptop' \
  'input.query(query_vector)=[0.1,0.2,...]' \
  'ranking=hybrid'
```

### Example 2: Weighted Hybrid

```vespa
rank-profile hybrid-weighted {
    constants {
        text_weight: 0.7
        vector_weight: 0.3
    }
    first-phase {
        expression {
            text_weight * (bm25(title) + bm25(description)) +
            vector_weight * closeness(embedding)
        }
    }
}
```

**Adjust weights** by changing constants.

### Example 3: Multi-Signal Hybrid

```vespa
rank-profile multi-signal {
    first-phase {
        expression {
            0.4 * bm25(title) +
            0.2 * bm25(description) +
            0.2 * closeness(embedding) +
            0.1 * attribute(rating) +
            0.1 * attribute(popularity)
        }
    }
}
```

**Combines:**
- Text relevance (title + description)
- Semantic similarity (vector)
- User ratings
- Popularity signals

---

## Ranking with Machine Learning Models

Vespa supports integrating ML models into ranking:

### ONNX Models

```vespa
rank-profile ml-onnx {
    first-phase {
        expression: bm25(title)
    }
    second-phase {
        expression: onnx("my_model.onnx")
    }
}
```

### XGBoost Models

```vespa
rank-profile ml-xgboost {
    first-phase {
        expression: bm25(title)
    }
    second-phase {
        expression: xgboost("my_model.json")
    }
}
```

### LightGBM Models

```vespa
rank-profile ml-lightgbm {
    first-phase {
        expression: bm25(title)
    }
    second-phase {
        expression: lightgbm("my_model.txt")
    }
}
```

**Best Practice:** Use ML models in **second-phase** (not first-phase) for performance.

---

## Common Ranking Patterns

### Pattern 1: Simple Text Search

```vespa
rank-profile text-only {
    first-phase {
        expression: nativeRank(title, description)
    }
}
```

### Pattern 2: BM25 Text Search

```vespa
rank-profile bm25-only {
    first-phase {
        expression: bm25(title) + bm25(description)
    }
}
```

### Pattern 3: Vector Search Only

```vespa
rank-profile vector-only {
    first-phase {
        expression: closeness(embedding)
    }
}
```

### Pattern 4: Hybrid Search

```vespa
rank-profile hybrid {
    first-phase {
        expression {
            0.6 * bm25(title) +
            0.4 * closeness(embedding)
        }
    }
}
```

### Pattern 5: Text + Popularity

```vespa
rank-profile text-popularity {
    first-phase {
        expression {
            0.8 * bm25(title) +
            0.2 * attribute(rating)
        }
    }
}
```

### Pattern 6: Multi-Phase with ML

```vespa
rank-profile ml-two-phase {
    first-phase {
        expression: bm25(title) + bm25(description)
    }
    second-phase {
        expression: xgboost("relevance_model.json")
    }
}
```

### Pattern 7: E-commerce Ranking

```vespa
rank-profile ecommerce {
    first-phase {
        expression {
            0.3 * bm25(title) +
            0.2 * bm25(description) +
            0.2 * closeness(embedding) +
            0.1 * attribute(rating) +
            0.1 * attribute(review_count) +
            0.1 * attribute(sales_rank)
        }
    }
}
```

---

## Best Practices

### 1. Start Simple

**Begin with default ranking:**

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description)
    }
}
```

**Then iterate** based on results.

### 2. Use First-Phase for Speed

**Keep first-phase fast:**

```vespa
# ✅ Good - Fast functions
first-phase {
    expression: bm25(title) + bm25(description)
}

# ❌ Avoid - Slow ML models
first-phase {
    expression: xgboost("model.json")  # Too slow!
}
```

### 3. Use Second-Phase for Accuracy

**Put expensive operations in second-phase:**

```vespa
rank-profile accurate {
    first-phase {
        expression: bm25(title)  # Fast
    }
    second-phase {
        expression: xgboost("model.json")  # Expensive but accurate
    }
}
```

### 4. Test Multiple Profiles

**Create multiple profiles for A/B testing:**

```vespa
rank-profile baseline {
    first-phase {
        expression: nativeRank(title)
    }
}

rank-profile experiment {
    first-phase {
        expression: bm25(title)
    }
}
```

**Test both** and compare results.

### 5. Normalize Scores

**If combining different score types, normalize:**

```vespa
rank-profile normalized {
    first-phase {
        expression {
            0.5 * (bm25(title) / max(bm25(title))) +
            0.5 * (closeness(embedding) / max(closeness(embedding)))
        }
    }
}
```

### 6. Use Constants for Tuning

**Make weights easy to adjust:**

```vespa
rank-profile tunable {
    constants {
        text_weight: 0.6
        vector_weight: 0.4
    }
    first-phase {
        expression {
            text_weight * bm25(title) +
            vector_weight * closeness(embedding)
        }
    }
}
```

**Change constants** without rewriting expressions.

### 7. Monitor Performance

**Check ranking performance:**

```bash
# Check query latency
curl http://localhost:8080/metrics/v1/values | grep query

# Profile queries
vespa query 'yql=...' 'traceLevel=5'
```

---

## Troubleshooting

### Low Relevance Scores

**Problem:** Documents don't seem relevant

**Solutions:**
1. **Check field indexing:**
   ```vespa
   field title type string {
       indexing: summary | index  # Must have 'index'
   }
   ```

2. **Verify query matches:**
   ```bash
   vespa query 'yql=select * from product where title contains "laptop"'
   ```

3. **Try different ranking:**
   ```vespa
   # Try BM25 instead of nativeRank
   expression: bm25(title) + bm25(description)
   ```

### Slow Ranking

**Problem:** Queries are slow

**Solutions:**
1. **Simplify first-phase:**
   ```vespa
   # ✅ Fast
   first-phase {
       expression: bm25(title)
   }
   
   # ❌ Slow
   first-phase {
       expression: complex_ml_model()
   }
   ```

2. **Move expensive operations to second-phase**

3. **Reduce second-phase candidates:**
   ```vespa
   rank-profile fast {
       first-phase {
           expression: bm25(title)
       }
       second-phase {
           rerank-count: 50  # Only rerank top 50
           expression: xgboost("model.json")
       }
   }
   ```

### Inconsistent Results

**Problem:** Same query returns different results

**Solutions:**
1. **Check for multiple rank profiles:**
   ```bash
   # Always specify ranking
   vespa query 'yql=...' 'ranking=default'
   ```

2. **Verify data consistency:**
   ```bash
   # Check documents are indexed
   vespa query 'yql=select * from product where true'
   ```

3. **Check for updates:**
   - Documents may have been updated
   - Index may be rebuilding

---

## Quick Reference

### Rank Profile Structure

```vespa
rank-profile <name> {
    constants {
        <name>: <value>
    }
    first-phase {
        expression: <expression>
    }
    second-phase {
        rerank-count: <number>
        expression: <expression>
    }
    global-phase {
        expression: <expression>
    }
}
```

### Common Ranking Functions

| Function | Usage | Best For |
|----------|-------|----------|
| `nativeRank(field...)` | Text search with proximity | Default text search |
| `bm25(field)` | Standard text search | Industry-standard ranking |
| `closeness(tensor)` | Vector similarity | Semantic search |
| `distance(tensor)` | Vector distance | Vector search (inverted) |
| `attribute(field)` | Field value | Popularity, ratings |
| `fieldMatch(field)` | Field match quality | Field-specific relevance |

### Common Expressions

```vespa
# Simple text
nativeRank(title, description)

# BM25 text
bm25(title) + bm25(description)

# Vector
closeness(embedding)

# Hybrid
0.6 * bm25(title) + 0.4 * closeness(embedding)

# Multi-signal
0.5 * bm25(title) + 0.3 * closeness(embedding) + 0.2 * attribute(rating)
```

---

## Key Takeaways for Newbies

1. **Ranking determines relevance** - It scores and sorts matching documents
2. **Rank profiles define scoring** - Each schema can have multiple profiles
3. **Multi-phase ranking** - First-phase (fast), second-phase (accurate), global-phase (advanced)
4. **nativeRank** - Vespa's default, considers term proximity
5. **BM25** - Industry-standard text ranking algorithm
6. **closeness()** - For vector/semantic search
7. **Hybrid ranking** - Combine text + vector for best results
8. **Start simple** - Use `nativeRank` or `bm25` first, then iterate
9. **Keep first-phase fast** - Use simple functions, save ML for second-phase
10. **Test multiple profiles** - A/B test different ranking strategies

---

## Resources

- **Ranking Overview**: https://docs.vespa.ai/en/ranking.html
- **nativeRank Reference**: https://docs.vespa.ai/en/reference/nativerank.html
- **BM25 Reference**: https://docs.vespa.ai/en/ranking/bm25.html
- **Rank Features**: https://docs.vespa.ai/en/reference/rank-features.html
- **Phased Ranking**: https://docs.vespa.ai/en/phased-ranking.html
- **Ranking Expressions**: https://docs.vespa.ai/en/reference/ranking-expressions.html

---

## Next Steps

After mastering ranking basics:

1. **Learn Phased Ranking** - Optimize performance with multi-phase ranking
2. **Explore ML Models** - Integrate ONNX, XGBoost, LightGBM models
3. **Learn Rank Features** - Discover all available ranking functions
4. **A/B Testing** - Test different ranking strategies
5. **Performance Tuning** - Optimize ranking for your use case

For more examples, check out:
- `simple_ecommerce_app/README.md` - Basic ranking examples
- `ecommerce_app/README.md` - Advanced ranking patterns
- Sample applications: https://github.com/vespa-engine/sample-apps
