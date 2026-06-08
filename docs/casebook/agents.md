# Casebook

This directory is a **casebook** — a collection of cases, each representing a
bounded unit of work (investigation, brainstorm, feature, design, etc.).

## Structure

```
docs/casebook/
  agents.md          # this file
  YYYY-MM-DD__hex/   # case directory
    case.toml        # case metadata
    intro.md         # the user's original writeup (do not modify)
    overview.md      # evolving summary of the case (keep updated)
    ...              # any other files: reports, designs, ADRs, transcripts, etc.
```

## Working with cases

- New cases are created by the user via `casebook new` — agents should
  work within existing cases rather than creating new ones.
- Start by reading `case.toml` for the case metadata: title, status, keywords,
  and any other fields that have been added. Then list the case directory to see
  what files are available — you may consider reading whichever files are
  relevant to your task.
- The `title` field in `case.toml` is the primary way cases are discovered. It
  should capture the full scope of the case so that anyone looking for
  information from this case can find it. New cases may have a default title of
  "Unnamed case" — update it early and refine it as the scope becomes clearer.
- Update `case.toml` as the work evolves. The `status` field is typically `open`
  or `closed`, but other values like `blocked` or `paused` are fine. Update
  `keywords` to help future sessions find relevant cases. Other fields like
  `description` or `summary` can be added freely.
- Case directories are for documentation and historical context — analysis,
  reports, decisions, designs, transcripts, etc. Code typically belongs in the
  source tree, not in the case directory.
- Use highly descriptive filenames so that an agent can understand what a file
  contains by reading its name alone. Prefer names like
  `websocket-reconnection-backoff-strategy.md` or
  `user-dashboard-layout-accessibility-review.md` over vague names like
  `report.md` or `notes.md`.
- Cases typically include an `intro.md` with the user's original writeup. This
  should not be modified — it is the original context, kept for posterity.
- Cases typically include an `overview.md` as a living summary of the case.
  Update this as the case evolves to keep it useful for future sessions.
- The casebook includes past cases that may provide historical context for
  design decisions, prior investigations, or previously considered approaches.
  Use `casebook list` to browse cases and `casebook show <id>` for details.
