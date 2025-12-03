# SUMMARY OF THE YQL (VESPA QUERY LANGUAGE)
Refs: 
- https://docs.vespa.ai/en/query-language.html
- https://docs.vespa.ai/en/reference/querying/json-query-language.html
- https://docs.vespa.ai/en/reference/querying/simple-query-language.html

## Vespa Query Languages Overview

Vespa supports **three query languages** for different use cases:

1. **YQL (Vespa Query Language)** - Structured, SQL-like language (primary)
2. **JSON Query Language** - JSON-based queries for programmatic access
3. **Simple Query Language** - User-friendly, natural language queries

This guide covers all three, with emphasis on YQL as the primary language.

---

## What is YQL?

**YQL (Vespa Query Language)** is Vespa's SQL-like query language for searching and retrieving documents. It's how you:
- **Search** for documents (text, vector, structured)
- **Filter** by field values
- **Sort** results
- **Group** and **aggregate** data
- **Combine** multiple search types (hybrid search)

Think of it as Vespa's equivalent to:
- **PostgreSQL**: `SELECT ... FROM ... WHERE ...`
- **MongoDB**: `db.collection.find({ ... })`
- **Elasticsearch**: Query DSL (JSON queries)

---

## YQL vs. Other Query Languages

### Comparison Table

| Feature | Vespa YQL | PostgreSQL SQL | MongoDB | Elasticsearch |
|---------|-----------|----------------|---------|---------------|
| **Basic Query** | `SELECT * FROM product WHERE true` | `SELECT * FROM product WHERE true` | `db.product.find({})` | `GET /index/_search` |
| **Text Search** | `WHERE title CONTAINS "laptop"` | `WHERE title LIKE '%laptop%'` | `{title: {$regex: "laptop"}}` | `{"match": {"title": "laptop"}}` |
| **Filter** | `WHERE price > 100` | `WHERE price > 100` | `{price: {$gt: 100}}` | `{"range": {"price": {"gt": 100}}}` |
| **Sort** | `ORDER BY price DESC` | `ORDER BY price DESC` | `.sort({price: -1})` | `"sort": [{"price": "desc"}]` |
| **Vector Search** | `nearestNeighbor(embedding, query_vector)` | `ORDER BY embedding <=> vector` | `$vectorSearch` | `knn` query |
| **Aggregation** | `ALL(GROUP(category) EACH(OUTPUT(COUNT(*))))` | `GROUP BY category` | `$group` | `aggs` |
| **Pagination** | `LIMIT 10 OFFSET 20` | `LIMIT 10 OFFSET 20` | `.skip(20).limit(10)` | `from: 20, size: 10` |

### Key Differences

1. **Document Sources**: YQL uses `FROM sources *` or `FROM product` (document type)
2. **Text Search**: Uses `CONTAINS` for full-text search (not `LIKE`)
3. **Vector Search**: Built-in `nearestNeighbor()` function
4. **Hybrid Search**: Easy to combine text + vector in one query
5. **User Queries**: `userQuery()` function for natural language queries

---

## Choosing the Right Query Language

| Language | Best For | When to Use |
|----------|----------|-------------|
| **YQL** | Developers, complex queries | Structured queries, programmatic access, complex filtering |
| **JSON Query Language** | Applications, APIs | Building queries in code, POST requests, complex nested queries |
| **Simple Query Language** | End users, search boxes | User-facing search, natural language, simple queries |

**Recommendation for beginners:** Start with **YQL** - it's the most powerful and flexible. Use **JSON Query Language** when building applications. Use **Simple Query Language** for user-facing search interfaces.

---

## JSON Query Language

**JSON Query Language** allows you to structure queries as JSON objects. This is especially useful for:
- Building queries programmatically in code
- POST requests (no URL length limits)
- Complex nested query structures
- Integration with JSON-based systems

### Basic JSON Query Structure

```json
{
  "yql": "SELECT * FROM product WHERE title CONTAINS \"laptop\"",
  "hits": 10,
  "offset": 0,
  "ranking": {
    "profile": "default"
  }
}
```

### Using JSON Queries

#### With curl (POST)

