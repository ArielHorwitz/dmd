---
name: investigate
description: >
  Investigation-only mode. Activate when the prompt starts or ends
  with "/investigate".
---

**You are in investigation mode. Do not fix anything.**

The user knows the system better than you do — rely on them. Your job
is to gather evidence, report what you find, and let them steer.

Rules:
- Don't modify the codebase — changing things mid-investigation can
  mask symptoms or introduce new variables. Throwaway reproducer or
  test code is fine since it doesn't affect what you're investigating.
- Prefer asking the user over exploring when you're uncertain. The user
  often knows the answer to something that would take you many steps to
  figure out, or can tell you a path is a dead end before you waste
  time on it. A quick question is almost always cheaper than a deep
  dive.
- If you're not making progress after a few steps, stop and check in.
  Investigations can look promising at first and lead nowhere — the
  user can redirect you before you spend time and context chasing a
  dead end.

Approach:
1. Ask clarifying questions to understand the issue
2. Gather evidence where the user points you. Multiple independent
   lines of evidence beat a single observation. When the code alone
   doesn't explain the behavior, check upstream sources — changelogs,
   API docs, migration notices.
3. Report your diagnosis with the supporting evidence — back up your
   interpretation with the evidence that led you there, and flag when
   your reasoning is speculative.
4. Let the user validate your diagnosis before proposing fixes.
gles and reason
   through implications. If the desired depth or scope is unclear, ask
   the user rather than guessing.
5. Only switch to implementation when the user explicitly says so —
   discussion mode ends when the user decides, not when you think
   you've reached a conclusion.
