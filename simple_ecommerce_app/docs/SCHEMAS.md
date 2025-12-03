# SUMMARY OF THE SCHEMAS
Ref: https://docs.vespa.ai/en/schemas.html

## What is a Vespa Schema?

A **Vespa schema** is a blueprint that defines:
- How your data is **stored** in Vespa
- How your data is **indexed** for search
- How your data is **processed** and **retrieved**
- How search results are **ranked** and **scored**

Think of it as a contract that ensures your documents are organized, searchable, and retrievable in the way you need.

---

## Vespa Schema vs. Other Databases

If you're familiar with other databases, here's how Vespa schemas compare:

### Comparison Table

| Concept | Vespa | PostgreSQL | MongoDB | Elasticsearch |
|---------|-------|------------|---------|---------------|
| **Schema Definition** | `.sd` file (schema definition) | `CREATE TABLE` statement | Implicit (from documents) or JSON Schema | Index mapping (JSON) |
| **Document/Record** | Document | Row | Document | Document |
| **Field/Column** | Field | Column | Field | Field |
| **Data Types** | `string`, `int`, `float`, `array`, `tensor` | `VARCHAR`, `INTEGER`, `FLOAT`, `ARRAY` | `String`, `Int32`, `Double`, `Array` | `text`, `keyword`, `integer`, `float`, `nested` |
| **Indexing** | `index` directive | `CREATE INDEX` | Index on field | Field mapping with `index: true` |
| **Full-Text Search** | `index` on string field | `tsvector` + `GIN` index | Text index | `text` type with analyzer |
| **Vector Search** | `tensor` with `index` | `vector` type + `ivfflat`/`hnsw` | Vector search (Atlas) | `dense_vector` type |
| **In-Memory Storage** | `attribute` directive | Materialized views / temp tables | In-memory storage (limited) | `doc_values: true` |
| **Filtering/Sorting** | `attribute` fields | Indexed columns | Indexed fields | `keyword` type or `doc_values` |
| **Ranking** | Rank profiles | `ORDER BY` + custom functions | `$sort` + `$textScore` | `_score` + custom scoring |
| **Retrievable Fields** | `summary` directive | `SELECT` columns | Projection in query | `_source` fields |
| **Schema Evolution** | Modify `.sd` file, deploy | `ALTER TABLE` | Schema-less (flexible) | Reindex or update mapping |

### Detailed Comparisons

#### **1. Schema Definition**

**Vespa:**
```vespa
schema product {
    document product {
        field title type string {
            indexing: summary | index
        }
    }
}
```

**PostgreSQL:**
```sql
CREATE TABLE product (
    title VARCHAR(255)
);
CREATE INDEX idx_title ON product USING gin(to_tsvector('english', title));
```

**MongoDB:**
```javascript
// Schema is implicit, but you can define validation:
db.createCollection("product", {
    validator: {
        $jsonSchema: {
            properties: {
                title: { type: "string" }
            }
        }
    }
});
db.product.createIndex({ title: "text" });
```

**Elasticsearch:**
```json
{
    "mappings": {
        "properties": {
            "title": {
                "type": "text",
                "index": true
            }
        }
    }
}
```

#### **2. Indexing Directives**

**Vespa:**
- `index` = Creates search index
- `attribute` = In-memory storage for filtering
- `summary` = Makes field retrievable

**PostgreSQL:**
- `CREATE INDEX` = Creates index
- No direct equivalent to `attribute` (uses indexes)
- `SELECT` = Retrieves fields

**MongoDB:**
- `createIndex()` = Creates index
- No direct equivalent to `attribute` (uses indexes)
- Projection in query = Retrieves fields

**Elasticsearch:**
- `index: true` = Creates search index
- `doc_values: true` = Similar to `attribute` (for sorting/aggregations)
- `_source` = Retrieves fields (stored by default)

#### **3. Vector Search**

**Vespa:**
```vespa
field embedding type tensor<float>(x[384]) {
    indexing: attribute | index
}
// Built-in vector search with HNSW index
```

**PostgreSQL (pgvector extension):**
```sql
CREATE TABLE product (
    embedding vector(384)
);
CREATE INDEX ON product USING hnsw (embedding vector_cosine_ops);
```

**MongoDB (Atlas Vector Search):**
```javascript
// Requires Atlas Vector Search index
db.product.createSearchIndex({
    "definition": {
        "fields": [{
            "type": "vector",
            "path": "embedding",
            "numDimensions": 384
        }]
    }
});
```

**Elasticsearch:**
```json
{
    "mappings": {
        "properties": {
            "embedding": {
                "type": "dense_vector",
                "dims": 384,
                "index": true,
                "similarity": "cosine"
            }
        }
    }
}
```

