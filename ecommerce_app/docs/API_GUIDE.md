# SUMMARY OF THE DOCUMENT API GUIDE
Ref: https://docs.vespa.ai/en/writing/document-v1-api-guide.html

## What is the Document API?

The **Vespa Document API** (`/document/v1/`) is a RESTful HTTP interface for managing documents in Vespa. It's how you:
- **Create** documents (PUT)
- **Read** documents (GET)
- **Update** documents (POST)
- **Delete** documents (DELETE)
- **Visit** documents (scan through all documents)

Think of it as Vespa's equivalent to:
- **PostgreSQL**: `INSERT`, `SELECT`, `UPDATE`, `DELETE` SQL commands
- **MongoDB**: `insertOne()`, `findOne()`, `updateOne()`, `deleteOne()` methods
- **Elasticsearch**: Document API (`PUT`, `GET`, `POST`, `DELETE` endpoints)

---

## Document API vs. Other Databases

### Comparison Table

| Operation | Vespa | PostgreSQL | MongoDB | Elasticsearch |
|-----------|-------|------------|---------|---------------|
| **Create** | `PUT /document/v1/...` | `INSERT INTO ...` | `db.collection.insertOne()` | `PUT /index/_doc/id` |
| **Read** | `GET /document/v1/...` | `SELECT * FROM ...` | `db.collection.findOne()` | `GET /index/_doc/id` |
| **Update** | `POST /document/v1/...` | `UPDATE ... SET ...` | `db.collection.updateOne()` | `POST /index/_doc/id/_update` |
| **Delete** | `DELETE /document/v1/...` | `DELETE FROM ...` | `db.collection.deleteOne()` | `DELETE /index/_doc/id` |
| **Batch** | JSONL feed file | `INSERT ... VALUES (...), (...)` | `db.collection.insertMany()` | `_bulk` API |
| **Visit All** | `GET /document/v1/?cluster=...` | `SELECT * FROM table` | `db.collection.find()` | `_search` with scroll |

### Key Differences

1. **Document ID Format**: Vespa uses structured IDs: `id:namespace:document-type::unique-id`
2. **Upsert by Default**: PUT operations create if missing, update if exists (upsert)
3. **Partial Updates**: POST allows updating only specific fields without replacing entire document
4. **Conditional Operations**: Supports conditional writes (create-if-not-exists, update-if-exists)

---

## Understanding Document IDs

### Document ID Format

Vespa document IDs follow this structure:

```
id:<namespace>:<document-type>::<unique-id>
```

**Example:**
```
id:ecommerce:product::laptop-123
```

**Components:**
- `id:` - Prefix (always present)
- `ecommerce` - **Namespace** (like a database name)
- `product` - **Document type** (matches your schema name)
- `::` - Separator
- `laptop-123` - **Unique identifier** (your choice)

### Why This Matters

- **Namespace** groups related documents (like a database)
- **Document type** must match your schema name (e.g., `product` matches `schema product`)
- **Unique ID** can be any string (product SKU, UUID, slug, etc.)

**Common Patterns:**
```bash
# Using product SKU
id:ecommerce:product::SKU-12345

# Using UUID
id:ecommerce:product::550e8400-e29b-41d4-a716-446655440000

# Using slug
id:ecommerce:product::wireless-headphones-pro
```

---

## Basic Operations

### 1. Create a Document (PUT)

**Creates a new document or replaces an existing one** (upsert behavior).

#### Using Vespa CLI (Recommended for Beginners)

```bash
vespa document put id:ecommerce:product::laptop-123 product.json
```

Where `product.json` contains:
```json
{
  "fields": {
    "title": "Gaming Laptop",
    "price": 1299.99,
    "in_stock": true
  }
}
```

#### Using curl

```bash
curl -X PUT \
  http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123 \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "title": "Gaming Laptop",
      "price": 1299.99,
      "in_stock": true
    }
  }'
```

