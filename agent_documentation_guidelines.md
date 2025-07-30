# Agent Documentation Guidelines

Summary: Concise rules for creating AI-optimized technical documentation

## Core Principles

- **Information Density**: Every line should convey new, relevant information
- **Structured Data**: Use consistent, predictable formats. Prefer lists, tables, and structured markup over prose
- **Explicit References**: Always provide exact paths, line numbers, or anchors
- **Semantic Clarity**: Use consistent terminology throughout. Define terms once in a glossary and never use synonyms
- **Unambiguity**: Every statement should have a single, clear interpretation
- **Deterministic Ordering**: List items alphabetically or numerically

## Authorial Style

The preferred authorial style is direct, pragmatic, and code-centric.

- **Code-First Explanations**: Prioritize code examples. Every major point or concept should be immediately illustrated with a concise code snippet. The text should serve to explain the code, not the other way around.

- **Emphasis Through Structure**: Use `###` headings for sections and `backticks` for code-related terms (e.g., `NSLock`). Avoid using bolding for emphasis.

- **Pragmatic Tone**: Maintain a practical, peer-to-peer tone. Include "words of caution" or pragmatic advice where appropriate.

- **Use Asides for Detail**: For tangential information or deeper examples that would clutter the main text, use Markdown blockquote admonitions. This keeps the primary flow clean while providing depth.

  > [!NOTE]
  > This is an example of an aside. It provides extra information and is rendered in a distinct box on platforms like GitHub.

## Guidelines

- **File Size**: Keep documents under 500 lines (approximately 500-1000 tokens)
- **Anchors Over Line Numbers**: Use stable anchors (`#search-api`) instead of line numbers
- **One Topic Per File**: Each document should cover exactly one concept, component, or workflow
- **No Forward References**: Never reference content that appears later in the document
- **Bidirectional Links**: For each component, list both what it depends on and what depends on it

## Anti-Patterns to Avoid

- **Narrative Style**: "Let's explore how the chunker works..." → "Chunker splits Swift files into semantic units."
- **Redundant Sections**: Don't repeat information across documents. Link instead.
- **Vague References**: "As mentioned earlier" → "See glossary.md#embedding"
- **Mixed Concerns**: Don't combine API reference with tutorials in the same document.
- **Assumption of Context**: Each document should be understandable in isolation.
- **Decorative Headers**: Headers should be functional labels, not clever phrases.

## Document Structure

### File format

Every document must:
- be formatted as markdown (except index.rst)
- begin with a title and a one line summary

Example:
```markdown
# EmbeddingsDB overview

Summary: Manages vector embeddings storage and similarity search operations
```

### Reference Formats

```markdown
# Good References
- File + anchor: `chunker/api.md#initialization`
- Code location: `repo://Sources/Chunker/Chunker.swift#L42-L95`
- Config key: `config://chunker.maxLineCount`
- Error code: `error://CHUNK_001`

# Avoid
- "See the chunking documentation"
- "As described above"
- "In the previous section"
```

## Special files

These are files that are usually useful. Consider creating them at your discretion.

### index.rst

- It is written in restructuredText format
- It contains an Overview section that provides a general idea of the project.
- It contains a visual tree with one-line summaries for each documentation file.

Example of visual tree

```
docs/
├── manifest.json                    # Document registry and navigation map
├── glossary.md                      # Canonical term definitions
├── components/
│   ├── chunker/
│   │   ├── overview.md              # Component purpose and architecture
│   │   ├── api.md                   # Public API reference
│   │   └── examples.md              # Usage patterns and code samples
│   └── embeddings/
│       ├── overview.md              # Component purpose and architecture
│       └── api.md                   # Public API reference
└── workflows/
    ├── setup.md                     # Initial configuration steps
    └── common_tasks.md              # Task-oriented guides
```

### glossary.md

```markdown
# Glossary

- **Chunk**: Semantic unit of source code, typically <500 lines
- **Embedding**: Vector representation of code semantics
- **MCP**: Model Context Protocol for AI assistant integration
```

### dependencies.md

```markdown
# Dependencies

Chunker -> EmbeddingsDB: produces chunks
EmbeddingsDB -> ExplorerServer: provides search API
ExplorerServer -> MCPClient: serves context

# Dependency Graph

<Same as above but in mermaid format>
```

### FAQ.md

```markdown
# Example Queries

Q: "How do I create embeddings for a Swift project?"
A: Read: workflows/setup.md#swift-project, embeddings/api.md#batch-process

Q: "What causes CHUNK_001 error?"
A: Read: troubleshooting/errors.md#CHUNK_001

# Troubleshooting Patterns

Error: "Failed to load CoreML model"
Cause: Missing model file or incompatible macOS version
Solution: embeddings/setup.md#coreml-requirements, models/download.md

# Anti-Example (What NOT to do)

Q: "How does the chunker work?"
A: The chunker uses advanced parsing... [WRONG - too vague]
A: Read: chunker/architecture.md#algorithm [CORRECT - specific reference]
```