#### **4. Ranking/Scoring**

**Vespa:**
```vespa
rank-profile default {
    first-phase {
        expression: 0.3 * bm25(title) + 0.7 * closeness(embedding)
    }
}
```

**PostgreSQL:**
```sql
SELECT *, 
    (0.3 * ts_rank(to_tsvector('english', title), query) + 
     0.7 * (1 - (embedding <=> query_vector))) as score
FROM product
ORDER BY score DESC;
```

**MongoDB:**
```javascript
db.product.aggregate([
    { $match: { $text: { $search: "query" } } },
    { $addFields: { 
        score: { 
            $add: [
                { $multiply: [0.3, { $meta: "textScore" }] },
                { $multiply: [0.7, { $vectorSearch: { ... } }] }
            ]
        }
    }},
    { $sort: { score: -1 } }
]);
```

**Elasticsearch:**
```json
{
    "query": {
        "script_score": {
            "query": { "match": { "title": "query" } },
            "script": {
                "source": "0.3 * _score + 0.7 * cosineSimilarity(params.query_vector, 'embedding')",
                "params": { "query_vector": [...] }
            }
        }
    }
}
```

### Key Differences

1. **Unified Configuration**: Vespa combines schema, indexing, and ranking in one `.sd` file, while others require separate commands/configurations.

2. **Built-in Vector Search**: Vespa has native tensor/vector support with HNSW indexing built-in, while others require extensions (PostgreSQL) or specific features (MongoDB Atlas, Elasticsearch).

3. **Rank Profiles**: Vespa allows multiple rank profiles (scoring strategies) per schema, making it easy to A/B test different ranking approaches.

4. **Synthetic Fields**: Vespa can compute fields on-the-fly (like embeddings) during indexing, which is more complex in other databases.

5. **Real-time Updates**: Vespa is optimized for real-time serving and updates, similar to Elasticsearch but with better consistency guarantees.

6. **Schema Flexibility**: 
   - **Vespa**: Structured schema with flexibility for computed fields
   - **PostgreSQL**: Strict schema, requires ALTER TABLE for changes
   - **MongoDB**: Schema-less by default, very flexible
   - **Elasticsearch**: Flexible mapping, but changes can be complex

### When to Use Vespa vs. Others

**Use Vespa when:**
- You need **hybrid search** (text + vector) out of the box
- You need **real-time serving** with low latency
- You want **unified configuration** for schema, indexing, and ranking
- You need **multiple ranking strategies** for A/B testing
- You're building **recommendation systems** or **search applications**

**Use PostgreSQL when:**
- You need **ACID transactions** and relational data
- You have **complex joins** and relational queries
- You need **mature ecosystem** and tooling

**Use MongoDB when:**
- You need **flexible schema** and document structure
- You have **hierarchical/nested data**
- You prefer **JavaScript/JSON** native format

**Use Elasticsearch when:**
- You need **log analytics** and time-series data
- You need **distributed search** across large clusters
- You're already using the **ELK stack**

---

## Key Components for Beginners

### 1. Document Type
The document type defines the structure of your documents - it's like a class definition in programming.

```vespa
schema mySchema {
    document myDocument {
        // fields go here
    }
}
```

### 2. Fields
Fields are the attributes/properties of your documents. Each field has:
- **Type**: string, int, float, array, tensor, etc.
- **Indexing directives**: How the field should be processed

**Common Field Types:**
- `string` - Text data
- `int` - Integer numbers
- `float` - Decimal numbers
- `array<string>` - Lists of strings
- `tensor<float>(x[128])` - Vector embeddings (for AI/ML)

### 3. Indexing Directives (CRITICAL FOR BEGINNERS!)

Indexing directives control how fields are processed. You combine them with the pipe (`|`) character:

#### **`summary`** - Makes field retrievable
- Field is included in query responses
- Use when you need to display the field in results
- **Example**: `indexing: summary`

#### **`index`** - Creates search index
- For strings: Creates full-text search index
- For tensors: Creates HNSW vector index (requires `attribute`)
- Enables searching within this field
- **Example**: `indexing: index`

#### **`attribute`** - In-memory storage
- Stores field in fast in-memory column store
- Enables: filtering, sorting, grouping, aggregation
- Required for structured queries
- **Example**: `indexing: attribute`

#### **`attribute: fast-search`** - Enhanced filtering
- Creates index over attribute for faster filtering
- Use for frequently filtered fields
- **Example**: `indexing: attribute | attribute: fast-search`