```bash
curl -X POST 'http://localhost:8080/search/' \
  -H 'Content-Type: application/json' \
  -d '{
    "yql": "SELECT * FROM product WHERE title CONTAINS \"laptop\"",
    "hits": 10
  }'
```

#### With Python

```python
import requests

query = {
    "yql": "SELECT * FROM product WHERE title CONTAINS \"laptop\"",
    "hits": 10,
    "ranking": {
        "profile": "default"
    }
}

response = requests.post('http://localhost:8080/search/', json=query)
```

### JSON Query Parameters

**Common parameters:**

```json
{
  "yql": "SELECT * FROM product WHERE title CONTAINS \"laptop\"",
  "hits": 10,                    // Number of results
  "offset": 0,                   // Pagination offset
  "timeout": "5s",               // Query timeout
  "ranking": {                   // Ranking configuration
    "profile": "hybrid",
    "properties": {
      "textWeight": 0.6,
      "vectorWeight": 0.4
    }
  },
  "presentation": {              // Result formatting
    "format": "json",
    "summary": "default"
  }
}
```

### JSON Query Examples

#### Text Search

```json
{
  "yql": "SELECT * FROM product WHERE title CONTAINS \"gaming laptop\"",
  "hits": 20
}
```

#### Filtered Search

```json
{
  "yql": "SELECT * FROM product WHERE title CONTAINS \"laptop\" AND price < 1000",
  "hits": 10,
  "ranking": {
    "profile": "default"
  }
}
```

#### Vector Search

```json
{
  "yql": "SELECT * FROM product WHERE {targetHits: 10}nearestNeighbor(embedding, query_vector)",
  "input.query(query_vector)": [0.1, 0.2, 0.3, ...],
  "hits": 10
}
```

#### Hybrid Search

```json
{
  "yql": "SELECT * FROM product WHERE userQuery(title, description) AND {targetHits: 10}nearestNeighbor(embedding, query_vector)",
  "query": "gaming laptop",
  "input.query(query_vector)": [0.1, 0.2, 0.3, ...],
  "ranking": {
    "profile": "hybrid"
  },
  "hits": 10
}
```

#### Sorting

```json
{
  "yql": "SELECT * FROM product WHERE true ORDER BY price DESC",
  "hits": 20
}
```

#### Aggregation

```json
{
  "yql": "SELECT * FROM product WHERE true LIMIT 0 | ALL(GROUP(category) EACH(OUTPUT(COUNT(*))))"
}
```

### Advantages of JSON Query Language

1. **No URL Length Limits** - POST requests can be as large as needed
2. **Programmatic Construction** - Easy to build queries in code
3. **Nested Structures** - Better for complex queries
4. **Type Safety** - JSON structure is validated
5. **Integration** - Works seamlessly with JSON-based APIs

### When to Use JSON Query Language

**✅ Use JSON Query Language when:**
- Building queries in application code
- Need complex nested query structures
- Query strings would be too long for GET requests
- Integrating with JSON-based systems
- Need fine-grained control over query parameters

**❌ Avoid JSON Query Language when:**
- Simple one-off queries (use YQL with CLI)
- User-facing search (use Simple Query Language)
- Quick testing (use YQL with curl GET)

---

## Simple Query Language

**Simple Query Language** is a user-friendly, natural language query format designed for end users. It's perfect for search boxes and user-facing interfaces.

### Basic Syntax

Simple queries use a **heuristic, non-structured** approach:

```plaintext
keyword1 keyword2 -excludedKeyword
```

### Simple Query Examples

#### Basic Search

```plaintext
laptop
```

**Equivalent YQL:**
```yql
SELECT * FROM product WHERE userQuery()
```

#### Multiple Keywords

```plaintext
gaming laptop
```

**Searches for documents containing both "gaming" AND "laptop"**

#### Exclude Terms

```plaintext
laptop -gaming
```

**Searches for "laptop" but excludes "gaming"**

#### Field-Specific Search

```plaintext
title:laptop
```

**Searches only in the `title` field**

#### Multiple Fields

```plaintext
title:laptop description:gaming
```

