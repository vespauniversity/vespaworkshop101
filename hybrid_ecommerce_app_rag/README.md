# Hybrid E-commerce App – Vespa 101 Chapter 4

This project is **Chapter 4** in the Vespa 101 series.  
Chapter 3 (`semantic_ecommerce_app`) introduced semantic search with pre-computed embeddings.  
This chapter adds **hybrid search** combining text (BM25) and semantic (ANN) search using **Reciprocal Rank Fusion (RRF)** ranking, and introduces **query-time embedding generation** using embedder components.

The goal here is to learn how to:
- Configure **embedder components** for query-time embedding generation
- Combine **text search (BM25)** and **semantic search (ANN)** in a single query
- Use **Reciprocal Rank Fusion (RRF)** ranking to merge results from multiple retrieval methods
- Build **hybrid search queries** that leverage both lexical and semantic signals

---

## Learning Objectives (Chapter 4)

After completing this chapter you should be able to:

- **Configure embedder components** for on-the-fly embedding generation
- **Define embedding fields** that are generated from text fields during indexing
- **Build hybrid queries** that combine text and semantic search
- **Implement RRF ranking** to fuse results from multiple retrieval methods
- **Understand the trade-offs** between query-time and pre-computed embeddings
- **Optimize hybrid search** for better relevance and performance

**Prerequisites**: Complete Chapter 3 (`semantic_ecommerce_app`) first. If you haven't, review:
- `semantic_ecommerce_app/README.md` for semantic search and ANN basics
- `ecommerce_app/README.md` for text search and schema fundamentals
- `simple_ecommerce_app/README.md` for fundamental concepts

---

## Project Structure

From the `hybrid_ecommerce_app` root:

```text
hybrid_ecommerce_app/
├── app/
│   ├── .vespaignore                # Files to ignore during deployment
│   ├── schemas/
│   │   └── product.sd              # Product schema with embedding field (TODO)
│   ├── services.xml                # Vespa services config (embedder TODO)
│   └── validation-overrides.xml    # Validation overrides (used sparingly)
├── dataset/
│   ├── vespa_feed-1K_no_embeddings.jsonl  # Products without embeddings
│   └── remove_embeddings.py        # Script to remove embeddings from data
├── queries.http                    # Example hybrid search queries
└── README.md                       # This file
```

You will mainly work with:
- `app/schemas/product.sd` - Schema with embedding field and RRF ranking (TODOs to complete)
- `app/services.xml` - Services config with embedder component (TODO)
- `dataset/vespa_feed-1K_no_embeddings.jsonl` - Data without pre-computed embeddings
- `queries.http` - Example queries for hybrid search

---

## Key Concepts

### What is Hybrid Search?

**Hybrid search** combines multiple retrieval methods to improve search quality:
- **Text search (BM25)**: Finds documents matching exact keywords
- **Semantic search (ANN)**: Finds documents by meaning using vector embeddings
- **Combined**: Leverages strengths of both approaches

**Example**:
- Query: "blue jeans"
- **BM25** finds: "blue jeans", "blue denim jeans"
- **Semantic** finds: "navy trousers", "denim pants", "indigo pants"
- **Hybrid** combines both for better coverage

### Query-Time Embedding Generation

Unlike Chapter 3 (pre-computed embeddings), this chapter uses **embedder components** to generate embeddings **on-the-fly** from query text:

- **Pre-computed** (Chapter 3): Embeddings stored in documents, faster queries
- **Query-time** (Chapter 4): Embeddings generated from query text, more flexible

**Benefits of query-time generation**:
- No need to pre-compute embeddings for all documents
- Can generate embeddings from any query text
- Easier to update embedding models
- Supports dynamic queries

### Reciprocal Rank Fusion (RRF)

**RRF** is a ranking technique that combines results from multiple retrieval methods:

```
RRF Score = Σ (1 / (k + rank_i))
```

Where:
- `k` = constant (typically 60)
- `rank_i` = rank of document in result set `i`