**Response:**
```json
{
  "id": "id:ecommerce:product::laptop-123",
  "pathId": "/document/v1/ecommerce/product/docid/laptop-123"
}
```

**Key Points:**
- PUT is **idempotent** - running it multiple times with same data is safe
- If document exists, it's **replaced** (not merged)
- All fields in `fields` object must match your schema

---

### 2. Read a Document (GET)

**Retrieves a document by its ID.**

#### Using Vespa CLI

```bash
vespa document get id:ecommerce:product::laptop-123
```

#### Using curl

```bash
curl http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123
```

**Response:**
```json
{
  "pathId": "/document/v1/ecommerce/product/docid/laptop-123",
  "id": "id:ecommerce:product::laptop-123",
  "fields": {
    "title": "Gaming Laptop",
    "price": 1299.99,
    "in_stock": true
  }
}
```

**If Document Not Found:**
```json
{
  "pathId": "/document/v1/ecommerce/product/docid/non-existent",
  "id": "id:ecommerce:product::non-existent"
}
```

**Note**: Use `curl -v` to see HTTP status codes (404 for not found).

---

### 3. Update a Document (POST)

**Partially updates an existing document** - only specified fields are changed.

#### Using Vespa CLI

```bash
vespa document update id:ecommerce:product::laptop-123 -d '{
  "fields": {
    "price": { "assign": 1199.99 },
    "in_stock": { "assign": false }
  }
}'
```

#### Using curl

```bash
curl -X POST \
  http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123 \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "price": { "assign": 1199.99 },
      "in_stock": { "assign": false }
    }
  }'
```

**Update Operations:**
- `"assign": value` - Set field to new value
- `"increment": number` - Add to numeric field
- `"add": value` - Add to array field
- `"remove": value` - Remove from array field

**Example - Increment Price:**
```json
{
  "fields": {
    "price": { "increment": 50.00 }
  }
}
```

**Example - Add to Array:**
```json
{
  "fields": {
    "tags": { "add": "on-sale" }
  }
}
```

**Key Points:**
- POST only updates specified fields
- Other fields remain unchanged
- Document must exist (returns 404 if not found)

---

### 4. Delete a Document (DELETE)

**Removes a document from Vespa.**

#### Using Vespa CLI

```bash
vespa document remove id:ecommerce:product::laptop-123
```

#### Using curl

```bash
curl -X DELETE \
  http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123
```

**Response:**
```json
{
  "id": "id:ecommerce:product::laptop-123"
}
```

**Key Points:**
- DELETE is **idempotent** - deleting non-existent document returns success
- Document is immediately removed from index
- Cannot be undone (unless you have backups)

---

## Batch Operations (Feeding Multiple Documents)

### Using JSONL Format

The most efficient way to feed many documents is using **JSONL** (JSON Lines) format:

**File: `products.jsonl`**
```jsonl
{"put": "id:ecommerce:product::1", "fields": {"title": "Laptop", "price": 999.99}}
{"put": "id:ecommerce:product::2", "fields": {"title": "Mouse", "price": 29.99}}
{"put": "id:ecommerce:product::3", "fields": {"title": "Keyboard", "price": 79.99}}
```

**Feed the file:**
```bash
vespa feed products.jsonl
```

**What happens:**
- Each line is processed as a separate document operation
- Operations are batched for efficiency
- Progress is shown in real-time

### Batch Operations in JSONL

You can mix operations in JSONL:

```jsonl
{"put": "id:ecommerce:product::1", "fields": {"title": "New Product", "price": 100}}
{"update": "id:ecommerce:product::1", "fields": {"price": {"assign": 90}}}
{"delete": "id:ecommerce:product::2"}
```

**Operations:**
- `"put"` - Create or replace document
- `"update"` - Partial update (same as POST)
- `"delete"` - Remove document

---

## Advanced Operations

### Conditional Writes

#### Create If Not Exists

Only create document if it doesn't already exist:

