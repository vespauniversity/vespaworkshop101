# E-commerce Ranking App – Vespa 101 Chapter 1: Basic Lexical Ranking

This project is **Chapter 1** in the Vespa 101 ranking series.  
This chapter introduces **Vespa ranking** with text/lexical search, focusing on how to write rank profiles and combine text relevance with business signals.

The goal here is to learn how to:
- Write and configure **rank profiles** in Vespa
- Use **BM25** and **nativeRank** for text relevance
- Combine multiple ranking signals (text + business logic)
- Implement **two-phase ranking** with user preferences

---

## Learning Objectives

After completing this chapter you should be able to:

- **Understand rank profiles** and how they control document scoring
- **Implement BM25 ranking** for industry-standard text relevance
- **Combine ranking signals** (text relevance + business attributes)
- **Use functions** to organize ranking expressions
- **Implement two-phase ranking** for performance optimization
- **Apply user preferences** via tensor operations

**Prerequisites:**
- Basic understanding of Vespa schemas and deployment (from `ecommerce_app`)
- Familiarity with YQL queries
- Understanding of text search concepts (term frequency, relevance scoring)

---

## Project Structure

From the `ecommerce_ranking_app` root:

```text
ecommerce_ranking_app/
├── app/
│   ├── schemas/
│   │   └── product/
│   │       ├── product.sd             # Product document schema
│   │       ├── default.profile        # Step 1: Basic nativeRank (TODO)
│   │       ├── bm25.profile           # Step 2: BM25 ranking (TODO)
│   │       ├── nativeRankBM25.profile # Step 3: Combining signals (TODO)
│   │       ├── ratingboost.profile    # Step 4: Business logic (TODO)
│   │       └── preferences.profile    # Step 5: User preferences (TODO)
│   ├── services.xml                   # Vespa services config
│   └── .vespaignore
├── cheating/                          # Solution files (reference only)
│   ├── bm25.profile
│   ├── nativeRankBM25.profile
│   ├── ratingboost.profile
│   └── preferences.profile
├── dataset/
│   ├── products.jsonl                 # Product data with ratings and features
│   └── enhance_data.py                # Script to add ratings and ProductFeatures
├── docs/                              # Additional documentation
│   ├── RANKING.md                     # Ranking concepts and rank profiles
│   ├── QUERIES.md                     # Query examples and patterns
│   └── SCHEMA.md                      # Schema design for ranking
├── img/
│   └── rank_profile_files.png         # Diagram of rank profile structure
├── queries.http                       # Example HTTP queries for each step
└── README.md                          # This file
```

You will mainly work with:
- `app/schemas/product/*.profile` files (rank profiles)
- `queries.http` (testing queries)

---

## Key Concepts

### What is Ranking?

**Ranking** determines how relevant each document is to a query and sorts results by relevance score. It's the "scoring system" that decides which documents appear first in search results.

**Example:**
- Query: "blue jeans"
- **Matching**: Finds all documents containing "blue" and "jeans"
- **Ranking**: Scores each match based on:
  - How well the text matches (term frequency, field importance)
  - Business signals (rating, price, user preferences)
- **Sorting**: Results ordered by score (highest first)

### Rank Profiles

A **rank profile** defines how documents are scored. You can have multiple rank profiles in one schema for different use cases or A/B testing.

**Basic Structure:**
```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(ProductName, Description)
    }
}
```

**Key Components:**
- **Rank Profile Name**: Identifies the profile (e.g., `default`, `bm25`, `preferences`)
- **First-Phase**: Fast ranking that runs on all matching documents
- **Second-Phase**: Optional expensive ranking on top N documents (for performance)
- **Functions**: Reusable expressions for complex ranking logic
- **Summary-Features**: Expose intermediate scores for debugging

**For detailed documentation**, see: [`docs/RANKING.md`](docs/RANKING.md)

### Ranking Algorithms

This chapter introduces two text ranking algorithms:

- **`nativeRank`**: Vespa's default ranking algorithm, optimized for general text search with term proximity
- **`BM25`**: Industry-standard ranking algorithm (Best Matching 25), widely used in search systems

