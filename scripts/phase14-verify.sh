#!/usr/bin/env bash
# Phase 14 post-adopt verify — proves the live adopt landed, against the running session.
#
# Constraints (Phase 14 ADOPT-02 / ADOPT-03 prohibitions):
#   - READ-ONLY against the live session and the operator's home. This script never
#     terminates a process, never asks the compositor to re-read or to set any
#     configuration value, and never writes anything under "$XDG". Every probe is an
#     observation; nothing here mutates its own subject to green a check.
#   - Never invokes ./arch/dots-hyprland.sh without --dry-run.
#   - Never reports a [PASS] for a condition it could not observe. An unobservable
#     condition emits [INFO] or [FINDING], never a pass and never a silent skip.
#     The same rule runs in the other direction: an unobservable condition is never
#     reported as a specific defect either. A compositor this script cannot reach
#     produces ONE failure saying so, not a wall of "the overlay did not load".
#   - The only environment this script writes is its own: it re-exports
#     HYPRLAND_INSTANCE_SIGNATURE inside this process so hyprctl talks to the
#     compositor that is actually running (see "live compositor resolution").
#     That is a correction to this shell's view, not a mutation of the session.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase14-verify.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.
#
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  observed condition recorded and dispositioned in 14-LIVE-VERIFY.md;
#              FINDINGS never move the exit code (D-14, D-38)
#   [INFO]     a condition this run could not observe, named rather than skipped

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
BASELINE=".planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt"
BACKUP_DIR="$HOME/ii-original-dots-backup"
WRAP="./arch/dots-hyprland.sh"

# --- fixture reader -----------------------------------------------------------
# After the install the live pre-adopt hyprland.conf no longer exists, so D-36 and
# D-37 are only provable against the recorded fixture. A missing fixture or a
# missing key is a loud hard failure, never an empty comparison that passes.
#
# baseline_value runs inside a command substitution, so an `exit` here would only
# leave the subshell and let the script sail on with an empty value. It therefore
# `return 1`s and every call site is written `X="$(baseline_value k)" || exit 1`.
# The fixture's existence is gated once, below, at the top level where exit works.
if [[ ! -f "$BASELINE" ]]; then
  printf '[FAIL] baseline fixture missing: %s\n' "$BASELINE" >&2
  printf '       Recorded by plan 14-01 before any mutation. Without it the D-36 and\n' >&2
  printf '       D-37 comparisons are circular: the live pre-adopt conf no longer exists.\n' >&2
  printf '       Aborting rather than comparing against nothing.\n' >&2
  exit 1
fi

baseline_value() {
  local key="$1" line
  line="$(grep -m1 -E "^${key}=" "$BASELINE" || true)"
  if [[ -z "$line" ]]; then
    printf '[FAIL] baseline key absent from %s: %s\n' "$BASELINE" "$key" >&2
    printf '       Fixture is present but incomplete. Aborting rather than comparing to empty.\n' >&2
    return 1
  fi
  printf '%s' "${line#*=}"
}

echo "=== Phase 14 post-adopt verify (read-only against the live session) ==="
echo "[CONFIG] repo_root=$REPO_ROOT"
echo "[CONFIG] xdg=$XDG"
echo "[CONFIG] baseline=$BASELINE"
echo "[CONFIG] backup_dir=$BACKUP_DIR"
BASELINE_CAPTURED="$(baseline_value baseline_captured)" || exit 1
HYPRLAND_CONF_SHA_PRE="$(baseline_value hyprland_conf_sha256)" || exit 1
echo "[CONFIG] baseline_captured=$BASELINE_CAPTURED"