```bash
curl -X PUT \
  "http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123?create=true" \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "title": "Gaming Laptop",
      "price": 1299.99
    }
  }'
```

**Behavior:**
- If document exists → Returns error (409 Conflict)
- If document doesn't exist → Creates it

#### Update If Exists

Only update if document already exists:

```bash
curl -X POST \
  "http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123?condition=true" \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "price": { "assign": 1199.99 }
    }
  }'
```

**Behavior:**
- If document exists → Updates it
- If document doesn't exist → Returns error (404 Not Found)

### Visiting Documents (Scanning All Documents)

**Visit all documents** in a schema (useful for data export, migration, etc.):

```bash
curl 'http://localhost:8080/document/v1/?cluster=content&wantedDocumentCount=10'
```

**Parameters:**
- `cluster=content` - Content cluster name (from `services.xml`)
- `wantedDocumentCount=10` - How many documents to return per request
- `timeout=60s` - Request timeout

**Response:**
```json
{
  "documents": [
    {
      "id": "id:ecommerce:product::laptop-123",
      "fields": { "title": "Gaming Laptop", "price": 1299.99 }
    },
    {
      "id": "id:ecommerce:product::mouse-456",
      "fields": { "title": "Wireless Mouse", "price": 29.99 }
    }
  ],
  "continuation": "eyJkb2NpZCI6Im1vdXNlLTQ1NiJ9"
}
```

**Pagination:**
- Use `continuation` token to get next batch
- Keep requesting until no `continuation` is returned

**Using Vespa CLI:**
```bash
vespa visit
```

---

## Document JSON Format

### Complete Document Structure

```json
{
  "put": "id:ecommerce:product::laptop-123",
  "fields": {
    "title": "Gaming Laptop",
    "description": "High-performance gaming laptop",
    "price": 1299.99,
    "in_stock": true,
    "tags": ["gaming", "laptop", "gpu"],
    "rating": 4.5,
    "reviews_count": 127
  },
  "condition": "title == \"Old Title\"",
  "create": false
}
```

**Fields:**
- `put` / `update` / `delete` - Operation type
- `fields` - Document data (must match schema)
- `condition` - Optional condition for conditional writes
- `create` - Optional flag for create-if-not-exists

### Field Types in JSON

**String:**
```json
"title": "Gaming Laptop"
```

**Number:**
```json
"price": 1299.99,
"quantity": 42
```

**Boolean:**
```json
"in_stock": true
```

**Array:**
```json
"tags": ["gaming", "laptop", "gpu"]
```

**Tensor (Vector):**
```json
"embedding": {
  "type": "tensor<float>(x[384])",
  "values": [0.1, 0.2, 0.3, ...]
}
```

---

## Common Patterns

### Pattern 1: Create or Update (Upsert)

**Use PUT** - it automatically creates if missing, updates if exists:

```bash
vespa document put id:ecommerce:product::laptop-123 product.json
```

This is the **most common pattern** - simple and safe.

### Pattern 2: Update Only If Exists

**Use POST with condition:**

```bash
curl -X POST \
  "http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123?condition=true" \
  -H 'Content-Type: application/json' \
  -d '{"fields": {"price": {"assign": 1199.99}}}'
```

### Pattern 3: Create Only If Not Exists

**Use PUT with create flag:**

```bash
curl -X PUT \
  "http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123?create=true" \
  -H 'Content-Type: application/json' \
  -d '{"fields": {"title": "New Product", "price": 100}}'
```

### Pattern 4: Batch Feed from CSV

1. Convert CSV to JSONL using a script
2. Feed JSONL file:

```bash
python convert_csv_to_jsonl.py products.csv > products.jsonl
vespa feed products.jsonl
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | What to Do |
|------|---------|------------|
| **200** | Success | Operation completed successfully |
| **201** | Created | Document was created |
| **400** | Bad Request | Check document format, field types |
| **404** | Not Found | Document doesn't exist (for GET/UPDATE) |
| **409** | Conflict | Document already exists (with `create=true`) |
| **413** | Content Too Large | Document exceeds size limit (10 MB recommended) |
| **429** | Too Many Requests | Backpressure - slow down and retry |

### Common Errors

#### 1. Field Type Mismatch

**Error:** `400 Bad Request`

**Cause:** Field type in JSON doesn't match schema

**Example:**
```json
// Schema expects: field price type float
// You send:
"price": "1299.99"  // ❌ String instead of number
```

**Fix:** Use correct type:
```json
"price": 1299.99  // ✅ Number
```

#### 2. Missing Required Field

**Error:** `400 Bad Request`

**Cause:** Schema requires field but it's missing

**Fix:** Include all required fields in document

#### 3. Document Not Found

**Error:** `404 Not Found`

**Cause:** Trying to GET or UPDATE non-existent document

**Fix:** 
- Check document ID is correct
- Use PUT instead of POST if you want to create

#### 4. Backpressure (429)

**Error:** `429 Too Many Requests`

**Cause:** Feeding too fast, system is overloaded

**Fix:**
- Implement retry with exponential backoff
- Reduce feed rate
- Use Vespa feed client (handles retries automatically)

---

## Performance & Best Practices

### 1. Use Batch Feeding (JSONL)

**✅ Good:**
```bash
vespa feed products.jsonl  # Processes many documents efficiently
```

**❌ Avoid:**
```bash
# Don't do this for many documents:
for id in $(cat ids.txt); do
  vespa document put $id product.json
done
```

### 2. Keep Documents Under 10 MB

**Why:** Larger documents:
- Take longer to process
- Use more memory
- May hit request size limits

**If you have large content:**
- Split into chunks
- Store large text in separate fields
- Use compression if needed

### 3. Handle Backpressure (429)

**Implement retry logic:**

```python
import time
import requests

def put_document_with_retry(url, data, max_retries=3):
    for attempt in range(max_retries):
        response = requests.put(url, json=data)
        if response.status_code == 200:
            return response
        elif response.status_code == 429:
            # Backpressure - wait and retry
            wait_time = 2 ** attempt  # Exponential backoff
            time.sleep(wait_time)
        else:
            raise Exception(f"Error: {response.status_code}")
    raise Exception("Max retries exceeded")
