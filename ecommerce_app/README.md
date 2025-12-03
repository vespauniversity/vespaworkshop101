# E-commerce App – Vespa 101 Chapter 2

This project is **Chapter 2** in the Vespa 101 series.  
Chapter 1 (`simple_ecommerce_app`) introduced a tiny schema and very small dataset.  
This chapter upgrades to a **more realistic e-commerce catalog**, larger data, and multiple ingestion options.

The goal here is **not** to re-teach the basics from Chapter 1, but to show how to:
- Map a **real CSV product catalog** to a Vespa schema
- Deploy a slightly richer **product schema**
- Feed data in **two ways**:
  - Directly from **JSONL**
  - Via **Logstash** reading the original CSV

---

## Learning Objectives (Chapter 2)

After completing this chapter you should be able to:

- **Understand a richer product schema** with multiple fields (name, brand, price, etc.)
- **Align schema fields with a CSV header row**
- **Deploy** a Vespa app that looks more like a real catalog
- **Convert CSV → JSONL** and feed to Vespa
- **Use Logstash** to stream data from CSV into Vespa

If any of these feel unfamiliar, quickly skim `simple_ecommerce_app/README.md` first.

---

## Project Structure

From the `ecommerce_app` root:

```text
ecommerce_app/
├── app/
│   ├── schemas/
│   │   └── product.sd              # Product document schema (edit this)
│   ├── services.xml                # Vespa services config
│   └── validation-overrides.xml    # Validation overrides (used sparingly)
├── dataset/
│   ├── myntra_products_catalog.csv # Original CSV catalog
│   ├── products.jsonl              # Converted JSONL, ready to feed
│   ├── generate_jsonl.py           # Script to convert CSV → JSONL
│   └── logstash.conf               # Logstash pipeline config for CSV → Vespa
├── docs/                           # Additional documentation (optional)
├── img/                            # Screenshots and diagrams (optional)
├── put-get-remove.sh               # Example CRUD operations script
├── example.http                    # Example HTTP queries
├── answers.http                    # Reference/solution HTTP queries
├── dummy-document.json             # Minimal example document
└── README.md                       # This file
```

You will mainly touch:
- `app/schemas/product.sd`
- `dataset/products.jsonl` (or the script that creates it)
- `dataset/logstash.conf`

---

## Step 1 – Review the Product Catalog (CSV)

Open the CSV:

- File: `dataset/myntra_products_catalog.csv`

Look at the **header row** – it defines what columns your catalog has, for example (names here are illustrative):

- `id`
- `product_title`
- `brand`
- `category`
- `price`
- `rating`
- `image_url`
- `product_url`

Your exact headers may differ, but the key idea:

> **Every column you care about in the CSV should have a corresponding field in `product.sd`.**

---

## Step 2 – Update the Vespa Schema (`product.sd`)

Open:
- `app/schemas/product.sd`

This file defines the **product document schema**.  
Using what you learned in Chapter 1 and the docs in `simple_ecommerce_app/docs/SCHEMAS*.md`, do the following:

1. **Create fields** that match important CSV columns  
   - Example ideas (your names should reflect your actual CSV):
     - `product_title` – `string`, `indexing: summary | index`
     - `brand` – `string`, `indexing: summary | attribute`
     - `category` – `string`, `indexing: summary | index | attribute`
     - `price` – `double`, `indexing: summary | attribute | attribute: fast-search`
     - `rating` – `double`, `indexing: summary | attribute`

2. **Choose indexing modes** per field  
   - **Searchable text** → `index | summary`
   - **Filter/sort fields** → `attribute` (and sometimes `attribute: fast-search`)
   - **Returned in results** → always include `summary`

3. **Keep it simple first**  
   - One `rank-profile default` is enough to start.
   - You can customize ranking (BM25, price/rating boosts, etc.) after data is flowing.

For detailed examples of fields and indexing, see:
- `simple_ecommerce_app/docs/SCHEMAS.md`
- `simple_ecommerce_app/docs/SCHEMAS_REF.md`

---

## Step 3 – Deploy the Application

From the `ecommerce_app` root:

> **Assumption**: You already configured **target** and **application name** in Chapter 1  
> (for example `vespa config set target local` or `cloud`, and `vespa config set application <tenant>.<app>[.<instance>]`).

If you **skipped Chapter 1 setup**, do that first using `simple_ecommerce_app/README.md` (Prerequisites + Setup).

Then deploy this Chapter 2 app:

```bash
cd app

# set the application name something like:
# vespa config set application my-tenant.ecommerce-app

# create the cert
vespa auth cert

# deploy it
vespa deploy

# check the status
vespa status
```

Wait for deployment to complete successfully.  
You should see output indicating the application is **ready**.

---

## Step 4 – Feed Data from JSONL

The CSV has already been converted to JSONL using:
- `dataset/generate_jsonl.py`

The resulting file:
- `dataset/products.jsonl`

Each line is a JSON document in Vespa feed format (one product per line).

Feed it:

```bash
vespa feed ../dataset/products.jsonl
```

![vespa_feed](img/vespa_feed.png)

What this does:
- Sends each JSONL line as a **put document** request to Vespa
- Uses your updated `product.sd` schema to validate and index fields

If feeding fails:
- Check error messages – usually it means **field names/types don’t match** your schema
- Compare:
  - Field names in `products.jsonl`
  - Field names and types in `app/schemas/product.sd`

---

## Step 5 – Verify Data with Simple Queries

Once feeding succeeds, try a few basic queries (adjust field names to your schema):

```bash
# Return any products
vespa query 'yql=select * from product where true'

# Search by product title
vespa query 'yql=select * from product where ProductName contains "shirt"'

# Filter by price
vespa query 'yql=select * from product where Price < 1000'

# Combined search + filter
vespa query 'yql=select * from product where ProductName contains "sneaker" and Price < 5000'
```

![vespa_query_1](img/vespa_query_1.png)

These are similar in spirit to Chapter 1, but now operate on a **much richer schema and larger dataset**.

---

