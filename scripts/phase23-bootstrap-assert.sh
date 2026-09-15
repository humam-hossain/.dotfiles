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
# Section 2: Isolated scratch de-stubbing, backup manifest, and stow linking (Plan 23-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Isolated scratch de-stubbing, backup manifest, and stow linking ---"
  info "Section 2 scheduled for Plan 23-02 implementation"
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
