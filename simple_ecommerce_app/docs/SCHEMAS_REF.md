# SUMMARY OF THE SCHEMAS REFERENCE
Ref: https://docs.vespa.ai/en/reference/schema-reference.html

This file is a **newbie-friendly cheat sheet** for the Vespa **Schema Reference**, meant to be read *after* `SCHEMAS.md`.
Where `SCHEMAS.md` explains the ideas, this doc focuses on **what options exist** and **when to use them**.

---

## 1. Schema File Overview

A schema file (`.sd`) typically contains, in this order:

- **schema**: The schema name and top-level configuration
- **document**: The document type and its fields
- **field**: Field definitions (type + indexing + options)
- **rank-profile**: How to score/rank results
- **fieldset**: Groups of fields to search/retrieve together
- Optional: **constants**, **imports**, and other advanced settings

Very simplified shape:

```vespa
schema product {
    document product {
        // field definitions
    }

    // rank profiles

    // fieldsets
}
```

If you are new, focus on:
- `document` + `field` blocks
- `indexing` directives (see `SCHEMAS.md`)
- `rank-profile` for ranking

---

## 2. `schema` Block

Top-level declaration:

```vespa
schema product {
    document product { ... }

    // schema-level settings can go here
}
```

Common things inside `schema`:
- `document` block
- One or more `rank-profile` blocks
- `fieldset` definitions
- Optional: `import field`, `constant` definitions, etc.

For most beginner use cases, you only need **one schema per app**, often named after your main entity (e.g. `product`, `doc`, `item`).

---

## 3. `document` Block

The `document` block defines the **document type** (the main entity you store/search).

```vespa
schema product {
    document product {
        field id type string { indexing: attribute | summary }
        field title type string { indexing: summary | index }
        field price type double { indexing: attribute | attribute: fast-search }
    }
}
```

Key points:
- The document name usually matches the schema name.
- All **fields** that are stored in Vespa live inside `document { ... }`.
- You can think of this like a **table schema** (Postgres) or **index mapping** (Elasticsearch).

---

## 4. `field` Block

Fields are where most of the schema reference options live.

Basic pattern:

```vespa
field <name> type <type> {
    indexing: ...
    [extra options...]
}
```

### 4.1 Field Types (Most Common)

- **Primitive types**
  - `string`
  - `int`, `long`
  - `float`, `double`
  - `bool`
  - `uri`
- **Collections**
  - `array<string>`, `array<int>`, ...
  - `weightedset<string>` (value + weight) – good for tags with importance
- **Tensors (for vectors & ML)**
  - `tensor<float>(x[384])` – dense vector
  - `tensor<float>(x{},y{})` – sparse tensor (keyed by strings)

For RAG / search apps, the most important new type is:

```vespa
field embedding type tensor<float>(x[384]) {
    indexing: attribute | index
}
```

### 4.2 Indexing (quick recap from `SCHEMAS.md`)

Inside a field you often have:

```vespa
field title type string {
    indexing: summary | index
}
```

- **`summary`**: field is retrievable in results
- **`index`**: full-text or vector index
- **`attribute`**: in-memory storage for filtering/sorting
- **`attribute: fast-search`**: extra-fast filtering index

You can combine these with `|`.

### 4.3 Useful Field Options (Beginner Set)

Some important options you will see in the reference:

- **`indexing`**: how to process and store (covered above)
- **`attribute: fast-access`**: optimize frequent random access
- **`matching`**: how text is matched (e.g. `matching: word`, `matching: exact`)
- **`rank`**: influence ranking (e.g. `rank: filter`) – tells Vespa this field is mainly for filtering
- **`stemming`**: for text languages (e.g. `stemming: best`, `stemming: none`)
- **`weight`**: for `weightedset` fields (implicit via values)

Example:

```vespa
field category type string {
    indexing: summary | index | attribute
    rank: filter        # used mostly as filter
    matching: exact     # no tokenization, exact matches
}
```

As a newbie, you can ignore most advanced flags until you need them. Start with:
- `indexing`
- `matching`
- `rank: filter` on pure filter fields

---

## 5. Collections: `array` and `weightedset`

### `array`

```vespa
field tags type array<string> {
    indexing: summary | index
}
```

