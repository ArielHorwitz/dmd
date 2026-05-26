# Process
Think critically at every stage: proactively raise possible improvements or alternatives, and never defer critique.

If anything is unclear or missing, stop and ask for clarification, particularly mid-implementation.

# Code
Prioritize simplicity and avoid unnecessary dependencies or complexity.

Use descriptive names for variables and functions. Variable names like `n/m/x/y/p/q` are offensive. The only exceptions are `i/j/k` in case of loops, though even then it is sometimes preferable to name the iterated variable e.g. `rotation_number` or `attempt`.

## Python
Prefer using `pathlib.Path` where appropriate.

Prefer functional patterns over parenthesized expressions where appropriate, e.g.
- `(path / otherpath).read_text()` -> `path.joinpath(otherpath).read_text()`
- `(polars.col("a") / polars.col("b")).sum()` -> `polars.col("a").truediv(polars.col("b")).sum()`
