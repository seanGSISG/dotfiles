<mcp_tools>
<behavior>
Use these tools proactively without explicit user requests. Match tool to need automatically.
</behavior>

<tool name="context7" trigger="library_docs">
Library/API documentation, code generation, setup/configuration steps.
Use for: Framework questions, API references, implementation patterns.
</tool>

<tool name="grep" trigger="github_code">
Real-world code examples from 1M+ public GitHub repositories.
Use for: Specific repository questions, production code patterns, implementation examples.
</tool>

<tool name="exa_websearch" trigger="broad_search">
# NOTE: Exa is currently down and not working.  Use your native web_search and web_fetch tools instead
Search billions of GitHub repos, docs, StackOverflow for token-efficient context.
Use for: Best practices, troubleshooting, cross-platform solutions.
</tool>

<selection_priority>
1. User mentions specific library/framework → context7
2. User references GitHub repo or wants real code → grep
3. User needs broad research/troubleshooting → exa
4. Complex queries → combine tools as needed
</selection_priority>
</mcp_tools>
