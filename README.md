# Vespa Workshop 101

This directory contains the Vespa Fundamentals Course (101) with 5 progressive chapters covering basic to advanced Vespa concepts.

## Project Content

### Chapter 1: Simple E-commerce App
**Location:** [`simple_ecommerce_app/`](simple_ecommerce_app/)  
**📄 [README.md](simple_ecommerce_app/README.md)**

**Concepts:**
- Basic document schema definition
- Simple field types (string, float)
- Indexing and attribute configuration

**Key Files:**
- `app/schemas/product.sd` - Minimal product schema
- `sample-product.json` - Example document
- `dataset/multiple-products.jsonl` - Sample data

---

### Chapter 2: Full E-commerce Application
**Location:** [`ecommerce_app/`](ecommerce_app/)  
**📄 [README.md](ecommerce_app/README.md)**

**Concepts:**
- Complex document schemas
- Multiple field types and indexing strategies
- CRUD operations (PUT, GET, DELETE)
- Data ingestion from CSV via Logstash
- HTTP API usage

**Key Files:**
- `app/schemas/product.sd` - Complete product schema
- `dataset/myntra_products_catalog.csv` - Full product catalog
- `dataset/products.jsonl` - Pre-converted JSONL format
- `example.http` - HTTP query examples
- `answers.http` - Solution queries

---

### Chapter 3: Semantic Search
**Location:** [`semantic_ecommerce_app/`](semantic_ecommerce_app/)  
**📄 [README.md](semantic_ecommerce_app/README.md)**

**Concepts:**
- Text embedding generation
- Vector similarity search with nearestNeighbor
- HNSW indexing for fast ANN search
- Distance metrics (angular, euclidean)
- Query embeddings

**Key Files:**
- `app/schemas/product.sd` - Schema with embedding fields
- `dataset/products.jsonl` - Products with embeddings
- `queries.http` - Semantic search examples
- `query-template.http` - Query templates

---

### Chapter 4: Hybrid Search
**Location:** [`hybrid_ecommerce_app/`](hybrid_ecommerce_app/)  
**📄 [README.md](hybrid_ecommerce_app/README.md)**

**Concepts:**
- Combining text search (BM25) with semantic search
- Hybrid retrieval strategies
- Rank fusion techniques (RRF - Reciprocal Rank Fusion)
- Query operators: `or`, `rank()`
- Query-time embedding generation with embedder components

**Key Files:**
- `app/schemas/product.sd` - Hybrid ranking profiles
- `dataset/vespa_feed-1K_no_embeddings.jsonl` - Data without embeddings
- `queries.http` - Hybrid query examples

---

### Chapter 4a: Hybrid Search with RAG
**Location:** [`hybrid_ecommerce_app_rag/`](hybrid_ecommerce_app_rag/)  
**📄 [README.md](hybrid_ecommerce_app_rag/README.md)**

**Concepts:**
- Retrieval: Execute hybrid search (BM25 + semantic) to find relevant products
- Context Building: Format retrieved products into prompt context
- LLM Generation: Send context + query to LLM
- Response: Stream or return generated answer

**Key Files:**
- `ragapp/schemas/product.sd` - Hybrid ranking profiles
- `ragapp/services.xml` - services and RAG search chain configuration

---

### Chapter 5: Sales Data Analytics
**Location:** [`sales_data_app/`](sales_data_app/)  
**📄 [README.md](sales_data_app/README.md)**

**Concepts:**
- Time-series data modeling
- Aggregation and grouping
- Analytics queries
- Different document types (purchase schema)
- Nested grouping and statistics

**Key Files:**
- `app/schemas/purchase.sd` - Purchase transaction schema
- `dataset/sales-data.csv` - Raw sales data
- `dataset/sales-data.jsonl` - Converted JSONL
- `queries.cli` - CLI query examples
- `queries.http` - HTTP query examples

---

## Course Progression

1. **Chapter 1** → Start with basic schema concepts
2. **Chapter 2** → Learn CRUD operations and full application setup
3. **Chapter 3** → Add semantic search capabilities
4. **Chapter 4** → Combine text and semantic search with hybrid ranking
5. **Chapter 4a** → Extend the hybrid search application with RAG (Retrieval-Augmented Generation)
6. **Chapter 5** → Explore analytics and time-series data

## Additional Resources

- [Vespa Documentation](https://docs.vespa.ai/)
- [Vespa Sample Applications](https://github.com/vespa-engine/sample-apps)
- [Vespa University Repository](https://github.com/vespaai/university)