# --- live compositor resolution ----------------------------------------------
# hyprctl resolves its socket path from $HYPRLAND_INSTANCE_SIGNATURE. A shell that
# was started before the operator's re-login still carries the PREVIOUS session's
# signature, so every hyprctl call fails with "Couldn't connect to
# /run/user/<uid>/hypr/<sig>/.socket.sock" — and hyprctl writes that refusal to
# STDOUT, exactly where a caller looks for an answer. Trusting the inherited value
# therefore turns one environment problem into a dozen false "the overlay did not
# load" defects, and turns the refusal string itself into a plausible-looking
# non-empty result.
#
# `hyprctl instances` does not read the env var: it enumerates the socket
# directory. Resolve the running instance from it and re-export the signature for
# the remainder of this process, so every probe below addresses the compositor
# that is actually running.
HYPR_LIVE=0
HYPR_SIG_INHERITED="${HYPRLAND_INSTANCE_SIGNATURE:-}"
HYPR_SIG_LIVE="$(hyprctl instances -j 2>/dev/null \
  | grep -o '"instance": *"[^"]*"' | head -1 \
  | sed 's/.*"instance": *"//; s/"$//' || true)"

if [[ -n "$HYPR_SIG_LIVE" ]]; then
  HYPR_LIVE=1
  export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG_LIVE"
  if [[ -z "$HYPR_SIG_INHERITED" ]]; then
    info "compositor live instance $HYPR_SIG_LIVE — this shell inherited no HYPRLAND_INSTANCE_SIGNATURE; resolved it from 'hyprctl instances'"
  elif [[ "$HYPR_SIG_INHERITED" != "$HYPR_SIG_LIVE" ]]; then
    info "compositor INHERITED HYPRLAND_INSTANCE_SIGNATURE '$HYPR_SIG_INHERITED' IS STALE — this shell predates the running session. Re-resolved to the live instance $HYPR_SIG_LIVE; every hyprctl probe below addresses the running compositor, not the dead socket."
  else
    info "compositor live instance $HYPR_SIG_LIVE — matches the signature this shell inherited"
  fi
else
  # ONE failure, named for what it is. The ADOPT-02 and ADOPT-03 hyprctl probes
  # below are then reported [INFO] "not observed" — neither passes nor defects.
  fail "compositor UNREACHABLE — 'hyprctl instances' reports no running Hyprland instance, so the ADOPT-02 configProvider and Lua-REPL probes and the ADOPT-03 monitor and workspace-rule assertions COULD NOT BE OBSERVED. They are reported below as [INFO], not as passes and not as defects. This shell inherited HYPRLAND_INSTANCE_SIGNATURE='${HYPR_SIG_INHERITED:-<unset>}'. Run this script from a terminal inside the live session, or from one started after the current login."
fi

# Emits hyprctl's JSON payload on stdout, or returns 1 when hyprctl did not answer
# with JSON. hyprctl prints its connection refusal to STDOUT, so a non-empty
# result is NOT evidence of success — the payload has to parse before any
# assertion is allowed to read it.
hypr_json() {
  local out
  out="$(hyprctl "$@" 2>/dev/null || true)"
  if [[ -z "$out" ]] || ! jq -e 'type' >/dev/null 2>&1 <<<"$out"; then
    return 1
  fi
  printf '%s' "$out"
}

# =============================================================================
# ADOPT-02 — the running session came from the ii Lua entry (D-33, three ways)
# =============================================================================

# 1. The rename happened.
if [[ -f "$XDG/hypr/hyprland.conf.old" ]]; then
  pass "ADOPT-02 hyprland.conf.old present: $XDG/hypr/hyprland.conf.old"
else
  fail "ADOPT-02 hyprland.conf.old missing — upstream's rename did not happen"
fi

# 2. The Lua entry installed.
if [[ -f "$XDG/hypr/hyprland.lua" ]]; then
  pass "ADOPT-02 hyprland.lua present: $XDG/hypr/hyprland.lua"
else
  fail "ADOPT-02 hyprland.lua missing — did --skip-hyprland-entry leak past the ban?"
fi

# 3. Nothing remains that could win over the Lua entry. Correct under either
#    reading of the 0.56.2 format preference (RESEARCH Open Question 1), and it
#    catches a failed rename directly.
if [[ ! -f "$XDG/hypr/hyprland.conf" ]]; then
  pass "ADOPT-02 hyprland.conf absent — no .conf can win over the Lua entry"
else
  fail "ADOPT-02 hyprland.conf still present at $XDG/hypr/hyprland.conf"
fi

# 4. The compositor names its own config provider. Assert the ABSENCE of the
#    recorded pre-adopt token, never the presence of a guessed post-adopt one:
#    the pre-adopt value is an observed fact, the post-adopt value is not.
CONFIG_PROVIDER_PRE="$(baseline_value configProvider_pre)" || exit 1
if [[ "$HYPR_LIVE" -eq 0 ]]; then
  info "ADOPT-02 configProvider probe NOT OBSERVED — compositor unreachable (see the single [FAIL] above). Recorded pre-adopt value was '$CONFIG_PROVIDER_PRE'."
else
  STATUS_JSON="$(hypr_json -j status)" || STATUS_JSON=""
  if [[ -z "$STATUS_JSON" ]]; then
    fail "ADOPT-02 hyprctl -j status did not return JSON even though an instance is live — the compositor answered, but not with a status payload"
    PROVIDER_LIVE=""
  else
    PROVIDER_LIVE="$(jq -r '.configProvider // empty' <<<"$STATUS_JSON")"
  fi
  if [[ -z "$STATUS_JSON" ]]; then
    : # already failed above; do not double-count
  elif [[ -z "$PROVIDER_LIVE" ]]; then
    fail "ADOPT-02 config provider unreadable — hyprctl -j status parsed but carried no configProvider key"
  elif [[ "$PROVIDER_LIVE" == "$CONFIG_PROVIDER_PRE" ]]; then
    fail "ADOPT-02 configProvider is still '$PROVIDER_LIVE' (recorded pre-adopt value) — session did not load the Lua entry"
  else
    pass "ADOPT-02 configProvider is '$PROVIDER_LIVE', no longer the recorded pre-adopt '$CONFIG_PROVIDER_PRE'"
  fi
fi

# 5. The Lua REPL, independent of any token. The Lua config manager answers a
#    well-formed expression with exactly "ok"; hyprlang refuses with "eval is only
#    supported with the lua config manager"; a dead socket answers "Couldn't
#    connect to ...". Assert the EXPECTED RETURN VALUE, never merely non-empty
#    output — hyprctl writes its refusals to stdout too, so "something came back"
#    is not evidence that anything worked.
HYPR_LUA_OK="ok"
if [[ "$HYPR_LIVE" -eq 0 ]]; then
  info "ADOPT-02 Lua REPL probe NOT OBSERVED — compositor unreachable (see the single [FAIL] above)"
else
  EVAL_OUT="$(hyprctl eval 'return 1+1' 2>&1 || true)"
  EVAL_OUT="${EVAL_OUT//$'\n'/ }"
  if [[ "$EVAL_OUT" == "$HYPR_LUA_OK" ]]; then
    pass "ADOPT-02 hyprctl eval 'return 1+1' returned the expected '$HYPR_LUA_OK' — the session is under the Lua config manager"
  elif [[ "$EVAL_OUT" == *"only supported with the lua config manager"* ]]; then
    fail "ADOPT-02 hyprctl eval refused — session is not under the Lua config manager: $EVAL_OUT"
  else
    fail "ADOPT-02 hyprctl eval returned '$EVAL_OUT', expected '$HYPR_LUA_OK' — not evidence the Lua config manager accepted it"
  fi
fi

# =============================================================================
# ADOPT-03 — the Phase 13 overlay LOADED, not merely got copied
#
# Overlay-declared values below are cited from .config/hypr/custom/general.lua
# (the authoring source of truth, see 13-SOT-APPLY.md). The guard immediately
# after re-reads that file so a drifted overlay is caught rather than silently
# compared against a stale constant.
# =============================================================================

OVERLAY_GENERAL=".config/hypr/custom/general.lua"
HDMI_A2_SCALE_DECLARED="1.5"
HDMI_A2_TRANSFORM_DECLARED="1"

if [[ -f "$OVERLAY_GENERAL" ]] \
  && grep -q "scale = ${HDMI_A2_SCALE_DECLARED}" "$OVERLAY_GENERAL" \
  && grep -q "transform = ${HDMI_A2_TRANSFORM_DECLARED}" "$OVERLAY_GENERAL"; then
  pass "ADOPT-03 overlay source declares HDMI-A-2 scale=${HDMI_A2_SCALE_DECLARED} transform=${HDMI_A2_TRANSFORM_DECLARED}: $OVERLAY_GENERAL"
else
  finding "ADOPT-03 overlay source $OVERLAY_GENERAL no longer declares HDMI-A-2 scale=${HDMI_A2_SCALE_DECLARED} transform=${HDMI_A2_TRANSFORM_DECLARED} — the constants below may be stale"
fi

# A refusal string is not a monitor list. MONITORS_JSON is only trusted once it
# has parsed as JSON, and the monitor assertions only run once it has.
MONITORS_JSON=""
if [[ "$HYPR_LIVE" -eq 1 ]]; then
  MONITORS_JSON="$(hypr_json -j monitors all)" || MONITORS_JSON=""
  if [[ -z "$MONITORS_JSON" ]]; then
    fail "ADOPT-03 hyprctl -j monitors all did not return JSON even though an instance is live"
  fi
fi

DP1_SCALE_PRE="$(baseline_value dp1_scale_pre)" || exit 1

if [[ -z "$MONITORS_JSON" ]]; then
  info "ADOPT-03 monitor assertions NOT OBSERVED — no monitor list to read. DP-1 presence, its scale (pre-adopt $DP1_SCALE_PRE) and the HDMI-A-2 comparison are unproven, neither passed nor failed."
else
  # DP-1 presence is unconditional and enforced.
  if jq -e '.[] | select(.name=="DP-1")' >/dev/null 2>&1 <<<"$MONITORS_JSON"; then
    pass "ADOPT-03 DP-1 present in hyprctl -j monitors all"
  else
    fail "ADOPT-03 DP-1 missing from hyprctl -j monitors all"
  fi

  # DP-1 scale is RECORDED, never enforced (D-14): a wrong scale is a Phase 15 item.
  DP1_SCALE_LIVE="$(jq -r '.[] | select(.name=="DP-1") | .scale' <<<"$MONITORS_JSON" 2>/dev/null || true)"
  if [[ -z "$DP1_SCALE_LIVE" ]]; then
    finding "ADOPT-03 DP-1 scale unreadable — recorded pre-adopt value was $DP1_SCALE_PRE (D-14, record and defer)"
  elif [[ "$DP1_SCALE_LIVE" == "$DP1_SCALE_PRE" || "$DP1_SCALE_LIVE" == "${DP1_SCALE_PRE}.0" ]]; then
    pass "ADOPT-03 DP-1 scale unchanged at $DP1_SCALE_LIVE (pre-adopt $DP1_SCALE_PRE)"
  else
    finding "ADOPT-03 DP-1 scale is $DP1_SCALE_LIVE, pre-adopt was $DP1_SCALE_PRE — recorded, not a blocker (D-14). Phase 15 item."
  fi

  # HDMI-A-2 is conditional: absent is an observability gap, named rather than skipped.
  if jq -e '.[] | select(.name=="HDMI-A-2")' >/dev/null 2>&1 <<<"$MONITORS_JSON"; then
    HDMI_SCALE_LIVE="$(jq -r '.[] | select(.name=="HDMI-A-2") | .scale' <<<"$MONITORS_JSON")"
    HDMI_TRANSFORM_LIVE="$(jq -r '.[] | select(.name=="HDMI-A-2") | .transform' <<<"$MONITORS_JSON")"
    info "ADOPT-03 verification ran in DUAL-HEAD mode — HDMI-A-2 is attached"
    if [[ "$HDMI_SCALE_LIVE" == "$HDMI_A2_SCALE_DECLARED" \
       && "$HDMI_TRANSFORM_LIVE" == "$HDMI_A2_TRANSFORM_DECLARED" ]]; then
      pass "ADOPT-03 HDMI-A-2 scale $HDMI_SCALE_LIVE transform $HDMI_TRANSFORM_LIVE match the overlay"
    else
      finding "ADOPT-03 HDMI-A-2 is scale $HDMI_SCALE_LIVE transform $HDMI_TRANSFORM_LIVE, overlay declares scale $HDMI_A2_SCALE_DECLARED transform $HDMI_A2_TRANSFORM_DECLARED — recorded, not a blocker"
    fi
  else
    info "ADOPT-03 verification ran in SINGLE-HEAD mode — HDMI-A-2 absent from hyprctl -j monitors all, so its scale/transform assertion could not be observed and was NOT counted as a pass"
  fi
fi

# Workspace rules are enforced independently of which monitors are attached:
# hyprctl reports rules for monitors that are not connected, so all eleven are
# checkable single-headed. Their presence in the RUNNING compositor is what proves
# the overlay loaded rather than merely having been copied (D-33 reasoning applied
# to ADOPT-03). The one thing that suspends them is an unreadable rule list.
WSRULES_JSON=""
if [[ "$HYPR_LIVE" -eq 1 ]]; then
  WSRULES_JSON="$(hypr_json -j workspacerules)" || WSRULES_JSON=""
  if [[ -z "$WSRULES_JSON" ]]; then
    fail "ADOPT-03 hyprctl -j workspacerules did not return JSON even though an instance is live"
  fi
fi
# workspace -> monitor, verbatim from .config/hypr/custom/general.lua:17-27
WS_EXPECT=(
  "1=DP-1" "2=DP-1" "3=DP-1" "4=DP-1" "5=DP-1" "special:social=DP-1"
  "6=HDMI-A-2" "7=HDMI-A-2" "8=HDMI-A-2" "9=HDMI-A-2" "10=HDMI-A-2"
)
if [[ -z "$WSRULES_JSON" ]]; then
  # "The compositor did not answer" and "the overlay did not load" are different
  # claims. Emitting eleven per-rule defects for an unread rule list would assert
  # the second from evidence for neither — the mirror image of a false pass.
  info "ADOPT-03 Workspace rule assertions NOT OBSERVED (${#WS_EXPECT[@]} rules unproven) — no rule list to read. This is an observability gap, NOT evidence the overlay failed to load."
else
  for entry in "${WS_EXPECT[@]}"; do
    ws="${entry%%=*}"
    want_mon="${entry#*=}"
    got_mon="$(jq -r --arg ws "$ws" '.[] | select(.workspaceString==$ws) | .monitor // "<unset>"' <<<"$WSRULES_JSON" 2>/dev/null || true)"
    if [[ -z "$got_mon" ]]; then
      fail "ADOPT-03 Workspace rule $ws missing from the running compositor — overlay did not load"
    elif [[ "$got_mon" == "$want_mon" ]]; then
      pass "ADOPT-03 Workspace rule $ws live on $got_mon"
    else
      finding "ADOPT-03 Workspace rule $ws is live but resolves to '$got_mon', overlay declares '$want_mon'"
    fi
  done
fi

# Shell chrome. Dual-run policy is accept-remove (Phase 11 D-11 overrides DISP-03):
# the ii shell runs and the Waybar/rofi/swaync stack does not.
if pgrep -f 'qs -c ii' >/dev/null 2>&1; then
  pass "ADOPT-03 ii shell running: qs -c ii"
else
  fail "ADOPT-03 ii shell not running: qs -c ii"
fi
# pgrep exits 1 for "no match" but 2, 3 and 127 for usage errors and a missing
# binary. Collapsing all of them into the else branch reports a PASS for a
# condition nobody observed. Only exit 1 means "checked, absent".
check_not_running() {
  # $1 = process name
  local rc
  pgrep -x "$1" >/dev/null 2>&1 && rc=0 || rc=$?
  case "$rc" in
    0) fail "ADOPT-03 $1 still running — Waybar/rofi/swaync dual-run policy is accept-remove" ;;
    1) pass "ADOPT-03 $1 not running (Waybar/rofi/swaync accept-remove)" ;;
    *) finding "ADOPT-03 pgrep -x $1 exited $rc — neither running nor absent was observed" ;;
  esac
}
check_not_running waybar
check_not_running swaync
# rofi never had an exec-once (RESEARCH Pitfall 6), so its absence is vacuous and
# its presence would be the surprise. Recorded, never enforced.
if pgrep -x rofi >/dev/null 2>&1; then
  finding "ADOPT-03 a rofi process is running — unexpected, it never had an autostart in the archived conf"