**For detailed comparison**, see: [`docs/RANKING.md`](docs/RANKING.md#nativerank-vs-bm25)

### Business Logic Integration

Ranking isn't just about text relevance. Real-world search systems combine:
- **Text relevance**: How well documents match query terms
- **Business signals**: Ratings, popularity, price, recency
- **User preferences**: Personalized ranking based on user behavior

This tutorial shows how to combine these signals.

### Two-Phase Ranking

**Two-phase ranking** optimizes performance by:
1. **First-phase**: Fast ranking on all matching documents (cheap features)
2. **Second-phase**: Expensive ranking on top N documents (expensive features)

**Example:**
```vespa
rank-profile preferences {
    first-phase {
        expression: bm25(ProductName) * attribute(AverageRating)
    }
    second-phase {
        rerank-count: 10
        expression: sum(query(user_preferences) * attribute(ProductFeatures))
    }
}
```

---

## Overview

This tutorial progresses through 5 steps, each building on the previous:

### Step 1: Default nativeRank
**Goal**: Understand basic rank profiles

- Start with `default.profile` using `nativeRank`
- Learn how rank profiles control scoring
- Test with simple queries

**Key Learning**: How rank profiles work and how to use them in queries

### Step 2: BM25 Ranking
**Goal**: Implement industry-standard BM25 ranking

- Create `bm25.profile` using `bm25()` function
- Compare BM25 vs nativeRank results
- Understand when to use each algorithm

**Key Learning**: BM25 algorithm and when to use it

### Step 3: Combining Signals
**Goal**: Combine multiple ranking signals

- Create `nativeRankBM25.profile` combining both algorithms
- Use functions to organize ranking expressions
- Learn about `summary-features` for debugging

**Key Learning**: How to combine multiple ranking signals using functions

### Step 4: Business Logic (Rating Boost)
**Goal**: Integrate business signals into ranking

- Create `ratingboost.profile` that multiplies text relevance by rating
- Understand how to use document attributes in ranking
- See how business logic affects result ordering

**Key Learning**: Combining text relevance with business attributes

### Step 5: User Preferences (Two-Phase Ranking)
**Goal**: Implement personalized ranking with two-phase ranking

- Create `preferences.profile` with two-phase ranking
- Use query inputs for dynamic ranking
- Implement tensor operations for user preferences

**Key Learning**: Two-phase ranking, query inputs, and tensor operations

---

## Step 1 – Default nativeRank

**File**: `app/schemas/product/default.profile`

### Task

Update the `default.profile` to use `nativeRank` on both `ProductName` and `Description`:

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(ProductName, Description)  # TODO: adjust here for this lab
    }
}
```

**What to do:**
1. Remove the `# TODO` comment
2. Ensure the expression uses `nativeRank(ProductName, Description)`
3. Deploy the app: `vespa deploy --wait 900`

