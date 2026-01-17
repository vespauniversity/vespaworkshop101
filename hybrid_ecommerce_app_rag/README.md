# Hybrid E-commerce RAG App – Vespa 101 Chapter 4a

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

### Step 1 – Configure LLM Client for RAG

You'll add an OpenAI LLM client to your services configuration.

#### 1.1 Add OpenAI LLM Client

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

#### 1.2 Add RAG Search Chain

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

#### 1.3 Complete services.xml Example

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

### Step 2 – Configure API Key

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

### Step 3 – Deploy RAG-Enabled Application

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

### Step 4 – Run RAG Queries

#### 4.1 Basic RAG Query (CLI)

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


#### 4.2 RAG Query with JSON Response

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

#### 4.3 Customizing the Prompt

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

#### 4.4 Structured JSON Output

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

### Step 5 – Compare Regular Search vs RAG

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

## Next Steps

After completing this tutorial, proceed to:

- [**Chapter 5**](https://github.com/vespauniversity/vespaworkshop101/tree/main/sales_data_app): Sales Data Analytics - Work with time-series data and aggregations