else
  info "ADOPT-03 rofi not running — vacuous, it never had an autostart; the real check is the launcher keybind (human)"
fi

# =============================================================================
# Pre-adopt conf evidence, and the surviving removal path
#
# The two pre-adopt conf copies are still hashed against the recorded fixture.
# The wrapper's own removal path is still probed dry-run only — this suite
# never rehearses a restore. Phase 16 retired the tiered-rollback promise these
# probes used to be labelled under; the probes themselves are unchanged, only
# their framing (D-20, D-10).
# =============================================================================

UNINST_OUT="$(mktemp /tmp/p14-verify-uninst-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$UNINST_OUT"' EXIT

REPO_HYPRCONF=".config/hypr/hyprland.conf"

# Presence is not identity. The record claims all three tier-1 sources carry the
# pre-adopt sha256, so the instrument must hash them -- a `-s` test would keep
# printing PASS after either source drifted, and source 2 is a live hook-injection
# target, so drift there has a real mechanism.
check_tier1_source() {
  # $1 = source label, $2 = path
  if [[ ! -s "$2" ]]; then
    fail "D-20 pre-adopt conf source $1 missing or empty: $2"
    return
  fi
  local sha
  sha="$(sha256sum "$2" | cut -d' ' -f1)"
  if [[ "$sha" == "$HYPRLAND_CONF_SHA_PRE" ]]; then
    pass "D-20 pre-adopt conf source $1 present and sha256 matches the pre-adopt fixture: $2"
  else
    fail "D-20 pre-adopt conf source $1 is $sha, fixture recorded $HYPRLAND_CONF_SHA_PRE (captured $BASELINE_CAPTURED) -- $2 is not the pre-adopt conf"
  fi
}
check_tier1_source 1 "$XDG/hypr/hyprland.conf.old"
check_tier1_source 2 "$REPO_HYPRCONF"

