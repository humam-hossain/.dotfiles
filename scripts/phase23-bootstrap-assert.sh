#!/usr/bin/env bash
# Phase 23 One-command bootstrap assert harness (BOOT-01 to BOOT-05).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase23-bootstrap-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------------------------
RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Git Working-Tree Porcelain Bracket (Pattern 2.2)
# ---------------------------------------------------------------------------
porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p23-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p23-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: CLI flags, unknown option rejection, root check, wrapper delegation (BOOT-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: CLI flags, unknown option rejection, root check, wrapper delegation ---"

  # 1. --help exits 0 and outputs usage
  HELP_RC=0
  HELP_OUT="$("$REPO_ROOT/bootstrap.sh" --help 2>&1)" || HELP_RC=$?
  if [[ "$HELP_RC" -eq 0 ]] && grep -q "Usage:" <<<"$HELP_OUT"; then
    pass "Section 1: ./bootstrap.sh --help outputs usage with exit 0"
  else
    fail "Section 1: ./bootstrap.sh --help failed (rc=$HELP_RC)"
  fi

  # 2. Unknown flag rejected with exit code 2 and error on stderr
  BOGUS_RC=0
  BOGUS_OUT="$("$REPO_ROOT/bootstrap.sh" --bogus-flag 2>&1)" || BOGUS_RC=$?
  if [[ "$BOGUS_RC" -eq 2 ]] && grep -q "Unknown bootstrap flag" <<<"$BOGUS_OUT"; then
    pass "Section 1: unknown flag correctly rejected with exit code 2"
  else
    fail "Section 1: unknown flag did not exit 2 with error message (rc=$BOGUS_RC)"
  fi

  # 3. Non-root execution gate: root simulation rejected with exit 1 (D-06)
  ROOT_RC=0
  ROOT_OUT="$(DOTFILES_MOCK_EUID=0 "$REPO_ROOT/bootstrap.sh" 2>&1)" || ROOT_RC=$?
  if [[ "$ROOT_RC" -eq 1 ]] && grep -qi "must not be run as root" <<<"$ROOT_OUT"; then
    pass "Section 1: root user invocation correctly rejected with exit code 1"
  else
    fail "Section 1: root user invocation was not rejected with exit code 1 (rc=$ROOT_RC)"
  fi

  # 4. Wrapper delegation: arch/dots-hyprland.sh bootstrap forwards to ./bootstrap.sh
  WRAP_RC=0
  WRAP_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" bootstrap --help 2>&1)" || WRAP_RC=$?
  if [[ "$WRAP_RC" -eq 0 ]] && grep -q "Usage:" <<<"$WRAP_OUT"; then
    pass "Section 1: arch/dots-hyprland.sh bootstrap successfully forwards to ./bootstrap.sh"
  else
    fail "Section 1: arch/dots-hyprland.sh bootstrap delegation failed (rc=$WRAP_RC)"
  fi

  # 5. Invariant: PAIR_COUNT in arch/*.sh MUST remain strictly 18
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  if [[ "$PAIR_COUNT" -eq 18 ]]; then
    pass "Section 1: PAIR_COUNT invariant in arch/*.sh is strictly 18"
  else
    fail "Section 1: PAIR_COUNT in arch/*.sh drifted (expected 18, counted $PAIR_COUNT)"
  fi
fi

# ===========================================================================
# Section 2: Isolated scratch de-stubbing, backup manifest, stow linking, capture seeding (BOOT-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Isolated scratch de-stubbing, backup manifest, and stow linking ---"

  S2_ROOT="$(mktemp -d /tmp/p23-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_ROOT")

  MOCK_REPO="$S2_ROOT/repo"
  MOCK_HOME="$S2_ROOT/home"
  mkdir -p "$MOCK_REPO/stow/testpkg/.config/testpkg"
  mkdir -p "$MOCK_REPO/capture/mockpkg/.config/mock"
  mkdir -p "$MOCK_HOME/.config/testpkg"
  mkdir -p "$MOCK_HOME/.config"

  # Populate mock repository and live targets
  echo "managed personal config" > "$MOCK_REPO/stow/testpkg/.config/testpkg/config.ini"
  echo "upstream stub content" > "$MOCK_HOME/.config/testpkg/config.ini"
  cp "$REPO_ROOT/guard-paths.tsv" "$MOCK_REPO/guard-paths.tsv"

  # Set up guarded live file that must NOT be pruned or deleted
  echo "guarded theme content" > "$MOCK_HOME/.config/kdeglobals"

  # Set up valid and invalid capture seeds
  echo '{"theme":"dark"}' > "$MOCK_REPO/capture/mockpkg/.config/mock/settings.json"
  echo '{"theme":' > "$MOCK_REPO/capture/mockpkg/.config/mock/broken.json"

  # Source bootstrap library functions for isolated testing
  # shellcheck source=/dev/null
  source "$REPO_ROOT/bootstrap.sh"

  # 1. Run de-stubbing
  run_destub "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1

  # Assert guarded file was not touched (D-17)
  if [[ -f "$MOCK_HOME/.config/kdeglobals" ]] && [[ "$(<"$MOCK_HOME/.config/kdeglobals")" == "guarded theme content" ]]; then
    pass "Section 2: guard-paths.tsv entry ($MOCK_HOME/.config/kdeglobals) was preserved untouched"
  else
    fail "Section 2: guarded file was modified or deleted during de-stubbing"
  fi

  # Assert conflicting stub was removed from live location
  if [[ ! -e "$MOCK_HOME/.config/testpkg/config.ini" ]]; then
    pass "Section 2: conflicting stub was unlinked from live location"
  else
    fail "Section 2: conflicting stub was not unlinked from live location"
  fi

  # Assert stub was archived to backup directory
  BACKUP_DIR="$(find "$MOCK_HOME" -maxdepth 1 -name '.dotfiles-backup.*' | head -1)"
  if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
    pass "Section 2: created timestamped backup directory ($BACKUP_DIR)"
    ARCHIVED_FILE="$BACKUP_DIR/.config/testpkg/config.ini"
    if [[ -f "$ARCHIVED_FILE" ]] && [[ "$(<"$ARCHIVED_FILE")" == "upstream stub content" ]]; then
      pass "Section 2: conflicting stub safely archived in backup hierarchy"
    else
      fail "Section 2: conflicting stub missing or corrupted in backup directory"
    fi

    # Assert MANIFEST.txt existence and verify checksum integrity via sha256sum -c
    if [[ -f "$BACKUP_DIR/MANIFEST.txt" ]]; then
      pass "Section 2: backup archive contains MANIFEST.txt"
      if (cd "$BACKUP_DIR" && sha256sum -c MANIFEST.txt >/dev/null 2>&1); then
        pass "Section 2: sha256sum -c verified archived stub checksum integrity"
      else
        fail "Section 2: sha256sum -c failed against MANIFEST.txt"
      fi
    else
      fail "Section 2: MANIFEST.txt missing from backup archive"
    fi
  else
    fail "Section 2: backup directory was not created"
  fi

  # 2. Run GNU Stow step
  run_stow_step "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1

  # Assert sensitive parent directories pre-created and are not symlinks (D-14)
  PARENT_DIRS_OK=true
  for pdir in "$MOCK_HOME/.config/gtk-3.0" "$MOCK_HOME/.config/gtk-4.0" "$MOCK_HOME/.config/hypr/custom" "$MOCK_HOME/.config/systemd/user"; do
    if [[ ! -d "$pdir" || -L "$pdir" ]]; then
      PARENT_DIRS_OK=false
      fail "Section 2: parent dir $pdir missing or folded into a symlink"
    fi
  done
  if [[ "$PARENT_DIRS_OK" == "true" ]]; then
    pass "Section 2: sensitive parent directories pre-created as real directories (no directory folding)"
  fi

  # Assert live config is a symlink pointing to repository source with matching inode
  LIVE_STOWED="$MOCK_HOME/.config/testpkg/config.ini"
  REPO_STOWED="$MOCK_REPO/stow/testpkg/.config/testpkg/config.ini"
  if [[ -L "$LIVE_STOWED" ]]; then
    pass "Section 2: stowed file is a symbolic link"
    if [[ "$LIVE_STOWED" -ef "$REPO_STOWED" ]]; then
      pass "Section 2: stowed symlink shares inode identity (-ef) with repository source"
    else
      fail "Section 2: stowed symlink does not resolve to repository source (-ef failed)"
    fi
  else
    fail "Section 2: stowed file is not a symbolic link"
  fi

  # Assert package parent directory in home was not folded into a symlink
  if [[ -d "$MOCK_HOME/.config/testpkg" && ! -L "$MOCK_HOME/.config/testpkg" ]]; then
    pass "Section 2: package parent directory is a regular directory (no stow directory folding)"
  else
    fail "Section 2: package parent directory was folded into a symlink"
  fi

  # 3. Run capture seed deployment
  # First test with broken JSON: must fail closed and return non-zero
  SEED_FAIL_RC=0
  deploy_capture_seeds "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || SEED_FAIL_RC=$?
  if [[ "$SEED_FAIL_RC" -ne 0 ]]; then
    pass "Section 2: deploy_capture_seeds failed closed on broken JSON syntax"
  else
    fail "Section 2: deploy_capture_seeds did not fail on invalid JSON syntax"
  fi

  # Remove broken JSON and deploy valid seed
  rm -f "$MOCK_REPO/capture/mockpkg/.config/mock/broken.json"
  SEED_PASS_RC=0
  deploy_capture_seeds "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || SEED_PASS_RC=$?
  if [[ "$SEED_PASS_RC" -eq 0 ]]; then
    DEPLOYED_SEED="$MOCK_HOME/.config/mock/settings.json"
    if [[ -f "$DEPLOYED_SEED" ]] && jq empty "$DEPLOYED_SEED" >/dev/null 2>&1; then
      pass "Section 2: valid capture seed deployed atomically with package prefix stripped"
    else
      fail "Section 2: deployed capture seed missing or invalid JSON"
    fi
  else
    fail "Section 2: deploy_capture_seeds failed on valid capture package"
  fi
