# Feature Specification: Modular Nix Configuration Layout

**Feature Branch**: `001-modular-nix-config`

**Created**: 2026-05-20

**Status**: Draft

**Input**: User description: "I want to build out this repo so I can include all my eventual nix stuff over time in an easy and straightforward way."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a new package without editing the monolith (Priority: P1)

As the sole maintainer of this personal Nix Darwin configuration, when I
want to add a new tool (e.g. a new CLI binary I just discovered), I open one
small focused file dedicated to that category of packages, add the entry,
build, and switch. I do not scroll through a 200+ line `flake.nix`, and I
do not risk merge-style conflicts inside a single giant attrset.

**Why this priority**: This is the most frequent change a personal dotfiles
repo sees over its lifetime. If this isn't fast and obvious, the rest of
the structure doesn't matter — the repo will accumulate cruft or stop
being touched.

**Independent Test**: Pick an arbitrary new CLI tool that is in `nixpkgs`,
locate the file it should be added to within 30 seconds by looking at the
directory layout, add a single line, and run `darwin-rebuild build
--flake .#macbook` successfully. The diff for the change touches exactly
one file.

**Acceptance Scenarios**:

1. **Given** a working repository on `main`, **When** I add a new system
   package by editing one file in the packages module, **Then**
   `darwin-rebuild build --flake .#macbook` succeeds and the new tool is
   present in the resulting system derivation.
2. **Given** a working repository, **When** I add a new Homebrew cask
   following the documented convention, **Then** the cask is appended to
   the appropriate Homebrew module file and `darwin-rebuild build`
   succeeds; no other file is touched.
3. **Given** the repository, **When** a future-me opens it cold six months
   from now, **Then** I can answer "where do I add a new system package?"
   by reading the top-level `README.md` or directory layout in under 30
   seconds, without grepping.

---

### User Story 2 - Modify a program's configuration in isolation (Priority: P2)