if printf '' | "$WRAP" uninstall --dry-run >"$UNINST_OUT" 2>&1; then
  pass "D-10 wrapper removal path still reachable: uninstall --dry-run exits 0"
else
  fail "D-10 wrapper removal path unreachable: uninstall --dry-run exited non-zero"
  sed -n '1,40p' "$UNINST_OUT" || true
fi

# =============================================================================
# D-37 — Phase 11 D-24 held: hyprlock/hypridle untouched, sidecars unpromoted
#
# A byte or hash mismatch means upstream took the INSTALL_FIRSTRUN branch and
# replaced the live files instead of writing .new sidecars. Hard failure.
# =============================================================================

HYPRLOCK_SHA_PRE="$(baseline_value hyprlock_conf_sha256)" || exit 1
HYPRLOCK_BYTES_PRE="$(baseline_value hyprlock_conf_bytes)" || exit 1
HYPRIDLE_SHA_PRE="$(baseline_value hypridle_conf_sha256)" || exit 1
HYPRIDLE_BYTES_PRE="$(baseline_value hypridle_conf_bytes)" || exit 1

check_untouched() {
  local label="$1" path="$2" want_bytes="$3" want_sha="$4" got_bytes got_sha
  if [[ ! -f "$path" ]]; then
    fail "D-37 $label missing: $path"
    return 0
  fi
  got_bytes="$(stat -c '%s' "$path")"
  got_sha="$(sha256sum "$path" | cut -d' ' -f1)"
  if [[ "$got_bytes" == "$want_bytes" && "$got_sha" == "$want_sha" ]]; then
    pass "D-37 $label byte-identical to the pre-adopt fixture ($got_bytes bytes, $got_sha)"
  else
    fail "D-37 $label changed: $got_bytes bytes / $got_sha, fixture recorded $want_bytes bytes / $want_sha — the firstrun path fired and Phase 11 D-24 did not hold"
  fi
}
check_untouched "hyprlock.conf" "$XDG/hypr/hyprlock.conf" "$HYPRLOCK_BYTES_PRE" "$HYPRLOCK_SHA_PRE"
check_untouched "hypridle.conf" "$XDG/hypr/hypridle.conf" "$HYPRIDLE_BYTES_PRE" "$HYPRIDLE_SHA_PRE"

