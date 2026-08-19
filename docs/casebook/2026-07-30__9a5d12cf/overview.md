# Install and upgrade agent-skills as part of home install flow

**Status: closed.** Implemented on branch `agent-skills-install`, reviewed,
and merged to `master`; reopened once after trying it out in practice (see
"Follow-up: consolidate into the `skills` component" below), then that
follow-up was itself implemented, reviewed, and merged. Not yet exercised
end-to-end on this machine (`install.sh skills` has never actually been
run) — first real run will create `~/.local/share/dmd/agent-skills` and
exercise the full clone+install+symlink path for the first time.

## Goal

Integrate [ArielHorwitz/agent-skills](https://github.com/ArielHorwitz/agent-skills)
into dmd's installation flow so that its skills are installed and upgraded
automatically whenever the home directory is installed, instead of being
hand-vendored into this repo.

## Context

- `agent-skills` is a separate repo of portable ".agents protocol" skills
  (currently `iac` and `casebook`). It ships its own `install.sh`
  (`./install.sh [skill...] | --list | --upgrade`, default install target
  `~/.agents/skills`, override with `--dest`) and a `fix-claude.sh` for
  creating Claude-Code-compatible symlinks (`fix-claude.sh ~` for global,
  `fix-claude.sh` for project-local).
- dmd used to hand-vendor skills directly under `home/.agents/skills/` —
  commits `57f7c1f` ("WIP casebook skill") and `422abc8` ("WIP iac skill")
  added `casebook` and `iac` there directly. Commit `a715d37` ("Cleanup and
  remove old skills and pre-skill scripts") removed dmd's other hand-rolled
  skills (`discuss`, `handoff`, `investigate`) plus `bin/agents-init.sh`,
  `bin/casebook-cli.py`, and `docs/casebook/agents.md` — i.e. the project is
  actively moving away from vendoring skill content in-repo.
- On disk right now, `~/.agents/skills/` already contains `casebook` and
  `iac` (presumably installed by manually running agent-skills' own
  `install.sh`), alongside `recall` (still dmd-managed via
  `home/.agents/skills/recall`, applied through homux) and some
  pre-existing `discuss`/`handoff`/`investigate`/`skill-creator` directories
  left over from before the cleanup commit (not currently tracked by dmd).
- dmd already symlinks `.claude/skills -> ../.agents/skills` (both at the
  repo root and under `home/.claude/`), which is functionally the same
  bridge that agent-skills' `fix-claude.sh ~` sets up. This overlap needs to
  be reconciled (see open questions).
- Existing dmd conventions relevant to this integration:
  - `install.sh` has one function per installable component
    (`install_packages`, `install_crates`, `install_scripts`, ...,
    `install_home`), gated by CLI component flags, with a `--force` flag to
    continue past warnings.
  - `install_home()` currently just calls `bin/install-home.sh` (which
    itself becomes the installed `install-home` command via
    `install_scripts()`, and is meant to be re-run standalone later, e.g.
    to reapply home config for a different location/hostname — it reads a
    state file at `~/.local/state/dmd/location`).
  - `home/.config/dmd/hooks/post.sh` is a homux post-apply hook (currently:
    reload systemd units) that runs after every `homux apply`, whether
    triggered via `install.sh home` or standalone `install-home`/
    `reload-config` runs.
  - `bin/clonedir.sh` is an existing generic helper for sparse-cloning a
    single directory out of a git repo — a precedent for pulling code from
    an external repo, though it doesn't handle "keep a persistent clone and
    upgrade it" (agent-skills' own `install.sh --upgrade` expects to be run
    from inside a persistent local clone via `git pull`).
  - No existing dmd pattern for maintaining a persistent external git
    clone (fonts are downloaded release archives, checked for existence,
    no upgrade path; paru is built in a throwaway `mktemp -d`).
  - `install.sh` supports `--user-mode` for rootless installs. agent-skills'
    default install target (`~/.agents/skills`) is already rootless, so this
    integration shouldn't need root regardless of mode.

## Open questions (for discussion)

1. **Where does the persistent agent-skills clone live?** Needs a stable
   path to `git pull` from before re-running `install.sh --upgrade`. No
   existing dmd convention for this (candidates: `~/.cache/dmd/agent-skills`,
   `~/.local/share/dmd/agent-skills`).
2. **Which script owns this step?** `install.sh`'s `install_home()`
   (runs only during a full/explicit `install.sh home` or `install.sh all`)
   vs. `bin/install-home.sh` itself (also reachable as the standalone
   `install-home` command, and via the `post.sh` hook path) vs. the
   `post.sh` hook. This determines how often it runs (every homux apply
   vs. only explicit installs) and whether it needs network access on
   every reapply.
3. **Do we still need `fix-claude.sh`?** dmd already maintains its own
   `.claude/skills -> ../.agents/skills` symlinks by hand; running
   agent-skills' `fix-claude.sh ~` on top may be redundant. Decide whether
   to drop dmd's manual symlink in favor of `fix-claude.sh`, or skip
   `fix-claude.sh` entirely and keep the existing symlink.
4. **Does homux's directory sync ever delete extraneous files?** If
   `~/.agents/skills` is ever treated as a homux-managed directory target
   (mirrored), an agent-skills-managed subdirectory living alongside
   `recall` could be wiped. Current coexistence suggests homux only
   overlays tracked files rather than mirroring the whole directory, but
   worth confirming.
5. **Should this be unconditional or gated behind a flag/component?**
   Every other `install.sh` component is opt-in via a letter flag
   (`p`/`c`/`s`/... /`h`). Should agent-skills sync always run as part of
   `h | home`, or get its own flag so it can be skipped (e.g. offline use)?

## Decisions

- **Clone location:** `~/.local/share/dmd/agent-skills`.
- **New dedicated `install.sh` component** (proposed flag `k | skills`,
  function e.g. `install_agent_skills()`): clone the repo if the directory
  doesn't exist yet, otherwise `git pull`. Root-agnostic (plain git
  operations), so it works the same in `--user-mode` — unlike `packages`,
  which is fully skipped without root. This is the *only* place network
  access happens for this integration; it only runs when explicitly
  invoked (`install.sh k` or `install.sh all`), never implicitly.
  - Rejected: folding this into `install_packages()`. That function is
    entirely skipped in `--user-mode` (no root available there), which
    would silently drop the agent-skills sync for user-mode installs even
    though a git clone/pull needs no privilege at all.
  - Rejected: putting it in `install_home()` / `bin/install-home.sh`. See
    below — `install-home` must stay fast and network-free.
