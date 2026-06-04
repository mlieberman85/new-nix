---
description: "Task list for feature 001-modular-nix-config"
---

# Tasks: Modular Nix Configuration Layout

**Input**: Design documents from `/specs/001-modular-nix-config/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: This feature has no test suite per se. The acceptance gate is
derivation-hash equivalence (SC-004) plus `nix flake check` / `darwin-rebuild
build --flake .#macbook` (FR-007). User-story acceptance tests are the
"independent test" probes called out in the spec (e.g., "add a hypothetical
package, confirm diff touches one file, then revert"). They appear in each
story phase as explicit tasks.

**Organization**: Tasks are grouped by user story (US1, US2, US3) from
`spec.md`. The Foundational phase establishes the structural scaffolding
every story depends on.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- All paths are repository-relative to `/Users/mlieberman/Projects/new-nix`.

## Path Conventions

- **Repository root**: `/Users/mlieberman/Projects/new-nix/`
- **Top-level flake**: `flake.nix`
- **Host tree**: `hosts/macbook/`
- **User home tree**: `hosts/macbook/home/mlieberman/`
- **Per-program modules**: `hosts/macbook/home/mlieberman/programs/`

---

## Phase 1: Setup (Capture Baseline)

**Purpose**: Capture the pre-refactor system derivation so every later phase
can prove content-neutrality (SC-004, FR-001).

- [ ] T001 Capture pre-refactor derivation reference: run `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.before` from repo root and verify the file is non-empty. This file is the SC-004 oracle — do NOT modify the working tree before capturing it.
- [ ] T002 Capture pre-refactor `environment.systemPackages` set: `nix eval --json .#darwinConfigurations.macbook.config.environment.systemPackages --apply 'pkgs: builtins.sort builtins.lessThan (map (p: p.name or p.pname or "?") pkgs)' > /tmp/syspkgs.before.json`. This is the FR-001 oracle for the packages list.
- [ ] T003 Capture pre-refactor homebrew lists: `nix eval --json .#darwinConfigurations.macbook.config.homebrew --apply 'h: { brews = builtins.sort builtins.lessThan h.brews; casks = builtins.sort builtins.lessThan h.casks; taps = builtins.sort builtins.lessThan h.taps; }' > /tmp/homebrew.before.json`. This is the FR-001 oracle for the Homebrew lists.

**Checkpoint**: Three baseline files in `/tmp/` capture the pre-refactor invariants. Setup complete.

---

## Phase 2: Foundational (Structural Scaffolding)

**Purpose**: Move the monolithic host module into `hosts/macbook/` and split
out the Determinate boundary and system-identity options. Every user story
phase below assumes this scaffolding exists.

**⚠️ CRITICAL**: No user story work can begin until Phase 2 is complete and T007 derivation-hash diff is empty.

- [ ] T004 Create `hosts/macbook/default.nix` containing the entire inline module value currently passed to `modules` in `flake.nix` — the `({ config, pkgs, lib, ... }: let gdk = ...; in { ... })` lambda. Move the WHOLE thing including the `let gdk = pkgs.google-cloud-sdk.withExtraComponents (...); in` binding. Wrap as a standalone module with signature `{ config, pkgs, lib, ... }:`. The `gdk` binding will be relocated again to `packages.nix` in T010. (Identified by structural boundary, not line numbers, since line numbers shift as the file is edited.)
- [ ] T005 Update `flake.nix` to remove the inline module body and replace it with `./hosts/macbook` in the `modules` list. After this task the file MUST be ≤ 60 lines (SC-006). Keep `home-manager.darwinModules.home-manager` as a peer entry in the `modules` list (per research R4).
- [ ] T006 Extract the Determinate boundary into `hosts/macbook/nix.nix`: move `nix.enable = false;` and `nix.settings.experimental-features = [ "nix-command" "flakes" ];` out of `hosts/macbook/default.nix` and into the new file. Add `./nix.nix` to the `imports` list in `default.nix`. (Principle IV, FR-006.)
- [ ] T007 Run intermediate equivalence check: `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.after.foundational && diff /tmp/system.drv.before /tmp/system.drv.after.foundational`. Diff MUST be empty. If non-empty, halt — investigate via `nix derivation show` JSON-diff before continuing.
- [ ] T008 Extract host-level system options into `hosts/macbook/system.nix`: move `environment.systemPath`, system-level `programs.zsh = { enable = true; enableSyntaxHighlighting = true; enableFzfHistory = true; }`, `programs.direnv.enable = true`, and `users.users.mlieberman` out of `hosts/macbook/default.nix` and into the new file. Add `./system.nix` to the `imports` list in `default.nix`. (Per research R7: only the *system-level* zsh enable + integrations move; the user-level zsh config stays in `default.nix` for now and migrates to a home-manager module in Phase 4.)
- [ ] T009 Run equivalence check after T008: `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.after.system && diff /tmp/system.drv.before /tmp/system.drv.after.system`. Diff MUST be empty.

**Checkpoint**: `flake.nix` ≤ 60 lines, host module split into `default.nix` + `nix.nix` + `system.nix`, derivation hash unchanged. User stories may now proceed.

---

## Phase 3: User Story 1 - Add a new package without editing the monolith (Priority: P1) 🎯 MVP

**Goal**: Adding a system package, brew, or cask becomes a one-file edit
that does not require touching `flake.nix` or the host entry module.

**Independent Test**: Add a hypothetical system package (`ncdu`) — diff
MUST touch exactly one file (`hosts/macbook/packages.nix`) — and
`darwin-rebuild build --flake .#macbook` MUST succeed. Same for a
hypothetical Homebrew brew. Both reverted at the end of the test.

### Implementation for User Story 1

- [ ] T010 [US1] Extract system packages into `hosts/macbook/packages.nix`. Move `environment.systemPackages = with pkgs; [ ... ];` AND the surrounding `let gdk = pkgs.google-cloud-sdk.withExtraComponents (...); in` binding out of `hosts/macbook/default.nix` and into the new file (function signature `{ pkgs, ... }:`). Preserve the package list byte-for-byte. Add `./packages.nix` to the `imports` list in `default.nix`. (Per research R3 — `gdk` co-locates with `packages.nix`.)
- [ ] T011 [US1] Extract Homebrew into `hosts/macbook/homebrew.nix`. Move the entire `homebrew = { enable = true; onActivation = { ... }; brews = [ ... ]; casks = [ ... ]; taps = [ ... ]; };` block out of `hosts/macbook/default.nix` and into the new file. Add `./homebrew.nix` to the `imports` list in `default.nix`.
- [ ] T012 [US1] Run equivalence check after T010 and T011: `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.after.us1 && diff /tmp/system.drv.before /tmp/system.drv.after.us1`. Diff MUST be empty. Also re-verify FR-001 list equivalence: `nix eval --json ... > /tmp/syspkgs.after.us1.json && diff /tmp/syspkgs.before.json /tmp/syspkgs.after.us1.json` and same for homebrew.
- [ ] T013 [US1] **Independent test (system package)**: edit `hosts/macbook/packages.nix` to append `ncdu` to `environment.systemPackages`. Run `git diff --stat` and confirm exactly one file is modified. Run `darwin-rebuild build --flake .#macbook` — MUST succeed. Run `git checkout hosts/macbook/packages.nix` to revert.
- [ ] T014 [US1] **Independent test (Homebrew brew)**: edit `hosts/macbook/homebrew.nix` to append `"wget"` to `homebrew.brews`. Run `git diff --stat` — exactly one file modified. Run `darwin-rebuild build --flake .#macbook` — MUST succeed. Revert with `git checkout hosts/macbook/homebrew.nix`.

**Checkpoint**: US1 fully delivered. A reader who wants to add a package, brew, cask, or tap edits exactly one file from the `hosts/macbook/` tree. SC-002 holds for these categories.

---

## Phase 4: User Story 2 - Modify a program's configuration in isolation (Priority: P2)

**Goal**: Tweaking any single home-manager program is a one-file edit in
`hosts/macbook/home/mlieberman/programs/<name>.nix`.

**Independent Test**: Change Helix's `theme` value (e.g., to
`catppuccin_macchiato`). Diff MUST touch only `helix.nix`. Build MUST
succeed. Revert.