**Notes:**
- For detailed deployment instructions and setup, see the [Deploying and Testing](#deploying-and-testing) section below
- If you're new to Vespa deployment, refer to `ecommerce_app/README.md` for prerequisites and initial setup
- You can test queries using the HTTP REST client (VS Code REST Client extension) with `queries.http` - see `ecommerce_app/README.md` section "5.3 Using the HTTP REST API" for setup instructions

### Testing

Use the query from `queries.http`:

```http
### step 1) search for shirt, default rank profile
POST https://<mTLS_ENDPOINT_DNS_GOES_HERE>/search/
Content-Type: application/json

{
  "yql": "select * from product where ProductName contains 'shirt'"
}
```

**Expected Result:**
- Documents containing "shirt" in ProductName are returned
- Results are sorted by `nativeRank` score (highest first)
- Check the `relevance` field in results to see scores

### What You're Learning

- **Rank profiles** define how documents are scored
- **nativeRank** is Vespa's default text ranking algorithm
- **First-phase** ranking runs on all matching documents
- Results are automatically sorted by relevance score

---

## Step 2 – BM25 Ranking

**File**: `app/schemas/product/bm25.profile`

### Task

Create a new rank profile that uses BM25 instead of nativeRank:

```vespa
rank-profile bm25 {
    first-phase {
        expression: bm25(ProductName)  # TODO: implement BM25 ranking
    }
}
```

**What to do:**
1. Replace the `# TODO` with `bm25(ProductName)`
2. Deploy the app: `vespa deploy --wait 900`

### Testing

Use the query from `queries.http`:

```http
### step 2) search for shirt, custom rank profile
POST https://<mTLS_ENDPOINT_DNS_GOES_HERE>/search/
Content-Type: application/json

{
  "yql": "select * from product where ProductName contains 'shirt'",
  "ranking.profile": "bm25"
}
```

**Compare Results:**
- Run the same query with `default` profile and `bm25` profile
- Notice differences in result ordering
- BM25 may rank documents differently than nativeRank

### What You're Learning

- **BM25** is an industry-standard ranking algorithm
- Different rank profiles can produce different result orderings
- You can switch profiles per query using `ranking.profile` parameter

**For detailed BM25 explanation**, see: [`docs/RANKING.md`](docs/RANKING.md#bm25-function)

---

## Step 3 – Combining Signals (nativeRank + BM25)

**File**: `app/schemas/product/nativeRankBM25.profile`

### Task

Create a rank profile that combines both nativeRank and BM25:

```vespa
rank-profile nativeRankBM25 {
    function my_bm25() {
        expression: bm25(ProductName)  # TODO: implement
    }

    function my_nativeRank() {
        expression: nativeRank(Description) * 1.7  # TODO: implement
    }

    summary-features: my_bm25 my_nativeRank  # TODO: add summary features

    first-phase {
        expression: my_bm25() + my_nativeRank()  # TODO: combine signals
    }
}
```

**What to do:**
1. Implement `my_bm25()` function using `bm25(ProductName)`
2. Implement `my_nativeRank()` function using `nativeRank(Description) * 1.7`
3. Add both functions to `summary-features` (for debugging)
4. Combine them in `first-phase` expression
5. Deploy the app: `vespa deploy --wait 900`

### Testing

Use the query from `queries.http`:

```http
### step 3) search for shirt in both title and description, combining signals
POST https://<mTLS_ENDPOINT_DNS_GOES_HERE>/search/
Content-Type: application/json

{
  "yql": "select * from product where ProductName contains 'shirt' OR Description contains 'shirt'",
  "ranking.profile": "nativeRankBM25"
}
```

Or via CLI:

```bash
vespa query \
  'yql=select * from product where ProductName contains "shirt" OR Description contains "shirt"' \
  'ranking.profile=nativeRankBM25'
```

**What to Check:**
- Results combine scores from both algorithms
- `summary-features` in results show individual scores
- Description matches get 1.7x weight (higher importance)

### What You're Learning

- **Functions** organize ranking expressions for reusability
- **summary-features** expose intermediate scores for debugging
- You can **combine multiple ranking signals** by adding scores
- **Field weighting** (1.7x for Description) emphasizes certain fields

---

## Step 4 – Business Logic (Rating Boost)

**File**: `app/schemas/product/ratingboost.profile`

### Task

Create a rank profile that boosts results by their average rating:

```vespa
rank-profile ratingboost {
    function my_bm25() {
        expression: bm25(ProductName)  # TODO: implement
    }

    function my_nativeRank() {
        expression: nativeRank(Description) * 1.7  # TODO: implement
    }

    summary-features: my_bm25 my_nativeRank  # TODO: add summary features

    first-phase {
        expression: (my_bm25() + my_nativeRank()) * attribute(AverageRating)  # TODO: multiply by rating
    }
}
```

**What to do:**
1. Implement the functions (same as Step 3)
2. Multiply the combined text relevance by `attribute(AverageRating)`
3. This boosts highly-rated products
4. Deploy the app: `vespa deploy --wait 900`

### Testing

Use the query from `queries.http`:

```http
### step 4) search for shirt in both title and description, with rating boost
POST https://<mTLS_ENDPOINT_DNS_GOES_HERE>/search/
Content-Type: application/json

{
  "yql": "select * from product where ProductName contains 'shirt' OR Description contains 'shirt'",
  "ranking.profile": "ratingboost"
}
```

**What to Check:**
- Highly-rated products (4.5+) should rank higher
- Products with same text relevance but higher ratings rank above lower-rated ones
- Compare with `nativeRankBM25` profile to see the difference

### What You're Learning

- **Business signals** (ratings) can be integrated into ranking
- **attribute()** function accesses document attributes in ranking
- **Multiplication** boosts results (vs addition which adds signals)
- Real-world ranking combines relevance + business logic

---

## Step 5 – User Preferences (Two-Phase Ranking)

**File**: `app/schemas/product/preferences.profile`

### Task

Create a rank profile with two-phase ranking that uses user preferences:

```vespa
rank-profile preferences {
    inputs {
        query(user_preferences) tensor<float>(features{})  # TODO: define query input
    }

    function my_bm25() {
        expression: bm25(ProductName)  # TODO: implement
    }

    function my_nativeRank() {
        expression: nativeRank(Description) * 1.7  # TODO: implement
    }

    summary-features: my_bm25 my_nativeRank  # TODO: add summary features

    first-phase {
        expression: (my_bm25() + my_nativeRank()) * attribute(AverageRating)  # TODO: same as ratingboost
    }

    second-phase {
        rerank-count: 10  # TODO: rerank top 10 from first phase
        expression: sum(query(user_preferences) * attribute(ProductFeatures))  # TODO: tensor dot product
    }
}
```

**What to do:**
1. Define `query(user_preferences)` input tensor
2. Implement first-phase (same as `ratingboost`)
3. Add second-phase that:
   - Reranks top 10 documents from first phase
   - Computes tensor dot product: `sum(query(user_preferences) * attribute(ProductFeatures))`
4. Deploy the app: `vespa deploy --wait 900`

### Understanding ProductFeatures Tensor

The `ProductFeatures` tensor is a sparse tensor with features like:
```json
{
  "ProductBrandDKNY": 1,
  "GenderUnisex": 1,
  "PrimaryColorBlack": 1,
  "PriceFactor": 0.93
}
```

The `PriceFactor` is calculated as `5 - log10(price)`, so lower prices get higher factors.

### Testing

Use the query from `queries.http`:

```http
### step 5) add user preferences
POST https://<mTLS_ENDPOINT_DNS_GOES_HERE>/search/
Content-Type: application/json

{
  "yql": "select * from product where ProductName contains 'shirt' OR Description contains 'shirt'",
  "ranking.features.query(user_preferences)": "{{features:GenderWomen}:1,{features:GenderUnisex}:0.7,{features:PriceFactor}:3}",
  "ranking.profile": "preferences"
}
```

**What the query input means:**
- `GenderWomen: 1` - User prefers women's products (weight: 1.0)
- `GenderUnisex: 0.7` - User likes unisex products (weight: 0.7)
- `PriceFactor: 3` - User strongly prefers lower prices (weight: 3.0)

**What to Check:**
- First phase: Fast ranking on all matches (text + rating)
- Second phase: Top 10 reranked by user preferences
- Products matching user preferences rank higher
- Check `relevance` scores to see the difference

### What You're Learning

- **Two-phase ranking** optimizes performance (cheap first, expensive second)
- **Query inputs** allow dynamic ranking per query
- **Tensor operations** enable complex feature matching
- **Personalization** can be implemented via tensor dot products
- **rerank-count** controls how many documents enter second phase

**For detailed two-phase ranking explanation**, see: [`docs/RANKING.md`](docs/RANKING.md#two-phase-ranking)

---

## Deploying and Testing

### Prerequisites

> **Assumption**: You already configured **target** and **application name**  
> (for example `vespa config set target local` or `cloud`, and `vespa config set application <tenant>.<app>[.<instance>]`).

If you **haven't set up Vespa yet**, do that first using `ecommerce_app/README.md` (Prerequisites + Setup).

### Step 1: Deploy the Application

```bash
cd app

# Verify configuration
vespa config get target        # Should show: cloud or local
vespa config get application   # Should show: tenant.app.instance

# Deploy
vespa deploy --wait 900

# Check status
vespa status
```

### Step 2: Feed Data

```bash
# From app directory
vespa feed --progress 3 ../dataset/products.jsonl
```

### Step 3: Test Queries

Use `queries.http` or the Vespa CLI:

```bash
# Step 1: Test default profile
vespa query 'yql=select * from product where ProductName contains "shirt"'

# Step 2: Test BM25 profile
vespa query \
  'yql=select * from product where ProductName contains "shirt"' \
  'ranking.profile=bm25'

# Step 3: Test nativeRankBM25 profile (combining signals)
vespa query \
  'yql=select * from product where ProductName contains "shirt" OR Description contains "shirt"' \
  'ranking.profile=nativeRankBM25'

# Step 4: Test ratingboost profile (with rating boost)
vespa query \
  'yql=select * from product where ProductName contains "shirt" OR Description contains "shirt"' \
  'ranking.profile=ratingboost'

# Step 5: Test preferences profile (with user preferences)
vespa query \
  'yql=select * from product where ProductName contains "shirt" OR Description contains "shirt"' \
  'ranking.profile=preferences' \
  'ranking.features.query(user_preferences)={{features:GenderWomen}:1,{features:GenderUnisex}:0.7,{features:PriceFactor}:3}'
```

**For more query examples**, see: [`docs/QUERIES.md`](docs/QUERIES.md)

---

## Exercises

Here are additional practice tasks:

### Exercise 1: Compare Ranking Algorithms

1. Run the same query with `default`, `bm25`, and `nativeRankBM25` profiles
2. Compare the top 5 results from each
3. Note which algorithm ranks which products higher and why

### Exercise 2: Tune Field Weights

1. In `nativeRankBM25.profile`, experiment with different weights:
   - Try `nativeRank(Description) * 2.0` (higher weight)
   - Try `nativeRank(Description) * 1.0` (equal weight)
2. Compare results and see how field importance affects ranking

### Exercise 3: Adjust Rating Boost

1. In `ratingboost.profile`, try different boost strategies:
   - `* attribute(AverageRating)` (linear)
   - `* pow(attribute(AverageRating), 2)` (quadratic - stronger boost)
   - `+ attribute(AverageRating) * 0.5` (additive instead of multiplicative)
2. See how different boost strategies affect results

### Exercise 4: Custom User Preferences

1. Create different user preference profiles:
   - Price-conscious user: `{PriceFactor: 5}`
   - Brand-loyal user: `{ProductBrandNike: 2, ProductBrandAdidas: 1.5}`
   - Color-picky user: `{PrimaryColorBlue: 2, PrimaryColorBlack: 1.5}`
2. Compare how different preferences affect ranking

### Exercise 5: Debug with Summary Features

1. Add more `summary-features` to see intermediate scores:
   ```vespa
   summary-features: my_bm25 my_nativeRank AverageRating
   ```
2. Inspect the `summary-features` in query results
3. Understand how each component contributes to final score

---

## Troubleshooting

### Rank Profile Not Found

**Error**: `Unknown rank profile: bm25`

**Solution**:
- Ensure the profile file exists in `app/schemas/product/`
- Redeploy: `vespa deploy --wait 900`
- Check profile name matches exactly (case-sensitive)

### No Results or Wrong Ordering

**Issue**: Results don't match expected ranking

**Solution**:
- Check that fields used in ranking are indexed/attribute as needed
- Verify `summary-features` to see intermediate scores
- Compare with `cheating/` solution files
- Ensure data is fed correctly: `vespa query 'yql=select * from product where true'`

### Tensor Operation Errors

**Error**: Issues with `ProductFeatures` tensor operations

**Solution**:
- Verify `ProductFeatures` field exists in schema
- Check tensor structure matches query input format
- Ensure data includes `ProductFeatures` (run `enhance_data.py` if needed)
- See [`docs/SCHEMA.md`](docs/SCHEMA.md#tensor-fields) for tensor field details

### Query Input Not Working

**Error**: `user_preferences` not recognized

**Solution**:
- Ensure `inputs` section is defined in rank profile
- Check tensor type matches: `tensor<float>(features{})`
- Verify query parameter format: `ranking.features.query(user_preferences)=...`
- See [`docs/QUERIES.md`](docs/QUERIES.md#query-inputs) for examples

---

## What You've Learned

By completing this tutorial, you have:

- ✅ **Understood rank profiles** and how they control document scoring
- ✅ **Implemented BM25 ranking** for industry-standard text relevance
- ✅ **Combined multiple ranking signals** using functions
- ✅ **Integrated business logic** (ratings) into ranking
- ✅ **Implemented two-phase ranking** for performance optimization
- ✅ **Applied user preferences** via tensor operations

**Key Takeaways:**
- Ranking is about combining multiple signals (text + business + user)
- Functions organize complex ranking expressions
- Two-phase ranking balances performance and accuracy
- Tensor operations enable powerful personalization

---

## Next Steps

From here, you're ready for:

- **Chapter 2**: Semantic/vector search with embeddings
- **Chapter 3**: Hybrid search (lexical + semantic) + learned reranking
- **Chapter 4**: Chunked document ranking (RAG scenarios)

**Related Tutorials:**
- `ecommerce_app` - Basic schema and queries
- `semantic_ecommerce_app` - Vector search and embeddings
- `hybrid_ecommerce_app` - Combining lexical and semantic search

---

## Additional Resources

- [Vespa Ranking Documentation](https://docs.vespa.ai/en/ranking.html)
- [Rank Profiles Reference](https://docs.vespa.ai/en/reference/schema-reference.html#rank-profile)
- [BM25 Reference](https://docs.vespa.ai/en/ranking/bm25.html)
- [nativeRank Reference](https://docs.vespa.ai/en/reference/nativerank.html)
- [Tensor Operations](https://docs.vespa.ai/en/reference/tensor.html)

**Project Documentation:**
- [`docs/RANKING.md`](docs/RANKING.md) – Detailed ranking concepts and examples
- [`docs/QUERIES.md`](docs/QUERIES.md) – Query patterns and examples
- [`docs/SCHEMA.md`](docs/SCHEMA.md) – Schema design for ranking

**Solution Files:**
- `cheating/` directory contains completed rank profiles for reference
- Compare your implementations with solutions to verify correctness