**Searches "laptop" in title AND "gaming" in description**

#### Required Terms (+)

```plaintext
+laptop +gaming
```

**Both terms must be present**

#### Phrase Search

```plaintext
"gaming laptop"
```

**Searches for exact phrase "gaming laptop"**

#### Complex Query

```plaintext
title:laptop price:100-500 -gaming
```

**Searches:**
- "laptop" in title field
- Price between 100 and 500
- Excludes "gaming"

### Using Simple Query Language

#### With Vespa CLI

```bash
vespa query 'query=laptop gaming'
```

**Vespa automatically uses Simple Query Language when you provide a `query` parameter.**

#### With curl

```bash
curl 'http://localhost:8080/search/?query=laptop%20gaming'
```

#### With JSON Query

```json
{
  "query": "laptop gaming",
  "yql": "SELECT * FROM product WHERE userQuery()"
}
```

### Simple Query Operators

| Operator | Meaning | Example |
|---------|---------|---------|
| **Space** | AND (both terms) | `laptop gaming` |
| **`-`** | NOT (exclude) | `laptop -gaming` |
| **`+`** | MUST (required) | `+laptop +gaming` |
| **`field:`** | Field-specific | `title:laptop` |
| **`"phrase"`** | Exact phrase | `"gaming laptop"` |
| **`field:value1-value2`** | Range | `price:100-500` |

### Simple Query Language Features

1. **Heuristic Parsing** - Tries to interpret user intent even with imperfect syntax
2. **Field-Specific** - Can target specific fields with `field:value`
3. **Boolean Logic** - Supports AND, OR, NOT operations
4. **Phrase Matching** - Exact phrase search with quotes
5. **Range Queries** - Numeric ranges with `field:min-max`

### When to Use Simple Query Language

**✅ Use Simple Query Language when:**
- Building user-facing search interfaces
- Users need to type queries directly
- You want natural language input
- Simple search boxes
- End-user applications

**❌ Avoid Simple Query Language when:**
- Need complex structured queries
- Programmatic query construction
- Very specific filtering requirements
- Advanced aggregations

### Simple Query Language Examples

#### E-commerce Search

```plaintext
wireless headphones price:50-200 -bluetooth
```

**Finds:**
- Wireless headphones
- Price between $50-$200
- Excludes Bluetooth

#### Product Search

```plaintext
title:laptop +gaming price:1000-2000
```

**Finds:**
- Laptops in title
- Must contain "gaming"
- Price between $1000-$2000

#### User-Friendly Search

```plaintext
"gaming laptop" under 1500 dollars
```

**Heuristic parsing attempts to interpret:**
- Phrase "gaming laptop"
- Price constraint (< $1500)

---

## Basic Query Structure

### Minimal Query

```yql
SELECT * FROM product WHERE true
```

**Components:**
- `SELECT *` - Return all fields
- `FROM product` - Document type (schema name)
- `WHERE true` - No filtering (return all documents)

### Using Vespa CLI

```bash
vespa query 'yql=select * from product where true'
```

### Using curl

```bash
curl 'http://localhost:8080/search/?yql=select%20*%20from%20product%20where%20true'
```

**Response:**
```json
{
  "root": {
    "children": [
      {
        "id": "id:ecommerce:product::laptop-123",
        "relevance": 0.0,
        "fields": {
          "title": "Gaming Laptop",
          "price": 1299.99,
          "in_stock": true
        }
      }
    ]
  }
}
```

---

## Selecting Fields

### Select All Fields

```yql
SELECT * FROM product WHERE true
```

### Select Specific Fields

```yql
SELECT title, price, in_stock FROM product WHERE true
```

**Response:**
```json
{
  "root": {
    "children": [
      {
        "id": "id:ecommerce:product::laptop-123",
        "fields": {
          "title": "Gaming Laptop",
          "price": 1299.99,
          "in_stock": true
        }
      }
    ]
  }
}
```

### Select with Aliases

```yql
SELECT title AS product_title, price AS product_price FROM product WHERE true
```

---

## Filtering (WHERE Clause)

### Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal | `WHERE price = 100` |
| `!=` | Not equal | `WHERE price != 100` |
| `<` | Less than | `WHERE price < 100` |
| `>` | Greater than | `WHERE price > 100` |
| `<=` | Less than or equal | `WHERE price <= 100` |
| `>=` | Greater than or equal | `WHERE price >= 100` |

**Examples:**

```yql
-- Products with price exactly 100
SELECT * FROM product WHERE price = 100

-- Products cheaper than 100
SELECT * FROM product WHERE price < 100

-- Products between 50 and 200
SELECT * FROM product WHERE price >= 50 AND price <= 200
```

### Text Search (CONTAINS)

**Full-text search** in indexed string fields:

```yql
SELECT * FROM product WHERE title CONTAINS "laptop"
```

**Case-insensitive** by default (depends on schema configuration).

**Multiple words:**
```yql
SELECT * FROM product WHERE title CONTAINS "gaming laptop"
```

**Multiple fields:**
```yql
SELECT * FROM product WHERE title CONTAINS "laptop" OR description CONTAINS "laptop"
```

### IN Operator

**Match any value in a list:**

```yql
SELECT * FROM product WHERE category IN ("electronics", "computers", "gaming")
```

**Equivalent to:**
```yql
SELECT * FROM product WHERE category = "electronics" OR category = "computers" OR category = "gaming"
```

### LIKE Operator (Pattern Matching)

**Pattern matching** (similar to SQL LIKE):

```yql
SELECT * FROM product WHERE title LIKE "laptop%"
```

**Patterns:**
- `%` - Matches any sequence of characters
- `_` - Matches any single character

**Examples:**
```yql
-- Starts with "gaming"
WHERE title LIKE "gaming%"

-- Ends with "pro"
WHERE title LIKE "%pro"

-- Contains "laptop"
WHERE title LIKE "%laptop%"

-- Exactly 5 characters starting with "lap"
WHERE title LIKE "lap__"
```

### Boolean Logic

**Combine conditions with AND, OR, NOT:**

```yql
-- AND: Both conditions must be true
SELECT * FROM product 
WHERE title CONTAINS "laptop" AND price < 1000

-- OR: Either condition can be true
SELECT * FROM product 
WHERE category = "electronics" OR category = "computers"

-- NOT: Negate condition
SELECT * FROM product 
WHERE NOT in_stock = false

-- Complex combinations
SELECT * FROM product 
WHERE (title CONTAINS "laptop" OR title CONTAINS "computer") 
  AND price < 1500 
  AND in_stock = true
```

### NULL Checks

**Check for null/empty values:**

```yql
-- Field is null or empty
SELECT * FROM product WHERE description IS NULL

-- Field is not null
SELECT * FROM product WHERE description IS NOT NULL
```

---

## User Queries (Natural Language Search)

**`userQuery()`** function allows natural language queries:

```yql
SELECT * FROM product WHERE userQuery()
```

**Usage with Vespa CLI:**

```bash
vespa query 'yql=select * from product where userQuery()' 'query=gaming laptop'
```

**Usage with curl:**

```bash
curl 'http://localhost:8080/search/?yql=select%20*%20from%20product%20where%20userQuery()&query=gaming%20laptop'
```

**How it works:**
- Searches in fields configured in your rank profile
- Uses default fieldset if defined
- Applies ranking (BM25, nativeRank, etc.)

**Specify which fields to search:**

```yql
SELECT * FROM product WHERE userQuery(title, description)
```

**With query parameter:**
```bash
vespa query 'yql=select * from product where userQuery(title, description)' 'query=gaming laptop'
```

---

## Vector Search (Nearest Neighbor)

**Search using vector embeddings** for semantic similarity:

### Basic Vector Search

```yql
SELECT * FROM product 
WHERE {targetHits: 10}nearestNeighbor(embedding, query_vector)
```

**Parameters:**
- `targetHits: 10` - Number of results to return
- `embedding` - Field name (tensor type)
- `query_vector` - Query parameter name

**Using Vespa CLI:**

```bash
vespa query \
  'yql=select * from product where {targetHits: 10}nearestNeighbor(embedding, query_vector)' \
  'input.query(query_vector)=[0.1,0.2,0.3,...]'
```