**For detailed information** about RRF, see:
- **Vespa Documentation**: [Phased Ranking - reciprocal_rank()](https://docs.vespa.ai/en/phased-ranking.html) - Covers the `reciprocal_rank()` function implementation
- **Academic Paper**: [Reciprocal Rank Fusion (RRF)](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf) - Original paper by Cormack et al. (2009) describing the RRF algorithm

**How it works**:
1. Run text search → get ranked results
2. Run semantic search → get ranked results
3. Combine using RRF → final ranked results

**Benefits**:
- Combines strengths of both methods
- Handles different result sets gracefully
- No need to normalize scores
- Works well when methods disagree

### Embedder Components

Vespa supports embedder components that generate embeddings from text:
- **HuggingFace embedder**: Uses HuggingFace models (e.g., sentence-transformers)
- **ONNX embedder**: Uses ONNX models
- **Custom embedders**: Build your own

**Configuration** (in `services.xml`):
```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model model-id="e5-small-v2"/>
</component>
```

**Usage** (in schema):
```javascript
field embedding type tensor<float>(x[384]) {
  indexing {
    (input title || "") . " " . (input description || "") | embed e5 | attribute | index
  }
}
```

**For detailed documentation**, see: [Embedding](https://docs.vespa.ai/en/embedding.html)

---

## Overview

This section introduces the fundamental concepts of embedders, embeddings, hybrid search with Reciprocal Rank Fusion (RRF), and phased ranking in Vespa. If you're new to these concepts, we recommend reading the detailed explanations in [Embedding](https://docs.vespa.ai/en/rag/embedding.html) and [Phased ranking](https://docs.vespa.ai/en/ranking/phased-ranking.html) for a deeper understanding.

### Embedders Overview

![embedders](img/embedders.png)

**What you're seeing:** This diagram illustrates what **embedder components** are in Vespa. Embedders are services that convert text into dense vector representations (embeddings) using machine learning models. They can be configured in `services.xml` and used during both document indexing and query processing.

**Key Concepts:**
- **Embedder Component**: A service configured in `services.xml` that generates embeddings from text
- **HuggingFace Embedder**: Most commonly used embedder type, supporting models from HuggingFace Hub
- **Model Hub**: Pre-configured models available in Vespa Cloud (e.g., `e5-small-v2`, `e5-base-v2`)
- **Index-time Embedding**: Embeddings generated during document indexing and stored in the index
- **Query-time Embedding**: Embeddings generated on-the-fly from query text using the `embed()` function

**Notes:** Think of it like this:
- **Embedder** = A service that converts text to numbers (embeddings)
- **Model** = The AI model that does the conversion (e.g., E5-small-v2)
- **Index-time** = Generate embeddings when documents are indexed (faster queries)
- **Query-time** = Generate embeddings when queries are made (more flexible)

**Example Embedder Configuration (`services.xml`):**
```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model model-id="e5-small-v2"/>
</component>
```

This configures an embedder named `e5` using the E5-small-v2 model from Vespa Model Hub, which generates 384-dimensional embeddings.

**Learn More:**
- Official Docs: [Embedding](https://docs.vespa.ai/en/embedding.html)
- Model Hub: [Vespa Cloud Model Hub](https://cloud.vespa.ai/en/model-hub)

### Embedding Overview

![embedding](img/embedding.png)

**What you're seeing:** This diagram illustrates how **embeddings** are generated and used in Vespa. Embeddings are dense vector representations of text that capture semantic meaning, enabling semantic search through approximate nearest neighbor (ANN) search.

**Key Concepts:**
- **Embedding Field**: A tensor field that stores vector embeddings (e.g., `tensor<float>(x[384])`)
- **Indexing Pipeline**: The process of generating embeddings from document fields during indexing
- **HNSW Index**: Hierarchical Navigable Small World graph index for efficient ANN search
- **Distance Metric**: How similarity is measured (e.g., `angular`, `euclidean`, `innerproduct`)
- **Query-time Embedding**: Using `embed()` function to generate embeddings from query text

**Notes:** Think of it like this:
- **Embedding** = A list of numbers representing text meaning (e.g., `[0.23, -0.45, 0.12, ...]`)
- **Indexing Pipeline** = `input title | embed e5 | attribute | index` - converts text to embedding and stores it
- **ANN Search** = Finding documents with similar embeddings (semantic similarity)
- **Distance Metric** = How to measure "closeness" between embeddings

**Example Embedding Field Definition:**
```vespa
field embedding type tensor<float>(x[384]) {
  indexing {
    (input title || "") . " " . (input description || "") | embed e5 | attribute | index
  }
  attribute {
    distance-metric: angular
  }
  index {
    hnsw {
      max-links-per-node: 16
      neighbors-to-explore-at-insert: 200
    }
  }
}
```

This field generates embeddings by concatenating title and description, then using the `e5` embedder component. The embedding is stored as an attribute with angular distance metric and indexed with HNSW for fast ANN search.

**Learn More:**
- Official Docs: [Embedding](https://docs.vespa.ai/en/embedding.html)
- Official Docs: [Nearest Neighbor Search](https://docs.vespa.ai/en/nearest-neighbor-search.html)

### Hybrid Search with Reciprocal Rank Fusion (RRF) Overview

![hybrid_search_with_rrf](img/RRF.png)

**What you're seeing:** This diagram illustrates how **hybrid search with Reciprocal Rank Fusion (RRF)** combines multiple retrieval methods to improve search quality. RRF merges results from text search (BM25) and semantic search (ANN) by converting ranks to reciprocal ranks and summing them.

**Key Concepts:**
- **Hybrid Search**: Combining multiple retrieval methods (text + semantic) in a single query
- **Reciprocal Rank Fusion (RRF)**: A ranking technique that combines ranked lists by converting ranks to reciprocal ranks
- **Reciprocal Rank**: `1.0 / (k + rank)` - converts rank position to a score (lower rank = higher score)
- **Global-Phase Ranking**: Final ranking phase that runs after merging results from all **content nodes**
- **Rank Normalization**: RRF automatically handles different score scales from different methods

**Notes:** Think of it like this:
- **Hybrid Search** = Using both keyword matching (BM25) and semantic understanding (ANN) together
- **RRF** = A way to combine rankings that focuses on rank position rather than absolute scores
- **Reciprocal Rank** = A document at rank 1 gets score 1/(60+1) = 0.0164, rank 2 gets 1/(60+2) = 0.0161
- **Global-Phase** = Final reranking step that combines signals from multiple methods

**Example RRF Rank Profile:**
```vespa
rank-profile rrf inherits use_closeness {
  function best_bm25() {
    expression: max(bm25(title), bm25(description))
  }
  function ann_score() {
    expression: closeness(field, embedding)
  }
  global-phase {
    rerank-count: 200
    expression: reciprocal_rank(ann_score()) + reciprocal_rank(best_bm25())
  }
}
```

This rank profile combines semantic search (closeness) with text search (BM25) using RRF. The global-phase reranks the top 200 results by summing reciprocal ranks from both methods.

**What it does:**
- Documents that rank well in both BM25 and semantic search get higher final scores
- Automatically normalizes different score scales from different methods
- Focuses on rank position rather than absolute scores, making it robust to score variations

**Learn More:**
- Official Docs: [Phased Ranking](https://docs.vespa.ai/en/phased-ranking.html)
- Academic Paper: [Reciprocal Rank Fusion](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)

### Phased Ranking Overview

![phased_ranking](img/phased_ranking.png)

**What you're seeing:** This diagram illustrates how **phased ranking** works in Vespa. Phased ranking optimizes search performance by using multiple ranking phases with different computational costs - fast ranking on all documents, then expensive ranking on top candidates.

**Key Concepts:**
- **First-Phase Ranking**: Fast ranking that runs on all matching documents (must be efficient)
- **Second-Phase Ranking**: More expensive ranking on top-K candidates from first phase
- **Global-Phase Ranking**: Final ranking across all content nodes after merging results
- **Rerank-Count**: Number of top candidates to rerank in second/global phase (e.g., 100, 200)
- **Performance Optimization**: Use fast functions in first phase, expensive functions in later phases

**Notes:** Think of it like this:
- **First-Phase** = Quick initial scoring of all matches (like a first-round interview)
- **Second-Phase** = Detailed evaluation of top candidates (like a final interview)
- **Global-Phase** = Final ranking after merging results from all nodes (like a final decision)
- **Rerank-Count** = How many candidates to evaluate in detail (balance between quality and speed)

**Example Two-Phase Ranking:**
```vespa
rank-profile two_phase {
  first-phase {
    expression: bm25(title) + bm25(description)
  }
  second-phase {
    rerank-count: 100
    expression: lightgbm("model.json")
  }
}
```

This rank profile uses fast BM25 in the first phase to score all matching documents, then uses an expensive LightGBM model on the top 100 candidates in the second phase.

**What it does:**
- First phase quickly filters down to top candidates using fast functions (BM25, nativeRank, closeness)
- Second phase applies expensive ranking (ML models, complex computations) only on top candidates
- Global phase handles cross-hit normalization and combining signals from multiple sources
- Optimizes for both quality and performance by limiting expensive operations

**Learn More:**
- Official Docs: [Phased Ranking](https://docs.vespa.ai/en/phased-ranking.html)
- Official Docs: [Ranking Expressions](https://docs.vespa.ai/en/reference/ranking/ranking-expressions.html)
- Official Docs: [Rank Features](https://docs.vespa.ai/en/reference/ranking/rank-features.html)


## Step 1 – Review the Schema

Open:
- `docs/product-original.sd`
- `docs/product-alternative.sd`
- `app/schemas/product.sd`

These schemas extend Chapter 3's schema but has **TODOs** for you to complete:

### Current State

The schema has:
- Text fields (`title`, `description`) with BM25 indexing
- Attribute fields (`category`, `price`, `average_rating`)
- A `use_closeness` rank profile for semantic search
- **TODO**: Define the embedding field (generated from text fields)
- **TODO**: Define the RRF rank profile for hybrid search

### TODO 1: Define Embedding Field

You need to add an embedding field that is **generated from text fields** during indexing:

```javascript
field embedding type tensor<float>(x[384]) {
  indexing {
    (input title || "") . " " . (input description || "") | embed e5 | attribute | index
  }
  attribute {
    distance-metric: angular
  }
  index {
    hnsw {
      max-links-per-node: 16
      neighbors-to-explore-at-insert: 200
    }
  }
}
```

**Key points**:
- `embed e5` - Uses the embedder component named "e5" (defined in `services.xml`)
- `input title` and `input description` - Generates embedding from both the `title` and `description` fields
- `. " " .` - Concatenates the fields with a space separator
- `|| ""` - Fallback to empty string if title or description is missing
- `attribute | index` - Stores as attribute and indexes with HNSW

### TODO 2: Define RRF Rank Profile

You need to implement the RRF rank profile:

```javascript
rank-profile rrf inherits use_closeness {
  function best_bm25() {
    expression: max(bm25(title), bm25(description))
  }
  function ann_score() {
    expression: closeness(field, embedding)
  }
  global-phase {
    rerank-count: 200
    expression: reciprocal_rank(ann_score()) + reciprocal_rank(best_bm25())
  }
}
```

**Key points**:
- `inherits use_closeness` - Reuses the closeness function
- `best_bm25()` - Gets the best BM25 score from title or description
- `ann_score()` - Returns the semantic similarity score using `closeness()` function, measuring how similar the query embedding is to the document embedding (ANN = Approximate Nearest Neighbor search)
- `closeness(field, embedding)` - Built-in Vespa function that computes the similarity between query and document embeddings based on the distance metric (e.g., angular distance). Higher values indicate more similar embeddings. Used for semantic/vector search.
- `global-phase` - Reranks top 200 results
- `reciprocal_rank()` - Converts scores to reciprocal ranks for RRF

### About `reciprocal_rank()` Function

The `reciprocal_rank()` function is a **built-in Vespa function** that implements Reciprocal Rank Fusion (RRF) normalization. It's specifically designed for combining results from multiple ranking methods.

**How it works**:
1. **Ranks documents** by the input expression (e.g., `closeness()` or `best_bm25()`)
   - Highest score → rank 1
   - Second highest → rank 2
   - And so on...
2. **Converts rank to reciprocal rank** using the formula: `1.0 / (k + rank)`
   - Where `k` is a constant (default: 60.0)
   - Lower rank number = higher reciprocal rank value
3. **Returns the reciprocal rank** value for each document

**Formula**:
```
reciprocal_rank(expression, k)
output = 1.0 / (k + rank)
```

**Example**:
- Document A: rank 1 in BM25, rank 3 in ANN
- Document B: rank 2 in BM25, rank 1 in ANN
- With k=60:
  - A: `1/(60+1) + 1/(60+3) = 0.0164 + 0.0159 = 0.0323`
  - B: `1/(60+2) + 1/(60+1) = 0.0161 + 0.0164 = 0.0325`
- B wins (higher combined RRF score)

**Why use `reciprocal_rank()`?**
- **Normalizes different score scales** - BM25 and closeness scores are on different scales
- **Focuses on rank order** - Emphasizes position rather than absolute score values
- **Handles rank positions correctly** - Uses actual rank positions, not score approximations
- **Built-in optimization** - Efficiently implemented by Vespa

**Parameters**:
- First argument: The ranking expression to normalize (e.g., `closeness(field, embedding)`, `best_bm25()`)
- Second argument (optional): The `k` constant (default: 60.0)
  - Lower k = rank matters more (more emphasis on top results)
  - Higher k = rank matters less (more uniform distribution)

**Documentation**: For detailed information, see the [Phased Ranking documentation](https://docs.vespa.ai/en/phased-ranking.html) which covers `reciprocal_rank()` and [Rank Feature Reference](https://docs.vespa.ai/en/reference/ranking/rank-features.html) which covers `closeness(dimension,name)` and `bm25(field)`.

**For detailed schema configuration**, see the schema file comments and Vespa documentation.

---

## Step 2 – Configure the Embedder Component

Open:
- `docs/services-original.xml`
- `docs/services-alternative.xml`
- `app/services.xml`

You need to add an embedder component configuration.

### TODO: Add HuggingFace Embedder

Add the embedder component inside the `<container>` section:

```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model model-id="e5-small-v2"/>
</component>
```

**Key points**:
- `id="e5"` - Component name (referenced in schema as `embed e5`)
- `type="hugging-face-embedder"` - Uses HuggingFace embedder
- `model-id` - HuggingFace model identifier (384 dimensions for e5-small-v2)

**Alternative models**:
- `e5-small-v2` - 384 dimensions
- `e5-base-v2` - 768 dimensions
- `e5-large-v2` - 1024 dimensions
- `minilm-l6-v2` - 384 dimensions

**For detailed embedder configuration**, see: [Huggingface Embedder](https://docs.vespa.ai/en/rag/embedding.html#huggingface-embedder)

---

## Step 3 – Deploy the Application

From the `hybrid_ecommerce_app` root:

> **Assumption**: You already configured **target** and **application name** in previous chapters  
> (for example `vespa config set target cloud`, and `vespa config set application <tenant>.<app>[.<instance>]`).

If you **skipped previous chapters**, do that first using `ecommerce_app/README.md` (Prerequisites + Setup).

Then deploy this Chapter 4 app:

```bash
cd hybrid_ecommerce_app/app

# Verify your application configuration
vespa config get target        # Should show: cloud

# Set the application target if it is not cloud
# $ vespa config set target cloud

vespa config get application   # Should show: tenant.app.instance

# Set the application name if it is not already set
# $ vespa config set application my-tenant.ecommerce-app

# Login if needed
vespa auth login

# Create certificates if needed
vespa auth cert

# generate/copy the cert from .vespa dirs to this application if needed
# vespa auth cert add -f

# Deploy the application
vespa deploy --wait 900

# Check the status
vespa status
```

Wait for deployment to complete successfully.  
You should see output indicating the application is **ready**.

**Note**: The embedder component will download the model on first use, which may take a few minutes.

**More details:** 
- [Vespa cli](https://docs.vespa.ai/en/clients/vespa-cli.html#deployment)

---

## Step 4 – Delete Existing Documents (If Any)

> **Important**: If you have existing documents from previous chapters, delete them first to avoid conflicts or setup the new application.

### Option 1: Using Vespa Cloud Console

1. Go to your application in [Vespa Cloud](https://console.vespa.ai/)
2. Navigate to the **Metrics** section
3. Find the **Documents** count
4. Click **"(delete)"** to remove all documents

**Note**: Deleting documents may take a while. Give it half a minute to complete before feeding data in the next step.

### Option 2: Using Document API

You can also use the Document v1 API to delete documents programmatically:

```bash
# Delete all documents (example - adjust document IDs to match your data)
vespa document remove id:ecommerce:product::1
vespa document remove id:ecommerce:product::2
```

### Option 3: Query and Delete

```bash
# First, query to see what documents exist
vespa query 'yql=select * from product where true'

# Then delete specific documents by ID
vespa document remove <document-id>
```

### Option 4: Bulk Delete Script

```bash
# Using a loop to delete all document IDs
# This script queries all documents, extracts their IDs, and deletes them using jq
vespa query 'yql=select * from product where true' 'hits=1000' | \
  jq -r '.root.children[].id' | \
  while read doc_id; do
    echo "Deleting document: $doc_id"
    vespa document remove "$doc_id"
  done
```

**Note**: 
- Adjust `hits=1000` if you have more documents (or remove limit to get all)
- The script processes documents in batches - if you have many documents, you may need to run it multiple times
- For very large datasets, consider using the Vespa Cloud Console delete option instead

---

## Step 5 – Feed the Sample Data

The dataset contains products **without pre-computed embeddings**. Embeddings will be generated **during indexing** using the embedder component.

**File**: `dataset/vespa_feed-1K_no_embeddings.jsonl`

Each line is a JSON document with text fields (`title`, `description`) but **no embedding field**.

### Feed the Data

```bash
# From app directory
vespa feed --progress 3 ../dataset/vespa_feed-1K_no_embeddings.jsonl
```

**What this does**:
- Sends each JSONL line as a **put document** request to Vespa
- The `embedding` field is **generated automatically** from the `title` and `description` fields using the embedder
- The embedding is indexed using **HNSW** for fast ANN search
- Documents are validated against the schema

**Note**: 
- Embedding generation happens **during indexing**, not at query time
- The embedder component processes each document's text fields
- This is different from Chapter 3 where embeddings were pre-computed

### Verify Data Was Fed

Check that documents were successfully indexed with embeddings:

```bash
vespa query 'yql=select * from product where true' 'hits=5'
```

You should see products with their embeddings generated and indexed.

**If feeding fails**:
- Check error messages – usually means **embedder not configured** or **field names/types don't match** your schema
- Verify embedder component is defined in `services.xml`
- Verify embedding field is defined in `app/schemas/product.sd`
- Check that text fields (`title`, `description`) exist in the JSONL data

**More details:** 
- [Vespa cli](https://docs.vespa.ai/en/clients/vespa-cli.html#documents)

---

## Step 6 – Run Hybrid Search Queries

Now that data is fed, you can perform **hybrid search** queries that combine text and semantic search.

### Option 1: Using Vespa CLI

**Text-only search (BM25)**:

```bash
vespa query \
  'yql=select * from product where title contains "stencil"' \
  'ranking.profile=default' \
  'hits=10'
```

**Semantic-only search (ANN)**:

```bash
vespa query \
  'yql=select * from product where {targetHits:100}nearestNeighbor(embedding, q_embedding)' \
  'ranking.profile=use_closeness' \
  'query_text=Mini Stencil' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=10'
```

**Note**: `embed(@query_text)` uses the embedder component to generate the query embedding on-the-fly from the text parameter. This works in Vespa CLI but **not in REST API JSON queries** (see Option 2 below for REST API limitations).

**Hybrid search (BM25 + ANN with RRF)**:

```bash
vespa query \
  'yql=select * from product where title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=Mini Stencil' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=10'
```

**Note**: The `embed()` function generates embeddings at query time using the embedder component configured in `services.xml`. Both text search (BM25) and semantic search (ANN) are combined using RRF ranking.

![query_hybrid](img/query_hybrid.png)

**More details:** 
- [Vespa cli](https://docs.vespa.ai/en/clients/vespa-cli.html#queries)

### Option 2: Using Query REST Client

Fill in the template in the file `queries.http` using a code editor (e.g., VS Code with REST Client plugin) and run the queries.

**The Example File**: `queries.http`

1. **Verify data was fed**:
   ```json
   {
     "yql": "select * from product where true",
     "presentation.summary": "medium"
   }
   ```

2. **ANN search with query-time embedding**:
   ```json
   {
     "yql": "select * from product where {targetHits:100}nearestNeighbor(embedding, q_embedding)",
     "ranking.profile": "use_closeness",
     "presentation.summary": "medium",
     "query_text": "Mini Stencil",
     "input.query(q_embedding)": "embed(@query_text)"
   }
   ```
   
   **⚠️ Important**: The `embed()` function **does not work in REST API JSON queries**. You'll get an error: "Expected tensor but got string". For REST API, you need to:
   - **Use Vespa CLI** instead (see Option 1 above), or
   - **Pre-compute the embedding vector** and pass it as an array (see `semantic_ecommerce_app/queries.http` for an example)

3. **Hybrid search with RRF**:
   ```json
   {
     "yql": "select * from product where title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))",
     "ranking.profile": "rrf",
     "presentation.summary": "medium",
     "query_text": "Mini Stencil",
     "input.query(q_embedding)": "embed(@query_text)"
   }
   ```

![rest_query_hybrid](img/rest_query_hybrid.png)
   
   **⚠️ Same limitation**: The `embed()` function doesn't work in REST API JSON. Use Vespa CLI for query-time embedding.

**Note**: Replace `<mTLS_ENDPOINT_DNS_GOES_HERE>` with your Vespa Cloud endpoint (from `vespa status`).

### Understanding the Queries

**Components**:
- `title contains @query_text` - Text search using BM25
- `{targetHits:100}nearestNeighbor(embedding, q_embedding)` - Semantic search using ANN
- `OR` - Combines both retrieval methods
- `embed(@query_text)` - Generates query embedding on-the-fly from text
- `ranking.profile=rrf` - Uses RRF ranking to combine results

**Query-time embedding**:
- `embed("text")` - Calls the embedder component to generate a vector
- Works with any text string
- No need to pre-compute query embeddings

**For detailed query syntax**, see: [Nearest neighbor search guide](https://docs.vespa.ai/en/querying/nearest-neighbor-search-guide.html)

---

## Step 7 – Experiment with Different Queries

### 7.1 Text-Only Search

Find products using keyword matching:

```bash
vespa query \
  'yql=select * from product where title contains "shirt"' \
  'ranking.profile=default' \
  'hits=10'
```

### 7.2 Semantic-Only Search

Find products using semantic similarity:

```bash
vespa query \
  'yql=select * from product where {targetHits:100}nearestNeighbor(embedding, q_embedding)' \
  'ranking.profile=use_closeness' \
  'input.query(q_embedding)=embed("comfortable shirt")' \
  'hits=10'
```

### 7.3 Hybrid Search with RRF

Combine both methods:

```bash
vespa query \
  'yql=select * from product where title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=comfortable shirt' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=10'
```

### 7.4 Hybrid Search with Filters

Add attribute filters:

```bash
vespa query \
  'yql=select * from product where (title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))) and price < 1000 and category = "electronics"' \
  'ranking.profile=rrf' \
  'query_text=smartphone' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=10'
```

### 7.5 Compare Ranking Profiles

Run the same query with different ranking profiles:

```bash
# Text only
vespa query \
  'yql=select * from product where title contains "shirt"' \
  'ranking.profile=default'

# Semantic only
vespa query \
  'yql=select * from product where {targetHits:100}nearestNeighbor(embedding, q_embedding)' \
  'ranking.profile=use_closeness' \
  'input.query(q_embedding)=embed("shirt")'

# Hybrid with RRF
vespa query \
  'yql=select * from product where title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=shirt' \
  'input.query(q_embedding)=embed(@query_text)'
```

Compare the results and relevance scores.

---

## Exercise – Complete the TODOs

Here are the tasks you need to complete:

### 1. Define the Embedding Field

In `app/schemas/product.sd`, add the embedding field that generates embeddings from the `title` and `description` fields:

```javascript
field embedding type tensor<float>(x[384]) {
  indexing {
    (input title || "") . " " . (input description || "") | embed e5 | attribute | index
  }
  attribute {
    distance-metric: angular
  }
  index {
    hnsw {
      max-links-per-node: 16
      neighbors-to-explore-at-insert: 200
    }
  }
}
```

**Place it** after the document fields but before the `fieldset` definition.

### 2. Configure the Embedder Component

In `app/services.xml`, add the HuggingFace embedder component:

```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model model-id="e5-small-v2"/>
</component>
```

**Place it** inside the `<container>` section, before `<document-api/>`.

### 3. Implement the RRF Rank Profile

In `app/schemas/product.sd`, uncomment and complete the RRF rank profile:

```javascript
rank-profile rrf inherits use_closeness {
  function best_bm25() {
    expression: max(bm25(title), bm25(description))
  }
  global-phase {
    rerank-count: 200
    expression: reciprocal_rank(closeness(field, embedding)) + reciprocal_rank(best_bm25())
  }
}
```

**Replace the TODO comment** with the actual implementation.

### 4. Test Your Implementation

After completing the TODOs:

1. **Deploy** the application:
   ```bash
   cd app
   vespa deploy --wait 900
   ```

2. **Feed** the data:
   ```bash
   vespa feed --progress 3 dataset/vespa_feed-1K_no_embeddings.jsonl
   ```

3. **Test** hybrid search:
   ```bash
   vespa query \
     'yql=select * from product where title contains @query_text OR ({targetHits:100}nearestNeighbor(embedding, q_embedding))' \
     'ranking.profile=rrf' \
     'query_text=Mini Stencil' \
     'input.query(q_embedding)=embed(@query_text)' \
     'hits=10'
   ```

---

## Understanding RRF Ranking

### How RRF Works

**Reciprocal Rank Fusion** combines ranked lists by:
1. Converting each rank to a reciprocal rank: `1 / (k + rank)`
2. Summing reciprocal ranks across all lists
3. Ranking by the sum (higher = better)

**Example**:
- Document A: rank 1 in BM25, rank 3 in ANN
- Document B: rank 2 in BM25, rank 1 in ANN
- With k=60:
  - A: `1/(60+1) + 1/(60+3) = 0.0164 + 0.0159 = 0.0323`
  - B: `1/(60+2) + 1/(60+1) = 0.0161 + 0.0164 = 0.0325`
- B wins (higher RRF score)

### RRF Parameters

- **`rerank-count`**: Number of documents to rerank (default: 200)
  - Higher = better quality, slower queries
  - Lower = faster queries, potentially lower quality

- **`k` constant**: Controls how much rank matters (implicit in `reciprocal_rank()`)
  - Lower k = rank matters more
  - Higher k = rank matters less
  - Default: 60 (good balance)

### Tuning RRF

**For better quality**:
```javascript
global-phase {
  rerank-count: 500
  expression: reciprocal_rank(closeness(field, embedding)) + reciprocal_rank(best_bm25())
}
```

**For faster queries**:
```javascript
global-phase {
  rerank-count: 100
  expression: reciprocal_rank(closeness(field, embedding)) + reciprocal_rank(best_bm25())
}
```

**For weighted RRF** (favor one method):
```javascript
global-phase {
  rerank-count: 200
  expression: 2.0 * reciprocal_rank(closeness(field, embedding)) + reciprocal_rank(best_bm25())
}
```
---

## RAG (Retrieval-Augmented Generation)

Now that you've learned hybrid search, let's extend the application with **RAG (Retrieval-Augmented Generation)**. RAG combines search retrieval with Large Language Model (LLM) generation to produce natural language answers based on your document corpus.

### What is RAG?

**RAG** is a technique that enhances LLM responses by:
1. **Retrieving** relevant documents from your corpus using search
2. **Augmenting** the LLM prompt with retrieved context
3. **Generating** natural language answers based on retrieved facts

**Benefits**:
- Grounds LLM responses in your actual data (reduces hallucination)
- Provides citations/sources for answers
- No need to fine-tune LLMs on your data
- Can answer questions about private or recent data

**Example**:
- User asks: "What are the best rated electronics under $500?"
- System retrieves: Top-rated electronics products in that price range
- LLM generates: Natural language answer summarizing the products with details

### Key Concepts

#### RAGSearcher Component

Vespa's `RAGSearcher` is a built-in component that:
- Executes your search query to retrieve relevant documents
- Formats retrieved documents into a context prompt
- Calls the LLM with the augmented prompt
- Returns the generated response

#### LLM Client Options

**1. OpenAI Client** (External):
- Uses OpenAI API (GPT-4, GPT-3.5, etc.)
- Fast, high-quality responses
- Requires API key and internet connection
- Pay per token usage

**2. Local LLM** (Self-hosted):
- Downloads and runs model locally
- No external dependencies or API costs
- Slower, requires more resources
- Full data privacy

#### Streaming Responses

RAG supports **streaming** responses where tokens are generated incrementally:
- **Server-Sent Events (SSE)**: `format=sse` - tokens stream as they're generated
- **JSON format**: `format=json` - wait for complete response

**More Details:**
- [LLM in Vespa](https://docs.vespa.ai/en/rag/llms-in-vespa.html)
- [External LLMs in Vespa](https://docs.vespa.ai/en/rag/external-llms.html)

### Step 8 – Configure LLM Client for RAG

You'll add an OpenAI LLM client to your services configuration.

#### 8.1 Add OpenAI LLM Client

Edit [app/services.xml](app/services.xml) and add the following inside the `<container>` section (after the embedder component, before `<document-api/>`):

```xml
<!-- OpenAI LLM Client for RAG -->
<component id="openai" class="ai.vespa.llm.clients.OpenAI">
  <config name="ai.vespa.llm.clients.llm-client">
    <apiKeySecretName>openai_api_key</apiKeySecretName>
    <model>gpt-4o-mini</model>
  </config>
</component>
```

**Key points**:
- `id="openai"` - Component identifier referenced by search chain
- `class="ai.vespa.llm.clients.OpenAI"` - Built-in OpenAI client
- `apiKeySecretName` - References secret name (configured in Vespa Cloud or passed via header)
- `model` - OpenAI model to use (gpt-4o-mini is cost-effective)

**Alternative models**:
- `gpt-4o-mini` - Fast, cost-effective (recommended)
- `gpt-4o` - More capable, higher quality
- `gpt-3.5-turbo` - Faster, cheaper, less capable

#### 8.2 Add RAG Search Chain

Still in [app/services.xml](app/services.xml), replace the `<search/>` element with:

```xml
<!-- Search configuration with RAG search chain -->
<search>
  <!-- Default search chain (no LLM) -->
  <chain id="default" inherits="vespa">
    <searcher id="ai.vespa.search.llm.LLMSearcher" />
  </chain>

  <!-- RAG search chain using OpenAI -->
  <chain id="rag" inherits="vespa">
    <searcher id="ai.vespa.search.llm.RAGSearcher">
      <config name="ai.vespa.search.llm.llm-searcher">
        <providerId>openai</providerId>
        <stream>true</stream>
      </config>
    </searcher>
  </chain>
</search>
```

**Key points**:
- `chain id="rag"` - Named search chain for RAG queries
- `RAGSearcher` - Built-in component that orchestrates retrieval + generation
- `providerId="openai"` - References the OpenAI client component
- `stream="true"` - Enables token streaming for faster perceived response time

#### 8.3 Complete services.xml Example

Your complete `<container>` section should now look like:

```xml
<container id="default" version="1.0">
  <clients>
    <client id="mtls" permissions="read,write">
      <certificate file="security/clients.pem"/>
    </client>
  </clients>

  <!-- HuggingFace embedder for generating embeddings -->
  <component id="e5" type="hugging-face-embedder">
    <transformer-model model-id="e5-small-v2"/>
  </component>

  <!-- OpenAI LLM Client for RAG -->
  <component id="openai" class="ai.vespa.llm.clients.OpenAI">
    <config name="ai.vespa.llm.clients.llm-client">
      <apiKeySecretName>openai_api_key</apiKeySecretName>
      <model>gpt-4o-mini</model>
    </config>
  </component>

  <document-api/>

  <!-- Search chains -->
  <search>
    <chain id="default" inherits="vespa">
      <searcher id="ai.vespa.search.llm.LLMSearcher" />
    </chain>

    <chain id="rag" inherits="vespa">
      <searcher id="ai.vespa.search.llm.RAGSearcher">
        <config name="ai.vespa.search.llm.llm-searcher">
          <providerId>openai</providerId>
          <stream>true</stream>
        </config>
      </searcher>
    </chain>
  </search>

  <nodes>
    <node hostalias="node1" />
  </nodes>
</container>
```

### Step 9 – Configure API Key

You need to provide your OpenAI API key for the LLM client to work.

#### Option 1: Vespa Cloud Secret Store (Recommended for Production)

For Vespa Cloud deployments, use the secret store:

1. **Create secret in Vespa Cloud Console**:
   - Go to your application in [Vespa Cloud](https://console.vespa.ai/)
   - Navigate to **Secrets** section
   - Add new secret: name `openai_api_key`, value `your-api-key-here`

2. **Reference in services.xml** (already done):
   ```xml
   <apiKeySecretName>openai_api_key</apiKeySecretName>
   ```

#### Option 2: HTTP Header (For Testing)

For local testing or quick experiments, pass the API key via HTTP header:

```bash
vespa query \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  query="your question" \
  searchChain=rag
```

**Note**: The header method only works for testing. For production, always use the secret store.

### Step 10 – Deploy RAG-Enabled Application

Deploy the updated application with RAG support:

```bash
cd hybrid_ecommerce_app/ragapp

# Deploy the RAG app
vespa deploy --wait 900
vespa status

# From ragapp directory
vespa feed --progress 3 ../dataset/vespa_feed-1K_no_embeddings.jsonl
```

Wait for deployment to complete. The application will now support both regular hybrid search and RAG queries.

### Step 11 – Run RAG Queries

#### 11.1 Basic RAG Query (CLI)

Using Vespa CLI with OpenAI:

```bash
vespa query \
  --timeout 60 \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=comfortable running shoes' \
  'input.query(q_embedding)=embed(@query_text)' \
  'searchChain=rag' \
  'format=sse' \
  'hits=5'
```

**Key parameters**:
- `searchChain=rag` - Uses the RAG search chain with LLM generation
- `format=sse` - Enables streaming response (tokens appear as generated)
- `hits=5` - Retrieves top 5 products as context for LLM
- `timeout=60` - Longer timeout for LLM generation

![vespa_client_query_rag_1](img/vespa_client_query_rag_1.png)


#### 11.2 RAG Query with JSON Response

For programmatic consumption (non-streaming):

```bash
vespa query \
  --timeout 60 \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=best electronics under 500 dollars' \
  'input.query(q_embedding)=embed(@query_text)' \
  'searchChain=rag' \
  'format=json' \
  'hits=5'
```

**Output includes**:
- `root.children[]` - Retrieved documents used as context
- Generated LLM response (location depends on RAGSearcher configuration)

![vespa_client_query_rag_2](img/vespa_client_query_rag_2.png)

#### 11.3 Customizing the Prompt

You can customize the system prompt sent to the LLM:

```bash
vespa query \
  --timeout 60 \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=what are good gifts for artists?' \
  'input.query(q_embedding)=embed(@query_text)' \
  'searchChain=rag' \
  'format=sse' \
  'hits=5' \
  'llm.prompt=You are a helpful shopping assistant. Based on the product information provided, recommend products that would make great gifts for artists. Include product names, descriptions, and why they would be suitable.'
```

**Key parameters**:
- `llm.prompt` - Custom system prompt for the LLM
- Helps guide the LLM to produce responses in your desired format/tone

![vespa_client_query_rag_3](img/vespa_client_query_rag_3.png)

#### 11.4 Structured JSON Output

Force the LLM to return structured JSON:

```bash
vespa query \
  --timeout 60 \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=art supplies under 50 dollars' \
  'input.query(q_embedding)=embed(@query_text)' \
  'searchChain=rag' \
  'format=sse' \
  'hits=5' \
  'llm.json_schema={"type":"object","properties":{"recommendations":{"type":"array","items":{"type":"object","properties":{"product_name":{"type":"string"},"price":{"type":"number"},"reason":{"type":"string"}}}},"summary":{"type":"string"}},"required":["recommendations","summary"]}'
```

**Note**: The LLM will return JSON matching the specified schema, useful for structured data extraction.

![vespa_client_query_rag_4](img/vespa_client_query_rag_4.png)

### Step 12 – Compare Regular Search vs RAG

Compare the difference between regular hybrid search and RAG:

#### Regular Hybrid Search

```bash
vespa query \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=best art supplies for beginners' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=5'
```

**Returns**: List of matching products with scores

![vespa_client_query_rag_5b](img/vespa_client_query_rag_5b.png)

#### RAG Search

```bash
vespa query \
  --timeout 60 \
  --header="X-LLM-API-KEY:sk-your-api-key-here" \
  'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
  'ranking.profile=rrf' \
  'query_text=best art supplies for beginners' \
  'input.query(q_embedding)=embed(@query_text)' \
  'searchChain=rag' \
  'format=sse' \
  'hits=5'
```

**Returns**: Natural language answer generated by LLM based on retrieved products

**Key Differences**:
- **Search**: Returns structured product data
- **RAG**: Returns conversational answer with product recommendations
- **Use Search when**: You need structured data, faceted navigation, filtering
- **Use RAG when**: You want natural language answers, summaries, or explanations

![vespa_client_query_rag_5](img/vespa_client_query_rag_5.png)

### Understanding RAG Architecture

The RAG search chain performs these steps:

1. **Query Processing**: Parse user query
2. **Retrieval**: Execute hybrid search (BM25 + semantic) to find relevant products
3. **Context Building**: Format retrieved products into prompt context
4. **LLM Generation**: Send context + query to LLM
5. **Response**: Stream or return generated answer

**Prompt Template** (simplified):
```
System: You are a helpful shopping assistant.

Context:
Product 1: [title, description, price, rating]
Product 2: [title, description, price, rating]
...

User Question: [user query]

Answer: [LLM generates response here]
```

**Flow Diagram**:
```
User Query → Hybrid Search → Top-K Products → Format Context → LLM API → Generated Answer
              (BM25+ANN)     (ranked by RRF)    (prompt)        (GPT-4)    (streaming)
```

### Exercise – Implement RAG in Your Application

Now it's your turn to add RAG capabilities!

#### Task 1: Configure OpenAI Client

In [app/services.xml](app/services.xml):

1. Add the OpenAI LLM client component (after the `e5` embedder, before `<document-api/>`):
   ```xml
   <component id="openai" class="ai.vespa.llm.clients.OpenAI">
     <config name="ai.vespa.llm.clients.llm-client">
       <apiKeySecretName>openai_api_key</apiKeySecretName>
       <model>gpt-4o-mini</model>
     </config>
   </component>
   ```

#### Task 2: Add RAG Search Chain

Still in [app/services.xml](app/services.xml):

1. Replace `<search/>` with the search chain configuration including the RAG chain:
   ```xml
   <search>
     <chain id="default" inherits="vespa">
       <searcher id="ai.vespa.search.llm.LLMSearcher" />
     </chain>

     <chain id="rag" inherits="vespa">
       <searcher id="ai.vespa.search.llm.RAGSearcher">
         <config name="ai.vespa.search.llm.llm-searcher">
           <providerId>openai</providerId>
           <stream>true</stream>
         </config>
       </searcher>
     </chain>
   </search>
   ```

#### Task 3: Deploy and Test

1. **Deploy** the application:
   ```bash
   cd app
   vespa deploy --wait 900
   ```

2. **Get your OpenAI API key** from [OpenAI Platform](https://platform.openai.com/api-keys)

3. **Test RAG query**:
   ```bash
   vespa query \
     --timeout 60 \
     --header="X-LLM-API-KEY:your-api-key-here" \
     'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
     'ranking.profile=rrf' \
     'query_text=best products for home office setup' \
     'input.query(q_embedding)=embed(@query_text)' \
     'searchChain=rag' \
     'format=sse' \
     'hits=5'
   ```

4. **Compare with regular search** (without RAG):
   ```bash
   vespa query \
     'yql=select * from product where title contains @query_text OR ({targetHits:5}nearestNeighbor(embedding, q_embedding))' \
     'ranking.profile=rrf' \
     'query_text=best products for home office setup' \
     'input.query(q_embedding)=embed(@query_text)' \
     'hits=5'
   ```

**Expected outcome**:
- Regular search returns structured JSON with product documents
- RAG returns a natural language response with product recommendations

### Advanced RAG Configurations

#### Custom Prompt Templates

You can define custom prompt templates for different use cases:

```bash
# Shopping assistant style
vespa query \
  --header="X-LLM-API-KEY:your-api-key" \
  'searchChain=rag' \
  'query_text=laptop for students' \
  'input.query(q_embedding)=embed(@query_text)' \
  'llm.prompt=You are an expert shopping advisor. Analyze the products and provide a concise recommendation with pros and cons for each product. Focus on value for money.'

# Technical expert style
vespa query \
  --header="X-LLM-API-KEY:your-api-key" \
  'searchChain=rag' \
  'query_text=laptop for students' \
  'input.query(q_embedding)=embed(@query_text)' \
  'llm.prompt=You are a technical expert. Provide detailed technical specifications comparison and recommend based on performance metrics.'
```

#### Controlling Context Size

Adjust how many documents are included in the LLM context:

```bash
# More context (better quality, slower, more expensive)
vespa query \
  --header="X-LLM-API-KEY:your-api-key" \
  'searchChain=rag' \
  'query_text=kitchen appliances' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=10'

# Less context (faster, cheaper, potentially lower quality)
vespa query \
  --header="X-LLM-API-KEY:your-api-key" \
  'searchChain=rag' \
  'query_text=kitchen appliances' \
  'input.query(q_embedding)=embed(@query_text)' \
  'hits=3'
```

### RAG Best Practices

#### 1. Context Quality Over Quantity

- Use **hybrid search with RRF** to ensure high-quality retrieved context
- Limit `hits` to 3-5 most relevant products (more context ≠ better answers)
- Use good ranking profiles to surface the most relevant documents

#### 2. Cost Optimization

- Use `gpt-4o-mini` for cost-effective responses (10-100x cheaper than GPT-4)
- Limit context size with fewer `hits`
- Cache common queries at application level
- Use structured output (`llm.json_schema`) to reduce token usage

#### 3. Prompt Engineering

- Provide clear system prompts with specific instructions
- Include format requirements in prompts (e.g., "list 3 recommendations")
- Add constraints (e.g., "focus on products under $100")
- Request citations (e.g., "cite product names and prices")

#### 4. Response Quality

- **Enable streaming** (`format=sse`) for better user experience
- Use **structured output** for consistent formatting
- Implement **retry logic** for failed LLM calls
- Monitor **response quality** and adjust prompts

#### 5. Security & Privacy

- **Never expose API keys** in frontend code
- Use **Vespa Cloud Secret Store** for production
- Implement **rate limiting** to prevent abuse
- **Log queries** for monitoring and debugging

### RAG Troubleshooting

#### Issue: "Unknown search chain 'rag'"

**Symptoms**: Error when using `searchChain=rag`

**Solutions**:
1. Verify RAG search chain is defined in `services.xml`
2. Check deployment was successful (`vespa status`)
3. Ensure `<search>` section includes the `rag` chain
4. Redeploy if needed

#### Issue: "LLM client not found" or "Unknown provider 'openai'"

**Symptoms**: Error about missing LLM client

**Solutions**:
1. Verify OpenAI component is defined in `services.xml`
2. Check `id="openai"` matches `providerId="openai"` in search chain
3. Ensure component is inside `<container>` section
4. Redeploy application

#### Issue: "API key not found" or "Unauthorized"

**Symptoms**: 401 error or authentication failure

**Solutions**:
1. **For testing**: Pass API key via header: `--header="X-LLM-API-KEY:sk-..."`
2. **For production**: Configure secret in Vespa Cloud Console
3. Verify API key is valid and has credits
4. Check secret name matches: `<apiKeySecretName>openai_api_key</apiKeySecretName>`

#### Issue: Slow RAG Responses

**Symptoms**: Long query times (>10 seconds)

**Solutions**:
1. **Reduce context size**: Use fewer `hits` (try 3-5)
2. **Use faster model**: Switch to `gpt-4o-mini` or `gpt-3.5-turbo`
3. **Optimize retrieval**: Reduce `targetHits` in ANN search
4. **Enable streaming**: Use `format=sse` for perceived speed
5. **Increase timeout**: Use `--timeout 120` for complex queries

#### Issue: Poor Quality Answers

**Symptoms**: LLM responses are generic, incorrect, or unhelpful

**Solutions**:
1. **Improve retrieval**: Ensure hybrid search returns relevant products
2. **Add more context**: Increase `hits` to 5-10
3. **Better prompts**: Add specific instructions via `llm.prompt`
4. **Use better model**: Switch to `gpt-4o` for higher quality
5. **Include more fields**: Update document summaries to include relevant attributes

#### Issue: Structured Output Validation Errors

**Symptoms**: LLM doesn't return valid JSON or schema violations

**Solutions**:
1. **Simplify schema**: Use simpler JSON schemas
2. **Add examples**: Include example output in `llm.prompt`
3. **Validate schema**: Ensure JSON schema is valid
4. **Use better model**: GPT-4 handles structured output better than 3.5

### What You've Learned About RAG

By completing the RAG section, you now understand:

- **RAG Architecture**: How retrieval and generation combine
- **LLM Integration**: Configuring OpenAI client in Vespa
- **Search Chains**: Creating custom search chains with RAGSearcher
- **Streaming Responses**: Server-Sent Events for real-time token streaming
- **Prompt Engineering**: Customizing LLM behavior with prompts
- **Structured Output**: Forcing JSON schema output
- **Cost Optimization**: Balancing quality, speed, and cost
- **Best Practices**: Security, privacy, and production considerations

**Key Takeaway**: RAG transforms search results into natural language answers by combining the precision of hybrid search with the language understanding of LLMs. This enables conversational interfaces, summaries, and explanations grounded in your actual data.

### Additional RAG Resources

- **Vespa RAG Documentation**: https://docs.vespa.ai/en/llms-rag.html
- **Search Chain Components**: https://docs.vespa.ai/en/components/chained-components.html
- **RAG Sample App**: https://github.com/vespa-engine/sample-apps/tree/master/retrieval-augmented-generation
- **OpenAI API Reference**: https://platform.openai.com/docs/api-reference
- **Prompt Engineering Guide**: https://platform.openai.com/docs/guides/prompt-engineering

---

## Destroy The Deployment

**Note:** Destroy the application if needed:
   ```bash
   vespa destroy
   ```

---

## Troubleshooting

### Issue: Embedder Not Found

**Symptoms**: Error "Unknown embedder 'e5'" or similar

**Solutions**:
1. **Verify embedder component** is defined in `services.xml`
2. **Check component ID** matches the schema (e.g., `embed e5` requires `id="e5"`)
3. **Verify model ID** is correct and accessible
4. **Check deployment** - redeploy after adding embedder

### Issue: Embedding Generation Fails

**Symptoms**: Documents fail to index or embeddings are missing

**Solutions**:
1. **Check model dimensions** - must match schema (384 for e5-small-v2)
2. **Verify text fields** exist in documents
3. **Check embedder logs** - look for model download/loading errors
4. **Test embedder** - try `embed("test")` in a query

### Issue: RRF Ranking Not Working

**Symptoms**: Results don't combine properly or ranking seems wrong

**Solutions**:
1. **Verify rank profile** is correctly defined
2. **Check `rerank-count`** - should be high enough (200+)
3. **Verify both methods** return results (test BM25 and ANN separately)
4. **Check expression syntax** - `reciprocal_rank()` function calls

### Issue: Slow Query Performance

**Symptoms**: High query latency

**Solutions**:
1. **Reduce `targetHits`**: Try 50 or 100
2. **Reduce `rerank-count`**: Try 100 instead of 200
3. **Check embedder latency**: Query-time embedding adds overhead
4. **Consider pre-computing**: For very high traffic, pre-compute query embeddings

### Issue: Low Recall (Missing Relevant Results)

**Symptoms**: Relevant documents not appearing in top results

**Solutions**:
1. **Increase `targetHits`**: Try 200, 500, or 1000
2. **Increase `rerank-count`**: Try 500 or 1000
3. **Tune HNSW parameters**: Increase `max-links-per-node` or `neighbors-to-explore-at-insert`
4. **Check embedding quality**: Verify embedder model is appropriate for your domain

### Issue: Query-Time Embedding Too Slow

**Symptoms**: Queries are slow due to embedding generation

**Solutions**:
1. **Use smaller model**: e5-small-v2 instead of e5-base-v2
2. **Cache embeddings**: Consider pre-computing common queries
3. **Use ONNX embedder**: Often faster than HuggingFace
4. **Optimize model**: Use quantized or optimized models

---

## What You've Learned in Chapter 4

By completing this app, you have:

- Learned how to **configure embedder components** for query-time embedding generation
- Defined **embedding fields** that are generated from text during indexing
- Built **hybrid search queries** combining text (BM25) and semantic (ANN) search
- Implemented **RRF ranking** to fuse results from multiple retrieval methods
- Understood the **trade-offs** between query-time and pre-computed embeddings
- Explored **hybrid search** for better search quality

From here, you are ready for more advanced topics:
- **Advanced ranking** (multi-phase, custom rerankers, learning-to-rank)
- **RAG applications** (Retrieval-Augmented Generation with LLMs)
- **Multi-vector search** (searching across multiple embedding fields)
- **Production optimization** (caching, performance tuning, monitoring)

---

## Next Steps

After completing this tutorial, proceed to:

- [**Chapter 5**](https://github.com/vespauniversity/vespaworkshop101/tree/main/sales_data_app): Sales Data Analytics - Work with time-series data and aggregations


---

## Additional Resources


- **Embedding Guide**: https://docs.vespa.ai/en/embedding.html
- **HuggingFace Embedder**: https://docs.vespa.ai/en/embedding.html#huggingface-embedder
- **Nearest Neighbor Guide**: https://docs.vespa.ai/en/querying/nearest-neighbor-search-guide.html
- **Ranking Guide**: https://docs.vespa.ai/en/ranking.html
- **RRF Ranking**: https://docs.vespa.ai/en/reference/ranking-expressions.html#reciprocal-rank

---


**Key takeaway**: Hybrid search combines the precision of text search with the semantic understanding of vector search, while RRF provides a robust way to merge results from different retrieval methods.

For detailed technical reference, see the Vespa documentation links above.


Proceed to [Chapter 5](https://github.com/vespauniversity/vespaworkshop101/tree/main/sales_data_app)
