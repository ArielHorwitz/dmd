---
name: worktree
description: Work inside a dedicated git worktree.
argument-hint: "Which worktree to use (description or an exact name)"
disable-model-invocation: true
---

For the rest of this session, work inside a dedicated git worktree rather than the main one, unless explicitly requested otherwise. Defer creating the worktree until you're about to change a file on disk.

The argument identifies which worktree to use — an exact name, or a description that points at one. Resolve it:

- If it matches an existing worktree, use that one.
- If no matching worktree exists, create it (follow existing conventions, if any).
- If it is ambiguous between existing worktrees, ask which to use rather than guessing.