**Using curl:**

```bash
curl -X POST 'http://localhost:8080/search/' \
  -H 'Content-Type: application/json' \
  -d '{
    "yql": "select * from product where {targetHits: 10}nearestNeighbor(embedding, query_vector)",
    "input.query(query_vector)": [0.1, 0.2, 0.3, ...]
  }'
```

### Vector Search with Filtering

**Combine vector search with filters:**

```yql
SELECT * FROM product 
WHERE {targetHits: 10}nearestNeighbor(embedding, query_vector)
  AND price < 1000
  AND in_stock = true
```

---

## Hybrid Search (Text + Vector)

**Combine text search and vector search** for best results:

```yql
SELECT * FROM product 
WHERE userQuery(title, description)
  AND {targetHits: 10}nearestNeighbor(embedding, query_vector)
```

**Ranking combines both:**
- Text relevance (BM25, nativeRank)
- Vector similarity (closeness)

**Example with rank profile:**

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

**Query with rank profile:**

```bash
vespa query \
  'yql=select * from product where userQuery(title) and {targetHits: 10}nearestNeighbor(embedding, query_vector)' \
  'query=gaming laptop' \
  'input.query(query_vector)=[0.1,0.2,...]' \
  'ranking=hybrid'
```

---

## Sorting (ORDER BY)

### Sort by Single Field

```yql
SELECT * FROM product WHERE true ORDER BY price ASC
```

**Sort directions:**
- `ASC` - Ascending (low to high)
- `DESC` - Descending (high to low)

**Examples:**

```yql
-- Sort by price (lowest first)
SELECT * FROM product WHERE true ORDER BY price ASC

-- Sort by price (highest first)
SELECT * FROM product WHERE true ORDER BY price DESC

-- Sort by title alphabetically
SELECT * FROM product WHERE true ORDER BY title ASC
```

### Sort by Multiple Fields

```yql
SELECT * FROM product 
WHERE true 
ORDER BY in_stock DESC, price ASC
```

**Sorts by:**
1. `in_stock` (descending) - In-stock items first
2. `price` (ascending) - Then by price (lowest first)

### Sort by Relevance

**Default sorting** is by relevance score (from rank profile):

```yql
SELECT * FROM product WHERE userQuery()
-- Automatically sorted by relevance (highest first)
```

**Explicit relevance sort:**

```yql
SELECT * FROM product WHERE userQuery() ORDER BY [relevance] DESC
```

---

## Pagination (LIMIT and OFFSET)

### Limit Results

```yql
SELECT * FROM product WHERE true LIMIT 10
```

**Returns first 10 documents.**

### Offset (Skip Results)

```yql
SELECT * FROM product WHERE true LIMIT 10 OFFSET 20
```

**Skips first 20, returns next 10** (documents 21-30).

**Common pagination pattern:**

```yql
-- Page 1 (results 1-10)
SELECT * FROM product WHERE true LIMIT 10 OFFSET 0

-- Page 2 (results 11-20)
SELECT * FROM product WHERE true LIMIT 10 OFFSET 10

-- Page 3 (results 21-30)
SELECT * FROM product WHERE true LIMIT 10 OFFSET 20
```

**Formula:**
```
OFFSET = (page_number - 1) * page_size
```

---

## Grouping and Aggregation

### COUNT

**Count total documents:**

```yql
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(OUTPUT(COUNT(*)))
```

**Count with filter:**

```yql
SELECT * FROM product WHERE price > 100 LIMIT 0 |
  ALL(OUTPUT(COUNT(*)))
```

### GROUP BY

**Group by field and count:**

```yql
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(GROUP(category) EACH(OUTPUT(COUNT(*))))
```

**Response:**
```json
{
  "root": {
    "children": [
      {
        "id": "group:category:electronics",
        "relevance": 0.0,
        "value": "electronics",
        "children": [
          {"fields": {"count()": 150}}
        ]
      },
      {
        "id": "group:category:computers",
        "relevance": 0.0,
        "value": "computers",
        "children": [
          {"fields": {"count()": 75}}
        ]
      }
    ]
  }
}
```