### Implementation for User Story 2

- [ ] T015 [US2] Create the home entry module `hosts/macbook/home/mlieberman/default.nix` with function signature `{ pkgs, lib, ... }:`. It must own ONLY `home.stateVersion = "24.11";` and the verbatim `home.activation.installSpecKit` block currently in `flake.nix` (load-bearing per FR-009). The `imports` list starts empty and is populated by T024.

  Per-program file creations T016–T023 are [P] because each creates a brand-new file with no other file dependency. They do NOT modify `default.nix` (host) or `default.nix` (home) — T024 makes the import wiring change in one atomic step.

- [ ] T016 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/alacritty.nix` mirroring the current `programs.alacritty` block from `hosts/macbook/default.nix` (signature `{ pkgs, lib, ... }:`). Preserve all settings byte-for-byte (font sizes, families, styles).
- [ ] T017 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/nushell.nix` with `programs.nushell.enable = true;`.
- [ ] T018 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/zsh.nix` containing the user-level `programs.zsh` settings: `enable = true;`, `shellAliases = { python = "python3"; };`, and the full `initContent` heredoc verbatim. (System-level `programs.zsh` already lives in `system.nix` per research R7.)
- [ ] T019 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/zoxide.nix` with `programs.zoxide.{enable, enableBashIntegration, enableZshIntegration, enableNushellIntegration}` all `true`.
- [ ] T020 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/wezterm.nix` with `programs.wezterm.{enable, enableZshIntegration, extraConfig}` matching the current monolith.
- [ ] T021 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/zellij.nix` with `programs.zellij = { enable = false; enableZshIntegration = false; }` (current values preserved).
- [ ] T022 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/helix.nix` mirroring the current `programs.helix` block. Preserve the `formatter.command = "${pkgs.nixfmt}/bin/nixfmt"` interpolation.
- [ ] T023 [P] [US2] Create `hosts/macbook/home/mlieberman/programs/neovim.nix` mirroring the current `programs.neovim` block including `withRuby = false`, plugins list, and `initLua`.
- [ ] T024 [US2] Wire it up: edit `hosts/macbook/home/mlieberman/default.nix` to set `imports = [ ./programs/alacritty.nix ./programs/nushell.nix ./programs/zsh.nix ./programs/zoxide.nix ./programs/wezterm.nix ./programs/zellij.nix ./programs/helix.nix ./programs/neovim.nix ];`. Then edit `hosts/macbook/default.nix` to replace the inline `home-manager.users.mlieberman = { pkgs, lib, ... }: { ... };` block with `home-manager.users.mlieberman = import ./home/mlieberman;`. Also leave the `home-manager.{useGlobalPkgs, useUserPackages, backupFileExtension}` settings in `default.nix`.
- [ ] T025 [US2] Run equivalence check: `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.after.us2 && diff /tmp/system.drv.before /tmp/system.drv.after.us2`. Diff MUST be empty.
- [ ] T026 [US2] **Independent test (program tweak)**: edit `hosts/macbook/home/mlieberman/programs/helix.nix` to change `theme = "catppuccin_frappe"` to `theme = "catppuccin_macchiato"`. Run `git diff --stat` — exactly one file modified. Run `darwin-rebuild build --flake .#macbook` — MUST succeed. Revert with `git checkout hosts/macbook/home/mlieberman/programs/helix.nix`.
- [ ] T027 [US2] **Independent test (plugin add)**: edit `hosts/macbook/home/mlieberman/programs/neovim.nix` to append `vim-fugitive` to the `plugins` list. Run `git diff --stat` — exactly one file modified. Build — MUST succeed. Revert.