- **`bin/install-home.sh`** gains one local, no-network step: from the
  clone dir, run `./install.sh --upgrade` (reinstall into
  `~/.agents/skills`) then `./fix-claude.sh ~` (Claude Code symlink).
  Guarded by an existence check on the clone dir (matching the existing
  `PERMS_DIR`/`POST_HOOK` conditional style in this script), so it's a
  no-op until the new component has run at least once.
  - Why here and not gated by anything else: `install-home` (the
    installed `install-home` command) is invoked frequently and directly
    by the user — notably on a hotkey wired to the location/monitor
    watchdog — specifically because it's supposed to be quick and not
    carry the full installer's overhead. It must stay network-free, so
    the clone/pull cannot live here; only the already-local reinstall
    step belongs in this script. This step re-syncs the installed skills
    against whatever the clone currently has, every time home is applied
    (including hotkey-triggered reapplies), independent of whether a
    fresh clone/pull just happened.
- **Drop dmd's hand-maintained `home/.claude/skills -> ../.agents/skills`
  *and* `home/.claude/CLAUDE.md -> ../.agents/agents.md` symlinks**;
  `fix-claude.sh ~` now owns creating both. Read the actual script
  (`/mnt/black/prog/agent-skills/fix-claude.sh`, a local clone) after the
  fact: it treats these two links as one atomic "bridge `.agents/` to
  `.claude/`" operation via the same idempotent `link_relative` helper
  (leaves anything already present untouched, so this is a no-op on
  machines that already have the symlinks from a prior homux apply).
  Originally only `skills` was dropped and `CLAUDE.md` was left dmd-managed
  — an inconsistent half-measure caught and fixed after re-reading the
  upstream script. (The repo-root `.claude/skills` and `.claude/CLAUDE.md`
  symlinks, used for dmd's own project-local dev tooling, are unrelated
  and untouched.)