#### **Common Combinations:**
```vespa
// Searchable and retrievable text field
field title type string {
    indexing: summary | index
}

// Searchable, retrievable, and filterable field
field category type string {
    indexing: summary | index | attribute
}

// Fast filtering field (not searchable)
field price type float {
    indexing: attribute | attribute: fast-search
}
```

---

## Complete Schema Example

```vespa
schema product {
    document product {
        // Text fields - searchable and retrievable
        field title type string {
            indexing: summary | index
        }
        
        field description type string {
            indexing: summary | index
        }
        
        // Structured field - filterable and sortable
        field price type float {
            indexing: attribute | attribute: fast-search
        }
        
        // Array field - for tags/categories
        field tags type array<string> {
            indexing: summary | index
        }
        
        // Vector embedding for semantic search
        field embedding type tensor<float>(x[384]) {
            indexing: attribute | index
        }
    }
    
    // Rank profile - how results are scored
    rank-profile default {
        first-phase {
            expression: nativeRank(title, description)
        }
    }
    
    // Hybrid ranking combining text and vector search
    rank-profile hybrid {
        first-phase {
            expression {
                0.3 * bm25(title) +
                0.3 * bm25(description) +
                0.4 * closeness(embedding)
            }
        }
    }
}
```

---

## Synthetic Fields (Advanced but Important!)

Synthetic fields are computed from other fields using processing pipelines. Common use case: generating embeddings.

```vespa
schema mySchema {
    document mySchema {
        field text type string {
            indexing: summary | index
        }
    }
    
    // Synthetic field: generates embedding from text field
    field embedding type tensor<float>(x[384]) {
        indexing: input text | embed | attribute | index
    }
}
```

**Pipeline explanation:**
- `input text` - Takes input from `text` field
- `embed` - Generates embedding vector
- `attribute` - Stores in memory
- `index` - Creates vector index for similarity search

---

## Rank Profiles

Rank profiles define how documents are scored and ranked. You can have multiple profiles for different use cases.

### Simple Rank Profile
```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description)
    }
}
```

### Hybrid Rank Profile (Text + Vector)
```vespa
rank-profile hybrid {
    first-phase {
        expression {
            0.3 * bm25(title) +           // Text relevance
            0.3 * bm25(description) +     // Text relevance
            0.4 * closeness(embedding)    // Vector similarity
        }
    }
}
```

**Ranking Functions:**
- `nativeRank(field)` - Vespa's default text ranking
- `bm25(field)` - BM25 text relevance score
- `closeness(tensor)` - Vector similarity (cosine distance)
- `attribute(field)` - Use attribute value directly

---

## Schema Evolution (IMPORTANT!)

When modifying schemas in production:

### ✅ Safe Changes
- **Adding new fields** - Existing documents will have empty/null values until updated
- **Adding new rank profiles** - No impact on existing data

### ⚠️ Changes That Trigger Reindexing
- **Changing field indexing** - May require background reindexing
- **Modifying field types** - Removes existing data and indexes
- **Removing fields** - Deletes data and indexes permanently

### 💡 Best Practice
Instead of changing a field, consider:
1. Add a new field with the desired configuration
2. Populate the new field with data
3. Update queries to use the new field
4. Remove the old field once migration is complete

---

## Field Sets

Field sets group fields together for efficient retrieval:

```vespa
fieldset default {
    fields: title, description, tags
}
```

This allows querying multiple fields at once efficiently.

---

## Key Takeaways for Newbies

1. **Always use `summary`** for fields you want to display in results
2. **Use `index`** for fields you want to search within
3. **Use `attribute`** for fields you want to filter, sort, or aggregate
4. **Combine directives** with `|` when you need multiple behaviors
5. **Plan schema changes carefully** - some changes are destructive
6. **Test rank profiles** to ensure relevant results
7. **Use synthetic fields** for computed values like embeddings

---

## Common Patterns

### E-commerce Product Schema
```vespa
schema product {
    document product {
        field title type string { indexing: summary | index }
        field description type string { indexing: summary | index }
        field price type float { indexing: attribute | attribute: fast-search }
        field category type string { indexing: summary | index | attribute }
        field in_stock type bool { indexing: attribute }
        field rating type float { indexing: attribute }
        field embedding type tensor<float>(x[384]) { indexing: attribute | index }
    }
}
```

### Search-Only Field (not retrievable)
```vespa
field searchable_text type string {
    indexing: index  // No summary = not returned in results
}
```

### Filter-Only Field (not searchable)
```vespa
field status type string {
    indexing: attribute  // Can filter, but not full-text search
}
```

---

## Resources

- Official Docs: https://docs.vespa.ai/en/schemas.html
- Sample Applications: https://github.com/vespa-engine/sample-apps
- Schema Reference: https://docs.vespa.ai/en/reference/schema-reference.html