**Checkpoint**: US2 fully delivered. Per-program edits touch exactly one file each; FR-010 holds (each module file's name contains its program name).

---

## Phase 5: User Story 3 - Accept a future second host without restructuring (Priority: P3)

**Goal**: A new host can be registered additively (one new directory + one
new line in `flake.nix`) without modifying any existing file under
`hosts/macbook/`.

**Independent Test**: Add a stub `hosts/testhost/default.nix` plus one entry
in `darwinConfigurations`. Confirm `git status` shows zero modifications to
files under `hosts/macbook/`. `nix flake check` MUST evaluate successfully.
Stub is reverted at the end of the test (not committed).

### Implementation for User Story 3

- [ ] T028 [US3] Create stub `hosts/testhost/default.nix` with a minimal module: `{ config, pkgs, lib, ... }: { system.primaryUser = "testuser"; system.stateVersion = 4; nixpkgs.config.allowUnfree = false; }` (sufficient for nix-darwin evaluation to type-check; need not be a complete buildable system).
- [ ] T029 [US3] Add one new entry under `darwinConfigurations` in `flake.nix`: `darwinConfigurations."testhost" = darwin.lib.darwinSystem { inherit system; modules = [ ./hosts/testhost ]; };`. The diff for this change MUST touch only `flake.nix` (one new entry) and the new `hosts/testhost/` directory.
- [ ] T030 [US3] Verify additive property: `git status --porcelain | grep -E '^.M hosts/macbook/'` MUST produce no output. (No file under the macbook host was modified.)
- [ ] T031 [US3] Verify evaluation: `nix flake check` MUST exit 0 with the stub host registered.
- [ ] T032 [US3] Revert the stub: `git checkout flake.nix && rm -rf hosts/testhost/`. The testhost is a verification probe, not a real host — do NOT commit it.

**Checkpoint**: US3 verified. SC-005 holds. The layout is second-host-ready without further structural work.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: README, formatting pass, and final acceptance validation.

- [ ] T033 [P] Write top-level `README.md` covering: (a) directory layout diagram (mirrors plan.md "Source Code" tree), (b) "where do I add X?" table copied from `specs/001-modular-nix-config/quickstart.md`, (c) cross-reference to `.specify/memory/constitution.md` for principles and the build/switch workflow. Does NOT duplicate workflow content (per research R6). Satisfies FR-005 and targets SC-003.
- [ ] T034 [P] Run `nixpkgs-fmt` on every new `.nix` file: `nixpkgs-fmt flake.nix hosts/macbook/default.nix hosts/macbook/nix.nix hosts/macbook/system.nix hosts/macbook/packages.nix hosts/macbook/homebrew.nix hosts/macbook/home/mlieberman/default.nix hosts/macbook/home/mlieberman/programs/*.nix`. Verify no functional change via T036 below.
- [ ] T035 Verify `flake.lock` was not modified during the feature: `git diff main -- flake.lock` MUST be empty. (FR-008, Principle II.)
- [ ] T036 **Final acceptance check** — all of the following MUST hold (commands literal, copy-paste from T002/T003 to ensure the comparison is byte-identical to the baseline):
    - `wc -l flake.nix | awk '{print $1}'` ≤ 60 (SC-006)
    - `nix path-info --derivation .#darwinConfigurations.macbook.system > /tmp/system.drv.final && diff /tmp/system.drv.before /tmp/system.drv.final` is empty (SC-004, FR-001)
    - `nix eval --json .#darwinConfigurations.macbook.config.environment.systemPackages --apply 'pkgs: builtins.sort builtins.lessThan (map (p: p.name or p.pname or "?") pkgs)' > /tmp/syspkgs.after.json && diff /tmp/syspkgs.before.json /tmp/syspkgs.after.json` is empty (FR-001 for the package list)
    - `nix eval --json .#darwinConfigurations.macbook.config.homebrew --apply 'h: { brews = builtins.sort builtins.lessThan h.brews; casks = builtins.sort builtins.lessThan h.casks; taps = builtins.sort builtins.lessThan h.taps; }' > /tmp/homebrew.after.json && diff /tmp/homebrew.before.json /tmp/homebrew.after.json` is empty (FR-001 for the Homebrew lists)
    - `nix flake check` exits 0 (FR-007)
    - `darwin-rebuild build --flake .#macbook` exits 0 (FR-007)
- [ ] T037 Verify FR-009 positive anchors + FR-006 negative invariant. Two checks:

    (a) Each of the five FR-009 anchors MUST appear exactly once across `flake.nix` and `hosts/`:
    ```sh
    for s in 'system.primaryUser = "mlieberman"' \
             'system.stateVersion = 4' \
             'home.stateVersion = "24.11"' \
             'nixpkgs.config.allowUnfree = true' \
             'home.activation.installSpecKit'; do
      n=$(grep -RFn "$s" flake.nix hosts/ | wc -l | tr -d ' ')
      [ "$n" = "1" ] || { echo "FR-009 FAIL: anchor [$s] appears $n times (expected 1)"; exit 1; }
    done
    echo "FR-009 anchors OK."
    ```

    (b) The Determinate boundary MUST NOT be re-enabled anywhere (FR-006, Principle IV):
    ```sh
    if grep -RInE 'nix\.enable[[:space:]]*=[[:space:]]*true' flake.nix hosts/; then
      echo "FR-006 FAIL: nix.enable = true appears in tree"; exit 1
    fi
    echo "FR-006 boundary OK (nix.enable = true does not appear)."
    ```
- [ ] T038 Run `darwin-rebuild switch --flake .#macbook`. (Per Principle V, only after T036 build is clean.) Open a fresh shell and exercise: `helix --version`, `nvim --version`, `bun --version`, `darwin-rebuild --list-generations | tail -3`. Any breakage triggers `darwin-rebuild --rollback` and a return to the failing task.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — must run first; baselines are write-once.
- **Foundational (Phase 2)**: Depends on Setup. BLOCKS all user stories. Tasks T004→T005→T006→T007 sequential; T008→T009 sequential.
- **US1 (Phase 3)**: Depends on Foundational completion (T009 green). Internally sequential (T010 → T011 → T012 → T013 → T014).
- **US2 (Phase 4)**: Depends on Foundational completion. Can run in parallel with US1 if structured carefully — but both modify `hosts/macbook/default.nix` (US1 removes packages+homebrew blocks; US2 removes the home-manager.users block). To avoid merge conflicts, prefer US1 then US2 sequentially. T016–T023 are [P] within US2 (each writes a brand-new file).
- **US3 (Phase 5)**: Depends on Foundational completion. Independent of US1/US2 (touches only `flake.nix` and a new `hosts/testhost/`).
- **Polish (Phase 6)**: Depends on US1, US2, US3 complete. T033 and T034 are [P]; T035–T038 sequential.

### User Story Dependencies

- **US1 (P1)**: independent of US2 and US3 once Foundational is done; recommended first for MVP.
- **US2 (P2)**: independent of US1 and US3 once Foundational is done; second priority but practically sequenced after US1 to avoid `hosts/macbook/default.nix` merge conflicts.
- **US3 (P3)**: independent of US1 and US2; could run in parallel with either, but its verification probe needs `flake.nix` settled (i.e., post-Foundational).

### Within Each User Story

- Extraction tasks (move attribute X out of inline → new file) MUST be followed by an equivalence-check task.
- Independent-test probes (T013, T014, T026, T027, T030–T032) are the SC-002 acceptance evidence — they run after extraction is verified.
- Reverts are part of the probe, not the next task.

### Parallel Opportunities

- T002, T003 (Setup baseline captures): could be [P] in spirit but each is one short shell command; running sequentially is fine.
- T016–T023 (per-program module creations): genuinely parallel — each writes a fresh file with no other dependency.
- T033 (README) and T034 (formatter pass): parallel — different files; format pass excludes README.
- US1, US2, US3 phases: technically independent post-Foundational but US1+US2 race on `hosts/macbook/default.nix`; sequence them. US3 truly independent.

---

## Parallel Example: User Story 2

```text
# After T015 creates the empty home entry, launch the 8 per-program creations together:
Task: T016 — Create hosts/macbook/home/mlieberman/programs/alacritty.nix
Task: T017 — Create hosts/macbook/home/mlieberman/programs/nushell.nix
Task: T018 — Create hosts/macbook/home/mlieberman/programs/zsh.nix
Task: T019 — Create hosts/macbook/home/mlieberman/programs/zoxide.nix
Task: T020 — Create hosts/macbook/home/mlieberman/programs/wezterm.nix
Task: T021 — Create hosts/macbook/home/mlieberman/programs/zellij.nix
Task: T022 — Create hosts/macbook/home/mlieberman/programs/helix.nix
Task: T023 — Create hosts/macbook/home/mlieberman/programs/neovim.nix
# Then T024 wires the imports + removes the inline block in a single atomic edit.
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T003) — capture baseline oracles.
2. Phase 2: Foundational (T004–T009) — host scaffolding + nix/system split.
3. Phase 3: User Story 1 (T010–T014) — packages and homebrew modular.
4. **STOP and VALIDATE**: SC-002 holds for packages/brews/casks; `darwin-rebuild build` clean; baseline diff empty.
5. (Optional) `darwin-rebuild switch` at MVP point — the system runs the refactored config with same derivation hash, so switch is a no-op generation-wise but exercises the new structure.

### Incremental Delivery

1. Setup + Foundational → host scaffolding in place; flake.nix ≤ 60 lines achieved.
2. US1 (T010–T014) → add-a-package one-file workflow verified — MVP.
3. US2 (T015–T027) → tweak-a-program one-file workflow verified.
4. US3 (T028–T032) → second-host additivity verified.
5. Polish (T033–T038) → README written, format pass, final acceptance, switch.

### Solo-Developer Strategy (the actual case here)

This repo has one maintainer. Run tasks sequentially per the order above.
The [P] markers on T016–T023 mean "these eight file creations are
mechanical and can be batched into a single sitting"; they don't require
multiple workers, just that each one writes a different new file and so
nothing races.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to a spec user story for traceability.
- Each user story is independently completable and (after Foundational) independently testable via its probe (T013/T014/T026/T027/T030–T032).
- Commit cadence: one commit per task is fine; one commit per phase checkpoint (after T009, T012, T025, T032, T036, T038) is the minimum. Per Constitution Principle V, commit before `switch` so rollbacks have a clear target.
- The derivation-hash diff is the load-bearing safety check — every phase ends with one. If a phase's diff is non-empty, do NOT proceed; diff the two `.drv` files (`nix derivation show $(cat /tmp/system.drv.before)` vs `... after`) to find which attribute the move accidentally altered.
- Avoid: bumping `flake.lock` (FR-008), toggling `nix.enable` (FR-006), introducing new flake inputs (Assumptions), reordering or renaming any of the five FR-009 anchors.