check_sidecar() {
  local label="$1" live="$2" sidecar="$3"
  if [[ ! -f "$sidecar" ]]; then
    fail "D-37 $label sidecar missing: $sidecar — the not-firstrun branch did not run"
    return 0
  fi
  pass "D-37 $label sidecar present and unmerged: $sidecar"
  if [[ "$(sha256sum "$sidecar" | cut -d' ' -f1)" == "$(sha256sum "$live" | cut -d' ' -f1)" ]]; then
    fail "D-37 $label sidecar has been promoted over its live counterpart: $sidecar == $live"
  else
    pass "D-37 $label sidecar not promoted — live copy still differs from it"
  fi
}
check_sidecar "hyprlock.conf" "$XDG/hypr/hyprlock.conf" "$XDG/hypr/hyprlock.conf.new"
check_sidecar "hypridle.conf" "$XDG/hypr/hypridle.conf" "$XDG/hypr/hypridle.conf.new"

# =============================================================================
# D-38 — named known losses and the screen-share probe
#
# Every check in this block routes to finding() or info() and NEVER to fail().
# A broken screen share is a recorded Phase 15 item, the same treatment the
# DP-1 scale gets under D-14.
# =============================================================================

if systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
  info "D-38 graphical-session.target is active"
else
  finding "D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). This is why screen share may be broken. Phase 15 item."