```

**Or use Vespa feed client** - it handles this automatically.

### 4. Use Appropriate Operations

- **PUT** - When you want upsert (create or replace)
- **POST** - When you want partial update only
- **DELETE** - When removing documents
- **Batch JSONL** - When feeding many documents

### 5. Monitor Feed Rate

**Check metrics:**
```bash
# View feed metrics
curl http://localhost:8080/metrics/v1/values
```

**Look for:**
- Feed rate (documents/second)
- Error rate
- Queue depth

---

## Troubleshooting

### Document Not Found in Queries

**Problem:** Document exists but doesn't appear in search results

**Solutions:**
1. **Check document ID format:**
   ```bash
   vespa document get id:ecommerce:product::laptop-123
   ```

2. **Verify document is indexed:**
   ```bash
   vespa query 'yql=select * from product where true'
   ```

3. **Check schema matches:**
   - Document type in ID must match schema name
   - Fields must match schema definition

### Documents Not Updating

**Problem:** Updates don't seem to take effect

**Solutions:**
1. **Use POST for partial updates:**
   ```bash
   vespa document update id:... -d '{"fields": {...}}'
   ```

2. **Check field names match schema**

3. **Verify update succeeded:**
   ```bash
   vespa document get id:...
   ```

### Feed Failing

**Problem:** `vespa feed` returns errors

**Solutions:**
1. **Check JSONL format:**
   - Each line must be valid JSON
   - No trailing commas
   - Proper escaping

2. **Validate against schema:**
   ```bash
   # Check schema
   cat app/schemas/product.sd
   
   # Compare with JSONL fields
   head -1 products.jsonl | jq .
   ```

3. **Check document IDs:**
   - Must follow format: `id:namespace:type::id`
   - Namespace and type must match your app

### Getting Empty Results from Visit

**Problem:** Visit returns no documents

**Solutions:**
1. **Increase `wantedDocumentCount`:**
   ```bash
   curl '...?wantedDocumentCount=100&timeout=60s'
   ```

2. **Check cluster name:**
   - Must match content cluster in `services.xml`

3. **Wait for indexing:**
   - Documents may still be indexing
   - Try again after a few seconds

---

## Comparison: Vespa CLI vs. curl

### When to Use Vespa CLI

**✅ Use CLI when:**
- Learning Vespa (simpler commands)
- Interactive development
- Single document operations
- You want automatic error handling

**Examples:**
```bash
vespa document put id:... file.json
vespa document get id:...
vespa document update id:... -d '{...}'
vespa document remove id:...
vespa feed products.jsonl
```

### When to Use curl/HTTP

**✅ Use HTTP when:**
- Building applications (programmatic access)
- Need conditional operations
- Custom error handling
- Integration with other tools

**Examples:**
```bash
curl -X PUT http://.../document/v1/.../docid/... -d '{...}'
curl -X POST "http://...?condition=true" -d '{...}'
```

---

## Quick Reference

### Document ID Format
```
id:<namespace>:<document-type>::<unique-id>
```

### Basic Operations

| Operation | CLI | HTTP |
|-----------|-----|------|
| **Create/Replace** | `vespa document put id:... file.json` | `PUT /document/v1/.../docid/...` |
| **Read** | `vespa document get id:...` | `GET /document/v1/.../docid/...` |
| **Update** | `vespa document update id:... -d '{...}'` | `POST /document/v1/.../docid/...` |
| **Delete** | `vespa document remove id:...` | `DELETE /document/v1/.../docid/...` |
| **Batch Feed** | `vespa feed file.jsonl` | Use feed client or batch API |

### Common curl Examples

```bash
# Create document
curl -X PUT http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123 \
  -H 'Content-Type: application/json' \
  -d '{"fields": {"title": "Laptop", "price": 999.99}}'

# Get document
curl http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123

# Update document
curl -X POST http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123 \
  -H 'Content-Type: application/json' \
  -d '{"fields": {"price": {"assign": 899.99}}}'

# Delete document
curl -X DELETE http://localhost:8080/document/v1/ecommerce/product/docid/laptop-123
```

---

## Key Takeaways for Newbies

1. **Document IDs are structured** - Follow the format: `id:namespace:type::id`
2. **PUT = Upsert** - Creates if missing, replaces if exists (most common)
3. **POST = Partial Update** - Only updates specified fields
4. **Use JSONL for batch** - Most efficient way to feed many documents
5. **Handle 429 errors** - Implement retry logic or use feed client
6. **Keep documents < 10 MB** - For optimal performance
7. **Use Vespa CLI for learning** - Simpler than curl
8. **Check HTTP status codes** - They tell you what went wrong

---

## Resources

- **Official Docs**: https://docs.vespa.ai/en/writing/document-v1-api-guide.html
- **Document JSON Format**: https://docs.vespa.ai/en/reference/document-json-format.html
- **Vespa CLI**: https://docs.vespa.ai/en/vespa-cli.html
- **HTTP Best Practices**: https://docs.vespa.ai/en/http-best-practices.html
- **Feed Client**: https://github.com/vespa-engine/vespa/tree/master/vespa-feed-client

---

## Next Steps

After mastering the Document API:

1. **Learn Querying** - How to search and retrieve documents
2. **Learn Ranking** - How to score and sort results
3. **Learn Aggregations** - How to group and aggregate data
4. **Explore Advanced Features** - Conditional writes, visiting, etc.

For more examples, check out:
- `simple_ecommerce_app/README.md` - Basic CRUD examples
- `ecommerce_app/README.md` - Advanced patterns
- Sample applications: https://github.com/vespa-engine/sample-apps