- Bundling the clone/pull unconditionally whenever the `k | skills`
  component is selected (no further sub-flag), matching how `install_crates`
  always runs `rustup update || :` and `install_fonts` always attempts its
  downloads when their component flags are passed.

## Implementation

Implemented as described above:

- `install.sh`: new `k | skills` component, `install_agent_skills()`
  clones `AGENT_SKILLS_REPO` into `AGENT_SKILLS_DIR`
  (`~/.local/share/dmd/agent-skills`) if missing, else `git pull`.
  Wired into the component list/help/arg parsing/invocation like every
  other component.
- `bin/install-home.sh`: after the existing `POST_HOOK` step, if
  `AGENT_SKILLS_DIR` exists, runs `./install.sh --upgrade` then
  `./fix-claude.sh ~` from inside it (subshell `cd`, no network).
  No-ops silently if the directory doesn't exist yet (i.e. before
  `install.sh skills` has ever been run).
- Removed the homux-managed `home/.claude/skills` (`-> ../.agents/skills`)
  and `home/.claude/CLAUDE.md` (`-> ../.agents/agents.md`) symlinks —
  `fix-claude.sh ~` now owns creating both. The repo-root `.claude/skills`
  and `.claude/CLAUDE.md` symlinks (dmd's own project-local dev tooling)
  are untouched.
- Documented in `README.md`: new row in the component table, and a new
  bullet in "Making changes" explaining the two-step network/local split.

Not yet done: actually running `install.sh skills` and `install-home` on
this machine to verify end-to-end (first real run will both create
`~/.local/share/dmd/agent-skills` and exercise the `install-home` local
step for the first time).

### Follow-up: expose `fix-claude` as a global command

Ariel wants `fix-claude.sh` (from the agent-skills repo) usable in any
project, not just as part of the home-install flow. `install_scripts()`
in `install.sh` now best-effort copies `$AGENT_SKILLS_DIR/fix-claude.sh`
into the staging dir alongside dmd's own `bin/*` before installing to
`$BIN_TARGET`, so it gets the extension stripped and installed as
`fix-claude` the same way every other script does.

- Chosen over: copying it into dmd's own git-tracked `bin/` (would vendor
  and drift from upstream — the whole point of this case is to stop
  hand-vendoring skill-adjacent content) and over writing directly to
  `$BIN_TARGET` from `install_agent_skills()` (would get clobbered by
  `install_scripts()`'s unconditional `rm -rf $BIN_TARGET` on any
  standalone `install.sh scripts` run, since the two components would
  otherwise both own writes into the same target dir).
- Reordered `skills` to run before `scripts` everywhere (help text, arg
  parsing, `INSTALLATION_COMPONENTS`, function definition order, and the
  final invocation sequence), so a from-scratch `install.sh all` clones
  agent-skills before `install_scripts()` stages `bin/` — `fix-claude` is
  available on the very first run, no self-healing needed.
- `bin/install-home.sh`'s own `./fix-claude.sh ~` invocation still calls
  the copy inside the clone directly (unaffected by whether the global
  `fix-claude` command has been installed yet).

### Follow-up: consolidate into the `skills` component

After using this for a while, Ariel decided he didn't like `install-home`
implicitly doing part of the agent-skills sync on every apply — he'd
rather both the repo sync (clone/pull) *and* the local install
(`./install.sh --upgrade` + `./fix-claude.sh ~`) live entirely inside the
`skills` component, and `install-home` know nothing about agent-skills at
all.

This reverses the earlier "separate concerns" decision above (network step
in `install.sh`, local step in `install-home.sh`) in favor of a simpler
single-owner model: `install_agent_skills()` now does clone-or-pull *and*
the local reinstall/symlink step, all in one function, only ever run
explicitly via `install.sh skills` (or `all`). `bin/install-home.sh` is
back to knowing nothing about agent-skills — no `AGENT_SKILLS_DIR`, no
conditional block.

Net effect: `install-home` (including the hotkey-triggered path) is simpler
and has one less thing to reason about, at the cost of skills no longer
auto-resyncing on every home apply — now only on an explicit
`install.sh skills`.
