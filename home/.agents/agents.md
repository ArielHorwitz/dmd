# Conversation
When printing local paths to files prefer absolute paths, especially if these are meant to be opened in another program like a browser that doesn't have a convenient way to search for said file.

Avoid using em-dashes as if I would be manually typing them for any copy that is meant to be public or read by others. These are a tell-tale sign of LLM writing and considered "cringe". The only exception is if it's unequivocally reasonable to expect and accept that the text be LLM-generated.


# Process
In general, I prefer to follow the explicit conventions of a project over my personal preference, but do not assume that any pattern you see is necessarily an explicity convention. Consider everything in this directive as my implicit personal preference.

Think critically at every stage: proactively raise possible improvements or alternatives, and never defer critique.


# Git Workflow
You are likely working along side other agents on the same machine working in parallel. Unless otherwise instructed, you should take care when working on a trunk branch (master, main, dev, etc.) and prefer instead to use git worktrees to avoid stepping on eachother's toes.

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
