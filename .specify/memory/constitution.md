<!--
Sync Impact Report
- Version change: 0.0.0 (uninitialized template) → 1.0.0
- Bump rationale: MAJOR. Initial ratification. All placeholder tokens replaced
  with concrete principles for this personal Nix Darwin configuration.
- Principles defined (5):
    I.   Declarative Reproducibility (NON-NEGOTIABLE)
    II.  Pinned & Deliberate Inputs
    III. Nix First, Homebrew Only Where Necessary
    IV.  Determinate-Compatible Daemon Boundary
    V.   Build Before Switch
- Sections added:
    Additional Constraints (single-user / single-machine scope, platform pin)
    Development Workflow (change → review → build → switch → rollback)
    Governance
- Sections removed: none
- Templates checked:
    .specify/templates/plan-template.md      — ✅ no changes (Constitution Check
                                                section is meant to be populated
                                                per-feature by /speckit-plan;
                                                principles defined here are
                                                what it gates against)
    .specify/templates/spec-template.md      — ✅ no changes (generic; no
                                                principle-specific scaffolding)
    .specify/templates/tasks-template.md     — ✅ no changes (generic)
    .specify/templates/checklist-template.md — ✅ no changes (generic)
    .specify/templates/commands/             — N/A (directory does not exist)
    CLAUDE.md                                — ✅ no changes (defers to current
                                                plan; no stale principle refs)
- Deferred TODOs: none
-->

# MacBook Nix Darwin Configuration Constitution

This constitution governs `flake.nix` and any modules it imports for the
personal Nix Darwin configuration of host `macbook` (user `mlieberman`,
platform `aarch64-darwin`). It applies to every change touching the flake,
its lockfile, home-manager modules, or any helper scripts that produce
inputs consumed by `darwin-rebuild`.

## Core Principles

### I. Declarative Reproducibility (NON-NEGOTIABLE)

All persistent system state — packages, fonts, shell config, GUI apps, taps,
casks, fonts, dotfiles managed by home-manager — MUST be expressed in the
flake (or a module it imports). Imperative side-channels are forbidden:

- No ad-hoc `brew install`, `brew tap`, or `brew cask install`.
- No `nix-env -i` / `nix profile install` for durable tools.
- No hand-edited dotfiles in `$HOME` for anything home-manager already owns.

**Rationale**: The single value proposition of this repository is that
`darwin-rebuild switch --flake .#macbook` on a fresh machine produces the
working environment. Every imperative shortcut erodes that guarantee and
turns a recoverable configuration into an undocumented snowflake. One-off
experimentation is fine in throwaway shells (`nix shell nixpkgs#...`); it
becomes part of the system only after it lands in the flake.

### II. Pinned & Deliberate Inputs

`flake.lock` MUST be committed. Input updates are explicit acts, not drive-by
side effects:

- Use `nix flake update` (all inputs) or `nix flake lock --update-input <name>`
  (single input) as a deliberate commit, separate from feature changes.
- `nixpkgs` is pinned via `nixpkgs-unstable` and propagated to `darwin` and
  `home-manager` via `inputs.nixpkgs.follows = "nixpkgs"`. Any new input MUST
  follow the same pin unless it intentionally tracks its own channel —
  intentional drift requires a comment in `flake.nix` explaining why.
- A lockfile bump MUST be accompanied by a successful `darwin-rebuild build`
  before the commit is merged.

**Rationale**: Floating inputs make "it worked yesterday" unfalsifiable.
Mixed input/feature commits make rollback a guessing game. Keeping bumps
isolated keeps `git bisect` and `darwin-rebuild --rollback` useful.

### III. Nix First, Homebrew Only Where Necessary

When adding a package, the order of preference is:

1. `environment.systemPackages` from `nixpkgs` (or a user-facing
   home-manager `programs.*` module).
2. `homebrew.brews` — only when nixpkgs lacks the package on `aarch64-darwin`,
   the nixpkgs build is broken on darwin, or the tool integrates with macOS
   services in ways the Nix store cannot (e.g., `yabai`, `skhd`).
3. `homebrew.casks` — for proprietary GUI applications that ship as `.app`
   bundles and are not available (or kept current) in nixpkgs.
4. `homebrew.taps` — only as a dependency of a brew or cask above, never as
   speculative inventory.

Each Homebrew entry SHOULD be justifiable against this hierarchy on review.
A package that lands in Homebrew is a candidate to migrate to nixpkgs the
next time someone looks at it.

**Rationale**: Homebrew is necessary on macOS but it is the escape hatch,
not the default. Mixing freely makes "where does `foo` come from?" a quiz
and undermines the reproducibility claim of Principle I.

