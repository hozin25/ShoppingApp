---
description: Initialize 
model: opus
---

# Initialize Codebase Documentation

Research each subfolder inside `src/` using subagents, create `summary.md` files for each folder, and generate a top-level `agent.md` file.

## Task Overview

1. Identify all subfolders in `src/` (including nested subfolders)
2. For each subfolder, use a subagent in "Explore" mode to research it
3. Create `summary.md` in each subfolder based on subagent findings
4. Create top-level `agent.md` that summarizes everything and references subfolder summaries

## Step 1: Discover All Subfolders

List all subfolders in `src/` directory. Include nested subfolders.

## Step 2: Research Each Subfolder with Subagent

For EACH subfolder (including nested ones), spawn a subagent in "Explore" mode:

```subagent
Mode: Explore
Task: Research and analyze the `src/{subfolder_path}/` directory. Provide comprehensive analysis covering:

1. **Purpose**: What is this module/folder responsible for?
2. **Key Functions**: Important functions, their signatures, and purposes
3. **Data Structures**: Key data structures, types, and schemas
4. **Patterns**: Common patterns, conventions, and architectural decisions
5. **Integration**: How does this module integrate with the rest of the codebase?

Focus on understanding:
- Clojure/ClojureScript code structure and conventions
- How this folder fits into the overall application architecture
- Key responsibilities and boundaries
- Important implementation details
```

## Step 3: Create summary.md for Each Folder

After receiving subagent research output for each folder, create `src/{subfolder_path}/summary.md` with this structure:

```markdown
# {Subfolder Name} Summary

## Overview
[Brief description of the folder's purpose and responsibility]

## Structure
[List of files and their purposes]

## Key Components

### Namespaces
[Main namespaces and their responsibilities]

### Key Functions
[Important functions and their purposes]

### Data Structures
[Key data structures and types]

## Dependencies
- **Depends on**: [What this module requires]
- **Used by**: [What depends on this module]

## Patterns & Conventions
[Common patterns, conventions, and architectural decisions]

## Notes
[Important implementation details or architectural decisions]
```

## Step 4: Create Top-Level AGENTS.md

After ALL subfolder summaries are created, generate `AGENTS.md` in the project root:

```markdown
# Codebase Overview

## High-Level Architecture
[Summary of the entire codebase structure and architecture]

## Module Map
[Overview of major modules and their relationships]

## Architecture Patterns
[Key architectural patterns and decisions across the codebase]

## Technology Stack
[Summary of technologies used: Clojure, ClojureScript, PostgreSQL, Shadow-CLJS, Replicant, etc.]
```

## Important Notes

- Use **"Explore" mode** subagent for faster codebase exploration
- Ensure consistent format across all `summary.md` files
- Top-level `AGENTS.md` should provide high-level overview without duplicating detailed information
- Include nested subfolders as separate entries with their own summaries
- Focus on understanding Clojure/ClojureScript patterns and the application's architecture