### SUM, AVG, MIN, MAX

**Aggregate functions:**

```yql
-- Sum of prices
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(OUTPUT(SUM(price)))

-- Average price
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(OUTPUT(AVG(price)))

-- Minimum price
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(OUTPUT(MIN(price)))

-- Maximum price
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(OUTPUT(MAX(price)))
```

### Group with Aggregations

**Group by category, calculate average price:**

```yql
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(GROUP(category) EACH(OUTPUT(AVG(price), COUNT(*))))
```

**Response:**
```json
{
  "root": {
    "children": [
      {
        "id": "group:category:electronics",
        "value": "electronics",
        "children": [
          {
            "fields": {
              "avg(price)": 299.99,
              "count()": 150
            }
          }
        ]
      }
    ]
  }
}
```

---

## Common Query Patterns

### Pattern 1: Simple Text Search

```yql
SELECT title, price FROM product WHERE title CONTAINS "laptop"
```

### Pattern 2: Filtered Search

```yql
SELECT * FROM product 
WHERE title CONTAINS "gaming" 
  AND price < 1500 
  AND in_stock = true
```

### Pattern 3: Sorted Results

```yql
SELECT * FROM product 
WHERE category = "electronics" 
ORDER BY price ASC 
LIMIT 20
```

### Pattern 4: User Query with Filters

```yql
SELECT * FROM product 
WHERE userQuery(title, description)
  AND price BETWEEN 50 AND 500
  AND in_stock = true
ORDER BY [relevance] DESC
LIMIT 10
```

### Pattern 5: Vector Search

```yql
SELECT * FROM product 
WHERE {targetHits: 10}nearestNeighbor(embedding, query_vector)
  AND price < 1000
```

### Pattern 6: Hybrid Search

```yql
SELECT * FROM product 
WHERE userQuery(title, description)
  AND {targetHits: 10}nearestNeighbor(embedding, query_vector)
ORDER BY [relevance] DESC
LIMIT 10
```

### Pattern 7: Aggregation

```yql
SELECT * FROM product WHERE true LIMIT 0 |
  ALL(GROUP(category) EACH(OUTPUT(COUNT(*), AVG(price), MIN(price), MAX(price))))
```

---

## Query Parameters

### Using Query Parameters

**Instead of hardcoding values, use parameters:**

```yql
SELECT * FROM product WHERE title CONTAINS @query AND price < @max_price
```

**Pass parameters:**

```bash
vespa query \
  'yql=select * from product where title contains @query and price < @max_price' \
  'query=laptop' \
  'max_price=1000'
```

### Common Parameters

| Parameter | Usage | Example |
|-----------|-------|---------|
| `query` | User search query | `query=gaming laptop` |
| `input.query(query_vector)` | Vector embedding | `input.query(query_vector)=[0.1,0.2,...]` |
| `ranking` | Rank profile name | `ranking=hybrid` |
| `hits` | Number of results | `hits=20` |
| `offset` | Skip results | `offset=10` |
| `timeout` | Query timeout | `timeout=5s` |

---

## Using Vespa CLI vs. curl

### Vespa CLI (Recommended for Beginners)

**Simple queries:**
```bash
vespa query 'yql=select * from product where true'
```

**With user query:**
```bash
vespa query 'yql=select * from product where userQuery()' 'query=laptop'
```

**With parameters:**
```bash
vespa query \
  'yql=select * from product where title contains @query' \
  'query=laptop'
```

**Advantages:**
- Simpler syntax
- Automatic URL encoding
- Better error messages
- Interactive mode

### curl (For Applications)

**GET request:**
```bash
curl 'http://localhost:8080/search/?yql=select%20*%20from%20product%20where%20true'
```

**POST request (for complex queries):**
```bash
curl -X POST 'http://localhost:8080/search/' \
  -H 'Content-Type: application/json' \
  -d '{
    "yql": "select * from product where title contains @query",
    "query": "laptop"
  }'
```