fi

SCREENCAST_PRE="$(baseline_value screencast_source_types_pre)" || exit 1
SCREENCAST_LIVE="$(busctl --user get-property org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop org.freedesktop.portal.ScreenCast \
  AvailableSourceTypes 2>/dev/null || true)"
if [[ -z "$SCREENCAST_LIVE" ]]; then
  finding "D-38 ScreenCast portal did not answer AvailableSourceTypes — screen share broken. Recorded, deferred to Phase 15."
elif [[ "$SCREENCAST_LIVE" == "$SCREENCAST_PRE" ]]; then
  info "D-38 ScreenCast portal answers AvailableSourceTypes = '$SCREENCAST_LIVE', unchanged from pre-adopt"
else
  finding "D-38 ScreenCast portal answers AvailableSourceTypes = '$SCREENCAST_LIVE', pre-adopt was '$SCREENCAST_PRE' — recorded, deferred to Phase 15."
fi

SESSION_UNIT="stow/systemd/.config/systemd/user/hyprland-session.service"
if [[ -f "$SESSION_UNIT" ]]; then
  info "D-38 the personal session unit file SURVIVES in the repo at $SESSION_UNIT — only its autostart line is gone, this is not a deletion"
else
  finding "D-38 personal session unit file absent from the repo: $SESSION_UNIT"
