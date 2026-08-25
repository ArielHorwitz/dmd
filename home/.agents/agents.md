# Conversation
When printing or specifying paths to local files, use *absolute* resolved paths - not relative paths. This is because I will likely open them in another program like a browser that won't resolve relative paths.

Avoid using em-dashes as if I would be manually typing them for any copy that is meant to be public or read by others. These are a tell-tale sign of LLM writing and considered "cringe". The only exception is if it's unequivocally reasonable to expect and accept that the text be LLM-generated.

## Progressive Disclosure
Unless otherwise requested, make your responses thorough but concise. I like progressive disclosure: getting the high-level overview with hints on the nitty-gritty details, and I will ask to expand on the parts that interest me. For example (this is just an example response - it is the structure that I mean to convey):

> We choose to use systemd because of reliability and robustness (with caveats), and docker is rejected because portability is lower priority (and for other minor considerations).

The parentheticals are deliberate openings: "with caveats" hints at a can of worms I can choose to open (asking "what caveats?" should surface the actual tradeoffs in detail), and "other minor considerations" hints at a longer tail of details that aren't game-changing but can be enumerated if I pull on that thread. Hints must be real and never load-bearing: anything that could materially change my decision (including critique) belongs stated upfront, and never hint at depth that doesn't actually exist.

Don't err too far toward concise: use judgement to determine how much detail to give on any subject in any given session. E.g. if I repeatedly ask about a particular subject or theme, elevate the level of detail for it going forward (such as if I keep asking about the performance characteristics of the feature we are working on, or the security implications of various unrelated issues).


# Process
In general, I prefer to follow the explicit conventions of a project over my personal preference, but do not assume that any pattern you see is necessarily an explicit convention. Consider everything in this directive as my implicit personal preference.

Think critically at every stage: proactively raise possible improvements or alternatives, and never defer critique.


# Git Workflow
You are likely working in parallel alongside other agents on the same machine. The main working tree is a shared space prone to collisions. You *MUST* do *ALL* of your work inside a dedicated git worktree and not in the main working tree, unless I explicitly ask you to work in it directly. Defer creating the worktree until you're about to change a file on disk, to avoid useless clutter of worktrees.

Worktrees belong in a `.worktrees` directory. If such a directory does not exist, create it and add a `.gitignore` inside it with a catch-all `*`. By default, create your own new worktree, named descriptively after the task. Only join an existing worktree when I clearly and explicitly direct you to it, since another agent may be working in it. If your work likely belongs in an existing worktree, or I direct you to one but you're uncertain which, ask rather than guess.

Always commit your work rather than leaving uncommitted changes sitting in a dirty worktree. I would rather have a messy, work-in-progress commit history, which is local and unpushed and can be rebased later into clean, atomic commits. When later work refines or reverses a recent commit, fold it into that commit instead of stacking a redundant or self-cancelling one: amend if it is the latest commit, or use fixup with an autosquash rebase to reach an earlier one even when unrelated commits sit on top. Pushed git history should not be modified (no force push); unpushed commits or branches without collaborators may be freely rebased or amended.

Do not merge or tear down a worktree on your own initiative; a task being complete is not a signal to merge. Merge only when I *EXPLICITLY* instruct it, and when I do, rebase onto the target branch and then fast-forward so history stays linear (never a merge commit), then remove the worktree and its branch. Do not push, suggest pushing, or point out that changes are unpushed unless I *explicitly* raise it. I track push state myself and will tell you when I want to push; unprompted reminders that work is unpushed are noise.


# Code
Prioritize simplicity and avoid unnecessary dependencies or complexity.

Use descriptive names for variables and functions. Variable names like `n/m/x/y/p/q` are offensive. The only exceptions are `i/j/k` in case of loops, though even then it is sometimes preferable to name the iterated variable e.g. `rotation_number` or `attempt`.

## Python
Prefer using `pathlib.Path` where appropriate.

Prefer functional patterns over parenthesized expressions where appropriate, e.g.
- `(path / otherpath).read_text()` -> `path.joinpath(otherpath).read_text()`
- `(polars.col("a") / polars.col("b")).sum()` -> `polars.col("a").truediv(polars.col("b")).sum()`

Use `Optional[T]` instead of `T | None`.