**With vector:**
```bash
curl -X POST 'http://localhost:8080/search/' \
  -H 'Content-Type: application/json' \
  -d '{
    "yql": "select * from product where {targetHits: 10}nearestNeighbor(embedding, query_vector)",
    "input.query(query_vector)": [0.1, 0.2, 0.3, ...]
  }'
```

---

## Error Handling

### Common Errors

#### 1. Field Not Found

**Error:** `Field 'nonexistent' not found`

**Cause:** Field doesn't exist in schema

**Fix:** Check schema field names

#### 2. Type Mismatch

**Error:** `Cannot compare string and number`

**Cause:** Comparing incompatible types

**Fix:** Use correct types:
```yql
-- Wrong
WHERE price = "100"

-- Correct
WHERE price = 100
```

#### 3. Index Not Found

**Error:** `No index for field 'title'`

**Cause:** Field not indexed (missing `index` directive)

**Fix:** Add `index` to field in schema:
```vespa
field title type string {
    indexing: summary | index
}
```

#### 4. Vector Dimension Mismatch

**Error:** `Tensor dimension mismatch`

**Cause:** Query vector size doesn't match field dimension

**Fix:** Ensure vector dimensions match:
```yql
-- Field: tensor<float>(x[384])
-- Query vector must have 384 elements
```

---

## Performance Tips

### 1. Use Indexed Fields for Search

**✅ Good:**
```yql
-- Field has 'index' directive
WHERE title CONTAINS "laptop"
```

**❌ Avoid:**
```yql
-- Field only has 'attribute' (not indexed)
WHERE title = "laptop"  -- Still works, but slower for text
```

### 2. Filter Before Search

**✅ Good:**
```yql
-- Filter first (fast), then search
WHERE in_stock = true AND title CONTAINS "laptop"
```

**❌ Avoid:**
```yql
-- Search first (slower), then filter
WHERE title CONTAINS "laptop" AND in_stock = true
```

### 3. Use LIMIT

**Always specify LIMIT** to avoid returning too many results:

```yql
SELECT * FROM product WHERE true LIMIT 10
```

### 4. Use Appropriate Rank Profiles

**Use rank profiles** optimized for your use case:

```bash
vespa query 'yql=...' 'ranking=hybrid'
```

### 5. Monitor Query Performance

**Check query metrics:**
```bash
curl http://localhost:8080/metrics/v1/values
```

**Look for:**
- Query latency
- Query rate
- Error rate

---

## Troubleshooting

### No Results Returned

**Problem:** Query returns empty results

**Solutions:**
1. **Check if documents exist:**
   ```bash
   vespa query 'yql=select * from product where true'
   ```

2. **Verify field names:**
   - Check schema field names
   - Ensure field names match exactly (case-sensitive)

3. **Check indexing:**
   - Field must have `index` for `CONTAINS` search
   - Field must have `attribute` for filtering

4. **Test with simpler query:**
   ```yql
   SELECT * FROM product WHERE true
   ```

### Wrong Results

**Problem:** Query returns unexpected results

**Solutions:**
1. **Check WHERE conditions:**
   - Verify logic (AND vs OR)
   - Check operator types (= vs CONTAINS)

2. **Check field types:**
   - String vs number comparisons
   - Array field handling

3. **Use explicit sorting:**
   ```yql
   ORDER BY price ASC
   ```

### Slow Queries

**Problem:** Queries take too long

**Solutions:**
1. **Add indexes:**
   - Ensure searched fields have `index`
   - Ensure filtered fields have `attribute`

2. **Add filters:**
   - Filter before searching
   - Use `attribute: fast-search` for frequent filters

3. **Limit results:**
   ```yql
   LIMIT 10
   ```

4. **Use rank profiles:**
   - Optimized ranking is faster

---

## Quick Reference

### Basic Query Structure

```yql
SELECT [fields] FROM [document-type] 
WHERE [conditions] 
ORDER BY [field] [ASC|DESC] 
LIMIT [number] OFFSET [number]
```

### Common WHERE Conditions