- Good for unordered lists (tags, categories).
- Can be searched and filtered similarly to single-valued fields.

### `weightedset`

```vespa
field interests type weightedset<string> {
    indexing: attribute
}
```

- Stores **value + weight** per entry.
- Useful when each entry has importance (e.g. user interests with scores).
- Often used in ranking expressions to boost some values more than others.

---

## 6. Tensors & Vector Fields

Tensors are the core of Vespa’s **vector / ML** capabilities.

### 6.1 Dense Vector (Most Common)

```vespa
field embedding type tensor<float>(x[384]) {
    indexing: attribute | index
}
```

- Used for **semantic search**, **RAG**, **recommendation**.
- `index` on tensor creates an approximate nearest neighbor (HNSW) index.
- Often paired with `closeness(embedding)` or `distance(embedding)` in rank profiles.

### 6.2 Sparse / Keyed Tensor (Advanced)

```vespa
field sparse_features type tensor<float>(term{}) {
    indexing: attribute
}
```

- Keys are strings (`term`), values are floats.
- Useful for feature stores or models with sparse features.

As a beginner, you usually only need 1D dense tensor vectors.

---

## 7. `rank-profile` Block (Reference View)

You saw examples in `SCHEMAS.md`. Here we focus on **what options exist**.

```vespa
rank-profile default {
    first-phase {
        expression: nativeRank(title, description)
    }

    second-phase {
        expression: closeness(embedding)
    }
}
```

### 7.1 Important Pieces

- **`first-phase`**
  - Required.
  - Main ranking expression (fast, computed for many docs).
- **`second-phase`**
  - Optional.
  - More expensive, run only on top candidates from first phase.
- **`constants`**
  - You can define per-profile constants for weights.

Common ranking functions:
- `nativeRank(field...)`
- `bm25(field)`
- `closeness(tensor_field)`
- `distance(tensor_field)`
- `attribute(field)`

Example with constant:

```vespa
rank-profile hybrid inherits default {
    constants {
        text_weight: 0.6
        vector_weight: 0.4
    }
    first-phase {
        expression: text_weight * bm25(title) +
                    vector_weight * closeness(embedding)
    }
}
```

---

## 8. `fieldset` Block (Reference View)

Fieldsets group fields for convenience.

```vespa
fieldset default {
    fields: title, description, tags
}
```

You can then search this fieldset instead of listing fields individually.

Typical usage:
- Define a `default` fieldset containing your main text fields.
- Use it as the default search target in queries.

---

## 9. Constants and Imported Fields (Overview)

These are more advanced but good to know they exist.

### 9.1 `constant`

You can define external constants (e.g. model weights, thresholds) in separate files and reference them in ranking.

Very simplified example:

```vespa
rank-profile myprofile {
    constants {
        my_const: 0.42
    }
    first-phase {
        expression: bm25(title) * my_const
    }
}
```

In production you often load **large tensors** (like model weights) as constants.

### 9.2 `import field`

Used in multi-schema / multi-document setups to reference fields from other document types.

As a beginner working with a single `product` schema, you can safely ignore this until you have cross-document relationships.

---

## 10. Summary & How to Use This Reference with `SCHEMAS.md`

Use this file together with `SCHEMAS.md`:

- **Start with `SCHEMAS.md`** for:
  - What schemas are
  - Indexing directives (`summary`, `index`, `attribute`)
  - Rank profiles and examples
  - Example product schema

- **Use `SCHEMAS_REF.md` when you ask:**
  - “Which field types can I use?”
  - “What options can I put inside a `field`?”
  - “How do I define rank profiles and fieldsets?”
  - “How do I define vector fields and use them in ranking?”

### Quick Checklist for a New Schema

1. **Define schema + document**
   - `schema product { document product { ... } }`
2. **Add fields**
   - Choose proper **type** (`string`, `double`, `tensor<float>(x[384])`, …)
   - Set **indexing** (`summary`, `index`, `attribute`, etc.)
3. **Add at least one `rank-profile`**
   - Start with `nativeRank` or simple `bm25` / `closeness`
4. **Add a `fieldset default`**
   - Group your main text fields
5. **Iterate**
   - Add more fields / rank-profiles as your app needs

With just these pieces, you can read the official **Schema Reference** and map most options back to concrete use cases in your own app.
