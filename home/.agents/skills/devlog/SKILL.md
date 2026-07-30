---
name: devlog
description: Append a prose entry to a dev log.
argument-hint: "[path to devlog.md] How long did you work, and anything to emphasize?"
disable-model-invocation: true
---

A dev log is a continuous, prose record of work — useful to a range of audiences such as (but not limited to) future me, collaborators, supervisors, stakeholders. It may be a personal log spanning everything I work on, or a project-local log that lives in and is scoped to that project (and may be checked into that project's version control). Update today's entry to reflect the work from this session.

## Which log file

If a path is given as part of the invocation, use that file. Otherwise, ask which log to use rather than guessing or creating a new one unprompted.

If the file doesn't exist yet, before writing the first entry, ask who the intended audience is. The answer sets the tone: how technical, verbose, or broad the prose should be. Record it as a short italicized note at the very top of the new file, above the first `### YYYY-MM-DD` heading, e.g. `_Audience: internal engineering team — technical, terse, results-focused._` On later invocations, read that note (if present) to calibrate tone instead of asking again — treat it as a standing assumption, not something to reconfirm every session.

## How to log

- Write in **prose**, matching the style of the existing entries (they are your examples) and the audience note at the top of the file, if present. No bullet points. Start each session's entry with a short **bolded title**, then the prose, e.g. `**Graceful shutdown** — fixed the live runtime's signal handlers…`.
- Find today's `### YYYY-MM-DD` heading, or create it at the end of the log if this is the day's first entry (entries are chronological, oldest-first). Add your work as its own paragraph(s) under that heading.
- **Append-only across sessions.** Other entries under today's date, and every earlier day, were written by other sessions — never reword, merge, or delete them.
- **Merge within your own session.** I may invoke this skill several times in one session. On the first call for the day, write a new entry; on later calls *within the same session and on the same day*, revise the entry you already wrote to fold in the new work, rather than adding a second one.
- **Size the entry by time spent** — budget roughly **one short sentence per hour worked**, where *short* means ~15–25 words (≤1h → one sentence; ~2h → two; ~4h → a short paragraph; a full day → at most two). When I give a time, that time sets the size; only infer from scope when I give none. It's a **cap, not a target**: you'll have far more to say than fits. When a detail doesn't fit, **drop the whole point — never smuggle it in as an extra clause.** No clause-stacking, no colon-lists, no "and… and…" run-ons. Stay proportional across tasks (one big task and ten small ones get about the same total space). Don't state the time in the entry.
- Log the results of the work too, not just the activity — e.g. that I ran simulations to answer a question, and optionally the answer that was found.