### IV. Determinate-Compatible Daemon Boundary

This system uses the Determinate Nix installer to manage the `nix` daemon.
Consequently:

- `nix.enable = false;` in nix-darwin MUST remain set. nix-darwin is not
  allowed to manage the daemon, `/etc/nix/nix.conf`, or the Nix store.
- `nix.settings` may be set for non-daemon concerns (e.g.,
  `experimental-features = [ "nix-command" "flakes" ]`) provided they do
  not conflict with what the Determinate installer writes.
- Any future change that flips `nix.enable` to `true`, or otherwise re-claims
  daemon management, is a MAJOR governance change and requires updating this
  constitution before merging.

**Rationale**: Two systems fighting over `/etc/nix/nix.conf` is a known
foot-gun and was the reason for the current split. Encoding the boundary
here prevents a future "small cleanup" from re-introducing the conflict.

### V. Build Before Switch

System changes follow build-then-switch, never switch-blind:

- `darwin-rebuild build --flake .#macbook` MUST succeed locally before
  running `switch`.
- Uncommitted working-tree changes SHOULD be committed (or stashed) before
  `switch`, so the activated generation corresponds to an identifiable
  commit and `darwin-rebuild --rollback` has a clear meaning.
- If `switch` produces a broken environment (login shell, window manager,
  editor unusable), the first response is `darwin-rebuild --rollback`, not
  imperative repair on the live system.

**Rationale**: A failed `switch` on a personal laptop can cost an
afternoon. `build` catches the same evaluation and most build failures
without touching the running system, at near-zero cost. Tying generations
to commits is what makes `--rollback` and `git bisect` complementary.

## Additional Constraints

- **Platform**: `aarch64-darwin` only. Cross-platform abstraction is out of
  scope; this flake is not intended to configure Linux or `x86_64-darwin`
  machines.
- **Host & user**: a single `darwinConfigurations."macbook"` for user
  `mlieberman`. Multi-host or multi-user generalization is a deliberate
  future change, not an accidental one — `system.primaryUser` and
  `users.users.mlieberman` are load-bearing and must be updated together.
- **State versions**: `system.stateVersion` and `home.stateVersion` are
  compatibility anchors. They MUST NOT be bumped opportunistically; bump
  only when intentionally adopting new defaults and after reading the
  release notes for the target version.
- **Unfree packages**: `nixpkgs.config.allowUnfree = true;` is accepted as a
  pragmatic necessity for this personal machine. License obligations for
  any unfree package added still apply.

## Development Workflow

1. **Change**: Edit `flake.nix` (or the relevant module) for the intended
   addition / removal / reconfiguration.
2. **Format & sanity-check**: Run `nixpkgs-fmt flake.nix` (available in the
   current `systemPackages`); resolve obvious evaluation errors with
   `nix flake check` or `darwin-rebuild build`.
3. **Build**: `darwin-rebuild build --flake .#macbook`. Do not proceed
   until this is clean.
4. **Commit**: One logical change per commit; lockfile updates kept in
   their own commit (Principle II).
5. **Switch**: `darwin-rebuild switch --flake .#macbook`.
6. **Verify**: Open a fresh shell and exercise the affected tool / module.
   If anything load-bearing (shell, editor, window manager) is broken,
   `darwin-rebuild --rollback` immediately and investigate from the
   previous generation.

For feature-style work driven by the `.specify/` flow, the same gates
apply: the `/speckit-plan` Constitution Check MUST verify the proposed
change is consistent with every principle above, and any deviation MUST be
recorded in that plan's Complexity Tracking with explicit justification.

## Governance

- This constitution supersedes ad-hoc conventions for any change to the
  flake, its modules, or `flake.lock`.
- **Amendments**: edit `.specify/memory/constitution.md` directly, update
  the version line and the Sync Impact Report comment at the top, and
  commit the change alongside (or before) the change it enables.
- **Versioning policy** (semantic):
  - **MAJOR**: removing a principle, redefining one in a backward-
    incompatible way, or fundamentally changing the governance model.
    Example: re-enabling `nix.enable` (Principle IV).
  - **MINOR**: adding a new principle, or materially expanding an existing
    one with new MUSTs.
  - **PATCH**: wording clarifications, typo fixes, formatting, or
    non-semantic refinements.
- **Compliance review**: every PR (or local change reviewed before
  `switch`) MUST be sanity-checked against the five principles. Violations
  are either fixed before merge or recorded as justified deviations in the
  relevant plan's Complexity Tracking — silent violations are not allowed.

**Version**: 1.0.0 | **Ratified**: 2026-05-16 | **Last Amended**: 2026-05-16