fi

# Named known losses. Each is probed and reported as observed — never asserted
# from the runbook's expectation alone.
if pgrep -x wl-clip-persist >/dev/null 2>&1; then
  info "D-38 known loss 'wl-clip-persist': process is running despite its exec-once being gone"
else
  info "D-38 known loss 'wl-clip-persist' CONFIRMED not running — its exec-once went with the renamed conf (expected)"
fi
for known in btop vesktop discord; do
  if pgrep -x "$known" >/dev/null 2>&1; then
    info "D-38 known loss (workspace-pinned autostart) '$known': running"
  else
    info "D-38 known loss (workspace-pinned autostart) '$known' CONFIRMED not running (expected)"
  fi
done
info "D-38 known loss (workspace-pinned autostart) 'google-chrome-stable on workspace 1' — the archived conf's four pinned autostarts all went with the rename (expected)"
if pgrep -x hyprpaper >/dev/null 2>&1; then
  info "D-38 known loss 'hyprpaper': running"
elif command -v hyprpaper >/dev/null 2>&1; then
  info "D-38 known loss 'hyprpaper' CONFIRMED stopped-but-INSTALLED — the binary is on PATH and hyprpaper.conf survives; nothing starts it. Wallpaper is Quickshell's job now, not breakage."
else
  finding "D-38 hyprpaper is neither running nor on PATH — it was expected to remain installed because it was installed as part of the personal stack; the wrapper capability that used to protect that stack from an orphan sweep was retired in Phase 16"