As the sole maintainer, when I want to tweak a single program (e.g.,
change my Helix theme, add a Neovim plugin, adjust Alacritty's font size),
I edit one file dedicated to that program. Unrelated program configs are
not present in the same file, so a change to Helix cannot accidentally
break Neovim and the diff is unambiguous.

**Why this priority**: Program configuration is the second-most-frequent
change. Co-locating all programs in a single home-manager block (current
state) means tweaking Helix shows up in diffs alongside Neovim, Alacritty,
Wezterm, etc., which makes reviews and `git blame` noisier than they need
to be.

**Independent Test**: Pick any program currently configured under
`home-manager.users.mlieberman.programs.*`, locate its dedicated module
file, make a one-line change (e.g., change theme name), and confirm the
diff touches exactly one file and `darwin-rebuild build` succeeds.

**Acceptance Scenarios**:

1. **Given** a working repository, **When** I change Helix's `theme` value,
   **Then** the diff is confined to the Helix-specific module file and
   `darwin-rebuild build` succeeds.
2. **Given** a working repository, **When** I add a plugin to Neovim's
   `plugins` list, **Then** the change touches only the Neovim module
   file.

---

### User Story 3 - Accept a future second host without restructuring (Priority: P3)

As the sole maintainer, if I later acquire a second machine (work MacBook,
desktop, etc.), I can register a new host by creating one new directory
and one new wiring entry in `flake.nix`. I do not need to rename, move, or
reorganize any existing file that belongs to the current `macbook` host.

**Why this priority**: Forward-looking, not immediate. The constitution
constrains today's scope to `aarch64-darwin` single-host, but the
structure chosen now will either welcome or fight a second host later.
A layout that treats "macbook" as the implicit subject of every file
forces a refactor when host #2 arrives.

**Independent Test**: Simulate adding a stub second host called `testhost`
by creating only new files/directories under a `hosts/` tree and one new
entry under `darwinConfigurations` in `flake.nix`. Confirm no existing
file under the `macbook` host's tree is modified, and confirm `nix flake
check` succeeds (the stub host need not build to completion — its presence
in the flake should evaluate).

**Acceptance Scenarios**:

1. **Given** the restructured repository, **When** I add a new
   `hosts/testhost/` directory containing minimal modules and register it
   under `darwinConfigurations`, **Then** zero files under
   `hosts/macbook/` are modified by the addition.
2. **Given** the restructured repository, **When** I open the top-level
   `flake.nix`, **Then** it is short enough to fit on one screen and
   contains no inline package lists, program configs, or homebrew lists.

---

### Edge Cases

- **Mid-restructure intermediate commits**: A commit on this feature branch
  might temporarily leave the repository unbuildable (e.g., one file moved
  but its references not yet updated). Constitution Principle V requires
  the feature branch's final state to build, but intermediate commits
  during a multi-step move are acceptable provided the feature branch is
  squashed or all-built before merge to `main`.
- **Conflicting categorization**: A tool (e.g., `direnv`) is both a
  `programs.direnv` home-manager module AND a system-level concern. The
  layout MUST give one and only one canonical home for such items, with
  the choice documented.
- **Tooling that crosses Nix and Homebrew (`yabai`, `skhd`)**: A single
  tool whose installation lives in Homebrew (because of macOS service
  integration) but whose configuration lives in dotfiles MUST be locatable
  by the same name from either side of the split.
- **Determinate-managed daemon**: The split MUST NOT introduce any module
  that toggles `nix.enable` (Constitution Principle IV). A missing or
  misplaced module that re-enables it counts as a regression.
- **Lockfile drift during restructure**: The restructure itself MUST NOT
  bump `flake.lock`; lock updates remain a separate concern per
  Constitution Principle II.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST produce an identical system derivation
  before and after the restructuring (same packages, same program
  configs, same homebrew lists). The restructure is a pure reorganization,
  not a content change.
- **FR-002**: The current monolithic `flake.nix` MUST be split into
  multiple files organized by concern (at minimum: top-level wiring,
  system packages, homebrew, per-program home-manager configs, per-host
  glue). The top-level `flake.nix` MUST contain only flake metadata,
  inputs, and the `darwinConfigurations` wiring — no inline package
  lists, no inline program configs.
- **FR-003**: The repository MUST adopt a `hosts/<hostname>/` directory
  convention so the existing `macbook` host lives under
  `hosts/macbook/`. Additional hosts are added by creating peer
  directories without modifying existing host files.
- **FR-004**: Adding a new system package, Homebrew brew, Homebrew cask,
  or home-manager program tweak MUST require editing at most one file in
  the common case (the target module). Cross-cutting wire-up files
  (`flake.nix`, top-level imports) are permitted but SHOULD NOT need to
  change for routine additions.
- **FR-005**: The repository MUST include a `README.md` (or equivalent
  top-level guide) documenting: the directory layout, where to put each
  category of addition (system package, homebrew brew/cask, home-manager
  program, new host), and the build/switch workflow already specified by
  the constitution.
- **FR-006**: The repository's structure MUST remain compatible with the
  Determinate-managed Nix daemon (Constitution Principle IV). No module
  may set `nix.enable = true` or otherwise re-claim daemon management.
- **FR-007**: All splits MUST pass `nix flake check` and `darwin-rebuild
  build --flake .#macbook` before the feature is considered complete.
- **FR-008**: The feature MUST NOT alter `flake.lock` (Constitution
  Principle II: lockfile bumps are isolated commits, not bundled with
  feature work). Any input update encountered during the restructure is
  out of scope for this feature.
- **FR-009**: The restructuring MUST preserve every load-bearing
  identifier from the current flake: `system.primaryUser = "mlieberman"`,
  `system.stateVersion = 4`, `home.stateVersion = "24.11"`,
  `nixpkgs.config.allowUnfree = true`, and the
  `home.activation.installSpecKit` activation script. These are pinned
  anchors and must not be lost or silently renamed during the split.
- **FR-010**: Each new module file MUST be discoverable by a predictable
  path (e.g., a Helix config lives at a path containing "helix" in its
  name or one of its parent directories). Random or alphabetic-only
  layouts that hide the subject are not acceptable.

### Key Entities

- **Host**: A named entry in `darwinConfigurations` (today: `macbook`).
  Owns its hostname-specific settings (homebrew lists, primary user,
  state version) and binds one or more home-manager users.
- **Module**: A focused `.nix` file responsible for one concern (e.g.,
  "system packages", "homebrew", "the Helix editor"). Imported by exactly
  one parent (a host module or a home-manager user module).
- **Home configuration**: A per-user home-manager bundle that imports
  per-program modules and any user-level activation scripts.
- **Top-level flake**: `flake.nix`. Contains inputs, the outputs lambda,
  the system attribute (`aarch64-darwin`), and the wiring that points
  each host name at its host module. No content beyond that.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Adding a new system package (start to "edit complete",
  excluding build/switch time) takes under 1 minute, in 9 out of 10
  additions, measured against a self-test where I add 10 hypothetical
  packages from a list.
- **SC-002**: For routine additions (new package, new brew, new cask, new
  program tweak), the resulting diff touches exactly one file in at least
  90% of cases, with the remaining 10% touching at most two files (target
  module plus one wire-up).
- **SC-003**: A cold reading of the top-level `README.md` answers the
  question "where do I add a new home-manager program?" in under 30
  seconds.
- **SC-004**: `darwin-rebuild build --flake .#macbook` produces the same
  system derivation `out` path (or, equivalently, the same
  `nix-store --query --hash`) before and after the restructure, proving
  the reorganization is content-neutral.
- **SC-005**: A simulated second host can be registered by adding only
  new files plus one new line under `darwinConfigurations` in
  `flake.nix`. Zero existing files under `hosts/macbook/` are modified
  during the simulation.
- **SC-006**: The top-level `flake.nix` after the restructure is at most
  60 lines (current: 217), measured by `wc -l`.

## Assumptions

- **Platform scope**: This feature targets `aarch64-darwin` only, in line
  with the constitution. Adding NixOS or `x86_64-darwin` support is out
  of scope and would be a separate constitutional change.
- **Secrets handling**: No secrets, credentials, API keys, or other
  sensitive material enter the repository as part of this restructure.
  Secrets management (e.g., `sops-nix`, `agenix`) is explicitly a future
  feature, not part of "build out this repo".
- **Module style**: Modularization is a lightweight categorical split
  (files grouped by concern, imported via standard nix-darwin /
  home-manager `modules = [...]` lists). It is NOT a full NixOS-style
  `options ⇔ config` module system with custom schemas — that complexity
  adds no payoff for a single-user personal config and would slow down
  the very additions this feature is meant to make easier.
- **Single user, single host today**: `mlieberman` on `macbook` remains
  the sole binding today. The structure permits but does not require
  additional users or hosts.
- **Existing functionality preserved**: Every package, cask, tap, brew,
  font, and program setting present in today's `flake.nix` is preserved
  byte-for-byte in semantic meaning. This is a refactor, not a redesign.
- **Constitution governs**: All five principles (declarative
  reproducibility, pinned inputs, Nix-first/Homebrew-second,
  Determinate-compatible daemon boundary, build-before-switch) remain in
  force during and after this feature.
- **No new flake inputs**: This feature does not add `flake-parts`,
  `flake-utils`, `nixos-hardware`, or any other helper input. If a future
  feature wants those, that is a separate, justified decision.