fi

# ===========================================================================
# Section 3: State machine resumability, --from, --only, --reset, idempotence (BOOT-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: State machine resumability, --from, --only, --reset, idempotence ---"

  S3_ROOT="$(mktemp -d /tmp/p23-assert-s3-XXXXXX)"
  SCRATCH_ROOTS+=("$S3_ROOT")
  S3_STATE_DIR="$S3_ROOT/state"
  STATE_FILE="$S3_STATE_DIR/dotfiles/bootstrap-state"
  export DOTFILES_MOCK_STEPS=1

  # 1. State initialization check (valid JSON schema adhering to D-02)
  INIT_RC=0
  XDG_STATE_HOME="$S3_STATE_DIR" "$REPO_ROOT/bootstrap.sh" --only submodules >/dev/null 2>&1 || INIT_RC=$?
  if [[ "$INIT_RC" -eq 0 && -f "$STATE_FILE" ]] && jq empty "$STATE_FILE" 2>/dev/null; then
    VER="$(jq -r '.schema_version // 0' "$STATE_FILE")"
    STAGE="$(jq -r '.stage // 0' "$STATE_FILE")"
    SUB_STATUS="$(jq -r '.steps.submodules.status // "missing"' "$STATE_FILE")"
    PKG_STATUS="$(jq -r '.steps.packages.status // "missing"' "$STATE_FILE")"
    if [[ "$VER" -eq 1 && "$STAGE" -eq 1 && "$SUB_STATUS" == "complete" && "$PKG_STATUS" == "pending" ]]; then
      pass "Section 3: state initialization created valid JSON schema (D-02)"
    else
      fail "Section 3: state JSON schema unexpected (ver=$VER, stage=$STAGE, sub=$SUB_STATUS, pkg=$PKG_STATUS)"
    fi
  else
    fail "Section 3: state file missing or invalid JSON after initialization (rc=$INIT_RC)"
  fi

  # 2. Simulated failure records 'failed' status and last_error in JSON, and exits with step's code
  FAIL_RC=0
  FAIL_OUT="$(XDG_STATE_HOME="$S3_STATE_DIR" DOTFILES_MOCK_FAIL_STEP="packages" DOTFILES_MOCK_FAIL_RC=42 "$REPO_ROOT/bootstrap.sh" 2>&1)" || FAIL_RC=$?
  if [[ "$FAIL_RC" -eq 42 ]]; then
    PKG_FAIL_STATUS="$(jq -r '.steps.packages.status // "missing"' "$STATE_FILE")"
    LAST_ERR="$(jq -r '.last_error // ""' "$STATE_FILE")"
    if [[ "$PKG_FAIL_STATUS" == "failed" && -n "$LAST_ERR" ]]; then
      pass "Section 3: simulated failure recorded status 'failed' and populated last_error in state JSON"
    else
      fail "Section 3: state JSON did not record status 'failed' (status=$PKG_FAIL_STATUS, err=$LAST_ERR)"
    fi
    if grep -q "\./bootstrap.sh --from packages" <<<"$FAIL_OUT"; then
      pass "Section 3: failure output printed exact resume instructions (./bootstrap.sh --from packages)"
    else
      fail "Section 3: failure output missing resume command: $FAIL_OUT"
    fi
  else
    fail "Section 3: simulated failure did not exit with mock exit code 42 (rc=$FAIL_RC)"
  fi

  # 3. Test --from <step>: resumes from target step, skipping prior steps
  FROM_RC=0
  FROM_OUT="$(XDG_STATE_HOME="$S3_STATE_DIR" "$REPO_ROOT/bootstrap.sh" --from packages 2>&1)" || FROM_RC=$?
  if [[ "$FROM_RC" -eq 0 ]]; then
    PKG_RESUME_STATUS="$(jq -r '.steps.packages.status // "missing"' "$STATE_FILE")"
    INST_STATUS="$(jq -r '.steps.installer.status // "missing"' "$STATE_FILE")"
    if [[ "$PKG_RESUME_STATUS" == "complete" && "$INST_STATUS" == "complete" ]]; then
      pass "Section 3: --from packages resumed and completed remaining execution"
    else
      fail "Section 3: steps after --from packages did not complete (pkg=$PKG_RESUME_STATUS, inst=$INST_STATUS)"
    fi
  else
    fail "Section 3: --from packages failed (rc=$FROM_RC)"
  fi

  # 4. Test --only <step>: executes strictly named step and terminates
  XDG_STATE_HOME="$S3_STATE_DIR" "$REPO_ROOT/bootstrap.sh" --reset --only destub >/dev/null 2>&1 || true
  DESTUB_STATUS="$(jq -r '.steps.destub.status // "missing"' "$STATE_FILE")"
  SUB_STATUS2="$(jq -r '.steps.submodules.status // "missing"' "$STATE_FILE")"
  STOW_STATUS="$(jq -r '.steps.stow.status // "missing"' "$STATE_FILE")"
  if [[ "$DESTUB_STATUS" == "complete" && "$SUB_STATUS2" == "pending" && "$STOW_STATUS" == "pending" ]]; then
    pass "Section 3: --only destub executed strictly the destub step"
  else
    fail "Section 3: --only destub did not isolate execution (destub=$DESTUB_STATUS, sub=$SUB_STATUS2, stow=$STOW_STATUS)"
  fi

  # 5. Test --reset: wipes state file and reinitializes
  XDG_STATE_HOME="$S3_STATE_DIR" "$REPO_ROOT/bootstrap.sh" --reset --only submodules >/dev/null 2>&1 || true
  RESET_SUB="$(jq -r '.steps.submodules.status // "missing"' "$STATE_FILE")"
  RESET_DESTUB="$(jq -r '.steps.destub.status // "missing"' "$STATE_FILE")"
  if [[ "$RESET_SUB" == "complete" && "$RESET_DESTUB" == "pending" ]]; then
    pass "Section 3: --reset reinitialized state cleanly"
  else
    fail "Section 3: --reset failed to reinitialize state (sub=$RESET_SUB, destub=$RESET_DESTUB)"
  fi

  # 6. Test idempotence: execute pipeline in completed state without flags; assert exit 0 and zero redundant operations
  jq '.steps |= map_values(.status = "complete")' "$STATE_FILE" > "$STATE_FILE.tmp.$$" && mv "$STATE_FILE.tmp.$$" "$STATE_FILE"
  IDEM_RC=0
  IDEM_OUT="$(XDG_STATE_HOME="$S3_STATE_DIR" "$REPO_ROOT/bootstrap.sh" 2>&1)" || IDEM_RC=$?
  if [[ "$IDEM_RC" -eq 0 ]]; then
    SKIP_COUNT="$(grep -c "already completed" <<<"$IDEM_OUT" || true)"
    if [[ "$SKIP_COUNT" -eq 7 ]]; then
      pass "Section 3: re-running on completed state is 100% idempotent (all 7 steps skipped)"
    else
      fail "Section 3: idempotence run did not skip all steps (skip count=$SKIP_COUNT)"
    fi
  else
    fail "Section 3: idempotence run failed with exit code $IDEM_RC"
  fi
fi

# ===========================================================================
# Section 4: Package snapshot validation and zero git drift (Plan 23-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Package snapshot validation and zero git drift ---"
  info "Section 4 scheduled for Plan 23-03 implementation"
fi

# ===========================================================================
# Section 5: Live host dry-run, PAIR_COUNT == 18, and verify --strict (Plan 23-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Live host dry-run, PAIR_COUNT == 18, and verify --strict ---"
  info "Section 5 scheduled for Plan 23-03 implementation"
fi

# ---------------------------------------------------------------------------
# Closing Self-Check: Porcelain Comparison (Pattern 2.8)
# ---------------------------------------------------------------------------
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
