---
name: lsp-code-navigator
description: IDE-like code navigation and refactoring using Language Server Protocol for semantic understanding. Use when navigating complex codebases, refactoring symbols across files, tracing type definitions, or understanding symbol relationships. Triggers on refactoring tasks, symbol renaming, cross-file navigation, or type investigation.
---

# LSP Code Navigator

Use Language Server Protocol operations for precise, semantic code understanding instead of text-pattern matching.

## LSP Capabilities

| Operation | Purpose | Use When |
|-----------|---------|----------|
| `goToDefinition` | Jump to symbol definitions | Finding where a function/class/type is defined |
| `findReferences` | Locate all usages of a symbol | Before renaming, understanding impact of changes |
| `hover` | Get type info and documentation | Verifying signatures, understanding parameters |
| `documentSymbol` | List all symbols in a file | Getting an overview of file structure |
| `workspaceSymbol` | Search symbols across project | Finding symbols by name globally |
| `goToImplementation` | Find interface implementations | Tracing concrete implementations of abstractions |
| `prepareCallHierarchy` | Get call hierarchy at position | Understanding function/method relationships |
| `incomingCalls` | Find callers of a function | Impact analysis before modifying a function |
| `outgoingCalls` | Find functions called by a function | Understanding dependencies of a function |

## Refactoring Workflow

1. **Analyze**: Use `findReferences` to understand all usages before modifying
2. **Verify**: Use `hover` to confirm type information and signatures
3. **Trace**: Use `goToDefinition` to understand implementation details
4. **Change**: Make modifications incrementally
5. **Validate**: Run diagnostics, then lint and test

## Best Practices

- Always analyze references before renaming or moving symbols
- Check diagnostics after each significant code change
- Use `goToDefinition` to understand implementation before modifying
- For cross-package changes, trace dependencies through imports
- Prefer LSP semantic navigation over grep-based text search for symbols

## Monorepo Considerations

When refactoring across package boundaries:

- Trace imports across packages with `findReferences`
- Check `tsconfig.base.json` path aliases when symbols span packages
- Verify changes don't break module boundaries

## Language Support

Configured LSP plugins (in `.claude/settings.json`):
- **TypeScript/JavaScript**: `typescript-lsp@claude-plugins-official`
- **Python**: `pyright-lsp@claude-plugins-official`

## Prerequisites

Install the LSP plugins (one-time per machine) — run your project's LSP setup command, then restart Claude Code for the plugins to take effect.
