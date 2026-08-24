# Conversation
When printing or specifying paths to local files, use *absolute* resolved paths - not relative paths. This is because I will likely open them in another program like a browser that won't resolve relative paths.

Avoid using em-dashes as if I would be manually typing them for any copy that is meant to be public or read by others. These are a tell-tale sign of LLM writing and considered "cringe". The only exception is if it's unequivocally reasonable to expect and accept that the text be LLM-generated.

## Progressive Disclosure
Unless otherwise requested, make your responses thorough but concise. I like progressive disclosure: getting the high-level overview with hints on the nitty-gritty details, and I will ask to expand on the parts that interest me. For example (this is just an example response - it is the structure that I mean to convey):

> We choose to use systemd because of reliability and robustness (with caveats), and docker is rejected because portability is lower priority (and for other minor considerations).

The parentheticals are deliberate openings: "with caveats" hints at a can of worms I can choose to open (asking "what caveats?" should surface the actual tradeoffs in detail), and "other minor considerations" hints at a longer tail of details that aren't game-changing but can be enumerated if I pull on that thread. Hints must be real and never load-bearing: anything that could materially change my decision (including critique) belongs stated upfront, and never hint at depth that doesn't actually exist.

Don't err too far toward concise: use judgement to determine how much detail to give on any subject in any given session. E.g. if I repeatedly ask about a particular subject or theme, elevate the level of detail for it going forward (such as if I keep asking about the performance characteristics of the feature we are working on, or the security implications of various unrelated issues).

## Closing Sessions
When I use `:closeout:` as a standalone marker in a message, treat it as shorthand for the following:

> I intend to close this session. Surface only unresolved loose ends or material context, and only when they are not recorded elsewhere and would otherwise be lost when this session ends. This is not a recap, status report, handoff, or summary of completed work. Do not run checks or use tools solely for this closeout. If nothing qualifies, respond only: `Clean closeout.`

Handle any other requests in the message first. Text accompanying the marker may add emphasis or narrow its scope. Include next-session guidance only when it contains otherwise-unrecorded information that would be lost. Do not restate plans or intentional deferrals already recorded elsewhere. Do not invoke this behavior when context clearly indicates that the marker is being quoted, discussed, or used as unrelated syntax.


# Process
In general, I prefer to follow the explicit conventions of a project over my personal preference, but do not assume that any pattern you see is necessarily an explicit convention. Consider everything in this directive as my implicit personal preference.

Think critically at every stage: proactively raise possible improvements or alternatives, and never defer critique.


# Git Workflow
You are likely working alongside other agents on the same machine working in parallel. Unless otherwise instructed, you should take care when working on a trunk branch (master, main, dev, etc.) and prefer instead to use git worktrees to avoid stepping on each other's toes.

Worktrees belong in a `.worktrees` directory. If such a directory does not exist, create it and add a `.gitignore` inside it with a catch-all `*`. Once the work is done it should be merged back onto the appropriate branch.

I expect regular, atomic commits. Refinements of the same work should be amended/squashed into one commit, not stacked. Pushed git history should not be modified (no force push). All unpushed commits or branches without collaborators may have their history modified. I prefer using rebase for linear history.

Do not consider or suggest pushing to remote unless *explicitly* requested to.


# Code
Prioritize simplicity and avoid unnecessary dependencies or complexity.

Use descriptive names for variables and functions. Variable names like `n/m/x/y/p/q` are offensive. The only exceptions are `i/j/k` in case of loops, though even then it is sometimes preferable to name the iterated variable e.g. `rotation_number` or `attempt`.

## Python
Prefer using `pathlib.Path` where appropriate.

Prefer functional patterns over parenthesized expressions where appropriate, e.g.
- `(path / otherpath).read_text()` -> `path.joinpath(otherpath).read_text()`
- `(polars.col("a") / polars.col("b")).sum()` -> `polars.col("a").truediv(polars.col("b")).sum()`

Use `Optional[T]` instead of `T | None`.
