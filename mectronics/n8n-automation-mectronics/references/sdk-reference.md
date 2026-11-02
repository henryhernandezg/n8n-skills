# n8n Workflow SDK Reference

## SDK Import Statement

```javascript
import { workflow, node, trigger, sticky, placeholder, newCredential, ifElse, switchCase, merge, splitInBatches, nextBatch, languageModel, memory, tool, outputParser, embedding, embeddings, vectorStore, retriever, documentLoader, textSplitter, reranker, fromAi, expr } from '@n8n/workflow-sdk';
```

## Key Patterns

### Linear Chain
```javascript
export default workflow('id', 'name')
  .add(startTrigger)
  .to(fetchData)
  .to(processData);
```

### Conditional Branching (Switch)
```javascript
const routeBy = switchCase({ version: 3.2, config: { name: 'Route', parameters: {
  rules: { values: [{
    outputKey: 'Option A',
    conditions: { combinator: 'and', options: { caseSensitive: true, leftValue: '', typeValidation: 'strict' },
      conditions: [{ leftValue: expr('{{ $json.field }}'), rightValue: 'value', operator: { type: 'string', operation: 'equals' } }]
    }
  }] },
  options: { fallbackOutput: 'extra' }
}}});

export default workflow('id', 'name')
  .add(trigger)
  .to(routeBy
    .onCase(0, branchA)
    .onCase(1, branchB));
```

### Expressions
- `expr('{{ $json.field }}')` — current item field
- `expr('{{ $("NodeName").item.json.field }}')` — specific node reference
- `expr('{{ $now.toISO() }}')` — current timestamp
- `expr('{{ JSON.stringify({ key: $json.value }) }}')` — safe JSON construction

### Credentials
- `credentials: { whatsAppApi: newCredential('WhatsApp account') }`
- `newCredential('Name')` — always use this, never hardcode tokens

### Rules
- Every node MUST have an `output` property with sample data
- Use `alwaysOutputData: true` for nodes that might return 0 items
- Use `executeOnce: true` for nodes that should run once regardless of input count
- Use descriptive node names, not generic ones