fi

LIVE_LAUNCHER="$XDG/hypr/hyprland/scripts/launch_first_available.sh"
REPO_LAUNCHER=".config/hypr/hyprland/scripts/launch_first_available.sh"
if [[ ! -f "$LIVE_LAUNCHER" ]]; then
  info "D-38 known loss 'hyprland/scripts/launch_first_available.sh' CONFIRMED deleted from live; the personal copy is tracked at repo $REPO_LAUNCHER"
elif cmp -s "$LIVE_LAUNCHER" "$REPO_LAUNCHER"; then
  info "D-38 'hyprland/scripts/launch_first_available.sh' survived live and is byte-identical to repo $REPO_LAUNCHER — no loss"
else
  info "D-38 known loss 'hyprland/scripts/launch_first_available.sh' CONFIRMED overwritten by upstream's copy ($(stat -c '%s' "$LIVE_LAUNCHER") bytes live vs $(stat -c '%s' "$REPO_LAUNCHER") bytes in the repo); the personal version is tracked at repo $REPO_LAUNCHER"
fi

# =============================================================================
# D-35 — the working tree is clean apart from this phase's own artifacts
# =============================================================================

PHASE14_PREFIX=".planning/phases/14-live-full-adopt-verify/"
PORCELAIN_ALL="$(git status --porcelain || true)"
DIRTY_OUTSIDE=""
while IFS= read -r porcelain_line; do
  [[ -z "$porcelain_line" ]] && continue
  entry_path="${porcelain_line:3}"
  entry_path="${entry_path##* -> }"
  entry_path="${entry_path%\"}"
  entry_path="${entry_path#\"}"
  case "$entry_path" in
    "$PHASE14_PREFIX"*) continue ;;
  esac
  DIRTY_OUTSIDE+="$porcelain_line"$'\n'
done <<<"$PORCELAIN_ALL"

if [[ -z "${DIRTY_OUTSIDE//[[:space:]]/}" ]]; then
  pass "D-35 git status --porcelain is clean apart from paths under $PHASE14_PREFIX"
else
  fail "D-35 working tree is dirty outside $PHASE14_PREFIX — review the diff, commit it, and record the fact as a finding in 14-LIVE-VERIFY.md"
  printf '%s' "$DIRTY_OUTSIDE" | sed '/^$/d; s/^/       /'
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