| Condition | Example |
|-----------|---------|
| **Equals** | `WHERE price = 100` |
| **Not equals** | `WHERE price != 100` |
| **Less than** | `WHERE price < 100` |
| **Greater than** | `WHERE price > 100` |
| **Contains** | `WHERE title CONTAINS "laptop"` |
| **IN** | `WHERE category IN ("electronics", "computers")` |
| **LIKE** | `WHERE title LIKE "laptop%"` |
| **AND** | `WHERE price > 100 AND price < 500` |
| **OR** | `WHERE category = "electronics" OR category = "computers"` |
| **NOT** | `WHERE NOT in_stock = false` |

### Text Search

```yql
-- Simple contains
WHERE title CONTAINS "laptop"

-- User query
WHERE userQuery()

-- User query with fields
WHERE userQuery(title, description)
```

### Vector Search

```yql
WHERE {targetHits: 10}nearestNeighbor(embedding, query_vector)
```

### Sorting

```yql
ORDER BY price ASC
ORDER BY price DESC
ORDER BY in_stock DESC, price ASC
```

### Pagination

```yql
LIMIT 10
LIMIT 10 OFFSET 20
```

### Aggregation

```yql
-- Count
ALL(OUTPUT(COUNT(*)))

-- Group and count
ALL(GROUP(category) EACH(OUTPUT(COUNT(*))))

-- Sum, avg, min, max
ALL(OUTPUT(SUM(price)))
ALL(OUTPUT(AVG(price)))
ALL(OUTPUT(MIN(price)))
ALL(OUTPUT(MAX(price)))
```

---

## Key Takeaways for Newbies

1. **Vespa has 3 query languages** - YQL (primary), JSON Query Language, Simple Query Language
2. **YQL is SQL-like** - If you know SQL, YQL will feel familiar
3. **Use CONTAINS for text search** - Not LIKE (though LIKE also works)
4. **userQuery() for natural language** - Simplifies text search
5. **nearestNeighbor() for vectors** - Built-in vector search
6. **Combine text + vector** - Hybrid search is easy in YQL
7. **Use LIMIT** - Always limit results for performance
8. **Filter before search** - More efficient query execution
9. **Check field indexing** - Fields need `index` or `attribute` to be searchable/filterable
10. **JSON Query Language for apps** - Use when building queries programmatically
11. **Simple Query Language for users** - Use for user-facing search interfaces

---

## Resources

- **YQL Official Docs**: https://docs.vespa.ai/en/query-language.html
- **YQL Reference**: https://docs.vespa.ai/en/reference/query-language-reference.html
- **JSON Query Language**: https://docs.vespa.ai/en/reference/querying/json-query-language.html
- **Simple Query Language**: https://docs.vespa.ai/en/reference/querying/simple-query-language.html
- **Query API**: https://docs.vespa.ai/en/query-api.html
- **Ranking**: https://docs.vespa.ai/en/ranking.html
- **Vector Search**: https://docs.vespa.ai/en/nearest-neighbor-search.html

---

## Next Steps

After mastering query languages:

1. **Learn Ranking** - How to customize result scoring
2. **Learn Aggregations** - Advanced grouping and statistics
3. **Learn Query Profiles** - Reusable query templates
4. **Explore Advanced Features** - Federation, streaming search, etc.
5. **Practice JSON Queries** - Build queries programmatically
6. **Implement Simple Queries** - Add user-facing search to your app

For more examples, check out:
- `simple_ecommerce_app/README.md` - Basic query examples
- `ecommerce_app/README.md` - Advanced query patterns
- Sample applications: https://github.com/vespa-engine/sample-apps

---

## Quick Comparison: When to Use Which Language

### Use YQL when:
- ✅ Learning Vespa (start here!)
- ✅ Complex structured queries
- ✅ Need precise control
- ✅ Writing queries manually
- ✅ Testing and debugging

### Use JSON Query Language when:
- ✅ Building queries in code
- ✅ POST requests (no URL limits)
- ✅ Complex nested structures
- ✅ Application integration
- ✅ Dynamic query construction

### Use Simple Query Language when:
- ✅ User-facing search boxes
- ✅ Natural language input
- ✅ End-user applications
- ✅ Simple search interfaces
- ✅ Quick user queries
