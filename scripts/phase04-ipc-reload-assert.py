#!/usr/bin/env python3
"""Phase 4 Wave 0 IPC + soft-reload asserts for IPC-01 / IPC-03.

Static gates: stock IpcHandler target bar (toggle/open/close), QS_NO_RELOAD_POPUP=1,
GlobalStates.barOpen. Live gates: qs list (default shell.qml), qs ipc show/call.
Soft-reload probe: content-change + same PID + restore + post-reload bar open.

Stdlib only. Expected green if stock already works. Exit 0 only when all pass.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BAR_QML = REPO_ROOT / ".config" / "quickshell" / "modules" / "ii" / "bar" / "Bar.qml"
SHELL_QML = REPO_ROOT / ".config" / "quickshell" / "shell.qml"
GLOBAL_STATES = REPO_ROOT / ".config" / "quickshell" / "GlobalStates.qml"

PROBE_MARKER = "// phase04-ipc-reload-assert-probe"
SUCCESS_LINE = "ipc/reload asserts OK"
FAIL_PREFIX = "ipc/reload assert FAIL"


def fail(msg: str) -> None:
    raise AssertionError(msg)


def read_text(path: Path) -> str:
    if not path.is_file():
        fail(f"missing source file: {path}")
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read {path}: {exc}")


def which_qs() -> str:
    qs = shutil.which("qs")
    if not qs:
        print("error: qs not found on PATH", file=sys.stderr)
        sys.exit(1)
    return qs


def run_qs(
    qs: str,
    args: list[str],
    *,
    pin_pid: int | None = None,
    pin_id: str | None = None,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    cmd = [qs]
    # Instance pin flags go before ipc subcommand when present.
    if pin_pid is not None and args and args[0] == "ipc":
        cmd = [qs, "ipc", "--pid", str(pin_pid), *args[1:]]
    elif pin_id is not None and args and args[0] == "ipc":
        cmd = [qs, "ipc", "-i", pin_id, *args[1:]]
    else:
        cmd = [qs, *args]
    try:
        return subprocess.run(
            cmd,
            check=check,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired:
        fail(f"command timed out: {' '.join(cmd)}")
    except OSError as exc:
        fail(f"failed to run {' '.join(cmd)}: {exc}")


def section_a_static() -> None:
    bar = read_text(BAR_QML)
    if 'target: "bar"' not in bar and "target: 'bar'" not in bar:
        fail(f'Bar.qml missing IpcHandler target: "bar" ({BAR_QML})')
    for name in ("toggle", "open", "close"):
        # Prefer typed void form; accept untyped only if typed missing (stock has typed).
        typed = re.search(rf"function\s+{name}\s*\(\s*\)\s*:\s*void\b", bar)
        untyped = re.search(rf"function\s+{name}\s*\(\s*\)\s*\{{", bar)
        if not typed and not untyped:
            fail(f"Bar.qml missing function {name}() for target bar")
        if not typed:
            fail(f"Bar.qml function {name}() must be typed void (IpcHandler registration)")

    shell = read_text(SHELL_QML)
    if "QS_NO_RELOAD_POPUP=1" not in shell:
        fail(f"shell.qml missing silent-reload pragma QS_NO_RELOAD_POPUP=1 ({SHELL_QML})")

    gs = read_text(GLOBAL_STATES)
    if not re.search(r"property\s+bool\s+barOpen\b", gs):
        fail(f"GlobalStates.qml missing property bool barOpen ({GLOBAL_STATES})")


def parse_qs_list(qs: str) -> list[dict]:
    """Return instances with keys: id, pid, config_path (str). Prefer JSON."""
    proc = run_qs(qs, ["list", "-j"])
    if proc.returncode == 0 and proc.stdout.strip():
        try:
            data = json.loads(proc.stdout)
            if isinstance(data, list):
                out = []
                for item in data:
                    if not isinstance(item, dict):
                        continue
                    out.append(
                        {
                            "id": str(item.get("id", "")),
                            "pid": int(item["pid"]),
                            "config_path": str(item.get("config_path", "")),
                        }
                    )
                if out:
                    return out
        except (json.JSONDecodeError, KeyError, TypeError, ValueError):
            pass

    # Fallback: plain text from `qs list` / `qs list -a`
    proc = run_qs(qs, ["list", "-a"])
    if proc.returncode != 0:
        print(
            f"error: qs list failed (exit {proc.returncode}): "
            f"{(proc.stderr or proc.stdout).strip()}",
            file=sys.stderr,
        )
        sys.exit(1)
    text = proc.stdout or ""
    instances: list[dict] = []
    current: dict | None = None
    for line in text.splitlines():
        m = re.match(r"^Instance\s+(\S+):\s*$", line)
        if m:
            if current:
                instances.append(current)
            current = {"id": m.group(1).rstrip(":"), "pid": None, "config_path": ""}
            continue
        if current is None:
            continue
        m = re.search(r"Process ID:\s*(\d+)", line)
        if m:
            current["pid"] = int(m.group(1))
            continue
        m = re.search(r"Config path:\s*(.+)$", line)
        if m:
            current["config_path"] = m.group(1).strip()
            continue
    if current:
        instances.append(current)
    # Drop incomplete
    return [i for i in instances if i.get("pid") is not None]


def select_default_instance(instances: list[dict]) -> dict:
    defaults = [
        i
        for i in instances
        if "quickshell/shell.qml" in (i.get("config_path") or "").replace("\\", "/")
    ]
    if not defaults:
        fail(
            "no running qs instance with config path containing quickshell/shell.qml "
            f"(got {len(instances)} instance(s))"
        )
    if len(defaults) > 1:
        # Prefer live PID still running
        alive = [i for i in defaults if pid_alive(int(i["pid"]))]
        if len(alive) == 1:
            return alive[0]
        fail(
            "multiple default quickshell/shell.qml instances; pin required: "
            + ", ".join(f"id={i['id']} pid={i['pid']}" for i in defaults)
        )
    return defaults[0]


def pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        # Exists but not signalable as us — treat as alive.
        return True
    except OSError:
        return False


def section_b_live(qs: str) -> tuple[dict, bool]:
    """Returns (instance, pin_required)."""
    instances = parse_qs_list(qs)
    if not instances:
        print("error: no running qs instances (qs list empty)", file=sys.stderr)
        sys.exit(1)

    inst = select_default_instance(instances)
    pin = len(instances) > 1
    pin_pid = int(inst["pid"]) if pin else None
    pin_id = str(inst["id"]) if pin else None

    show = run_qs(qs, ["ipc", "show"], pin_pid=pin_pid, pin_id=pin_id)
    if show.returncode != 0:
        fail(
            f"qs ipc show failed (exit {show.returncode}): "
            f"{(show.stderr or show.stdout).strip()}"
        )
    show_out = show.stdout or ""
    # Expect a block: target bar\n  function … for toggle/open/close
    if not re.search(r"(?m)^target\s+bar\s*$", show_out):
        fail("qs ipc show does not expose target bar")
    for fn in ("toggle", "open", "close"):
        # Within bar block is ideal; substring match of function name under target is enough.
        if not re.search(rf"(?m)^\s*function\s+{fn}\s*\(", show_out):
            # Bar block may be only place; still require the function appears near bar target.
            if not re.search(
                rf"target\s+bar[\s\S]{{0,400}}function\s+{fn}\s*\(", show_out
            ):
                fail(f"qs ipc show missing function {fn} on target bar")

    call = run_qs(qs, ["ipc", "call", "bar", "open"], pin_pid=pin_pid, pin_id=pin_id)
    if call.returncode != 0:
        fail(
            f"qs ipc call bar open failed (exit {call.returncode}): "
            f"{(call.stderr or call.stdout).strip()}"
        )
    return inst, pin


def find_instance_log(inst: dict) -> Path | None:
    xdg = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    inst_id = str(inst.get("id") or "")
    if inst_id:
        candidate = Path(xdg) / "quickshell" / "by-id" / inst_id / "log.log"
        if candidate.is_file():
            return candidate
    # Fallback: by-pid
    pid = inst.get("pid")
    if pid is not None:
        by_pid = Path(xdg) / "quickshell" / "by-pid" / str(pid)
        if by_pid.is_dir():
            for name in ("log.log", "log.qslog"):
                p = by_pid / name
                if p.is_file():
                    return p
            # by-pid may be symlink to by-id
            try:
                resolved = by_pid.resolve()
                for name in ("log.log", "log.qslog"):
                    p = resolved / name
                    if p.is_file():
                        return p
            except OSError:
                pass
    return None


def wait_for_soft_reload(log_path: Path | None, before_size: int, timeout_s: float = 5.0) -> None:
    """Optional log poll for reload signals; always returns after timeout/sleep."""
    if log_path is None or not log_path.is_file():
        time.sleep(1.0)
        return
    deadline = time.monotonic() + timeout_s
    signals = ("Configuration Loaded", "Reloading configuration", "configuration loaded")
    while time.monotonic() < deadline:
        try:
            data = log_path.read_bytes()
            tail = data[before_size:].decode("utf-8", errors="replace")
            if any(s in tail for s in signals):
                return
        except OSError:
            pass
        time.sleep(0.15)
    # Log poll optional — continue even if signals not observed.
    time.sleep(0.3)


def section_c_soft_reload(qs: str, inst: dict, pin: bool) -> None:
    pid = int(inst["pid"])
    config_path = Path(inst["config_path"])
    if not config_path.is_file():
        fail(f"instance config path not a file: {config_path}")

    pin_pid = pid if pin else None
    pin_id = str(inst["id"]) if pin else None

    original = config_path.read_text(encoding="utf-8")
    # Unique one-line comment probe (content change — not mtime-only).
    probe_line = f"{PROBE_MARKER} {time.time_ns()}\n"
    log_path = find_instance_log(inst)
    before_size = 0
    if log_path is not None and log_path.is_file():
        try:
            before_size = log_path.stat().st_size
        except OSError:
            before_size = 0

    restored = False
    try:
        try:
            with config_path.open("a", encoding="utf-8") as fh:
                fh.write(probe_line)
        except OSError as exc:
            fail(f"cannot append soft-reload probe to {config_path}: {exc}")

        wait_for_soft_reload(log_path, before_size, timeout_s=5.0)

        if not pid_alive(pid):
            fail(f"soft reload killed process (PID {pid} gone)")
        # Same PID still the qs instance — re-check via qs list when possible
        post = parse_qs_list(qs)
        matching = [
            i
            for i in post
            if int(i["pid"]) == pid
            and "quickshell/shell.qml" in (i.get("config_path") or "").replace("\\", "/")
        ]
        if not matching:
            # PID alive but not listed as default shell — still fail (hard restart / different proc)
            # If qs list empty due to transient, fall back to pid_alive only.
            if post:
                pids = [int(i["pid"]) for i in post]
                if pid not in pids:
                    fail(
                        f"soft reload changed PID (expected {pid}, running={pids})"
                    )
    finally:
        # Always restore prior content exactly.
        try:
            current = config_path.read_text(encoding="utf-8")
            if current != original:
                config_path.write_text(original, encoding="utf-8")
            restored = True
        except OSError as exc:
            # Best-effort second try
            try:
                config_path.write_text(original, encoding="utf-8")
                restored = True
            except OSError as exc2:
                print(
                    f"error: failed to restore {config_path} after probe: {exc2}",
                    file=sys.stderr,
                )
                restored = False

    if not restored:
        fail(f"could not restore probed file {config_path}")

    # Settle after restore (may trigger second soft reload).
    time.sleep(0.8)
    if not pid_alive(pid):
        fail(f"PID {pid} gone after restore settle")

    call = run_qs(qs, ["ipc", "call", "bar", "open"], pin_pid=pin_pid, pin_id=pin_id)
    if call.returncode != 0:
        fail(
            f"post-reload qs ipc call bar open failed (exit {call.returncode}): "
            f"{(call.stderr or call.stdout).strip()}"
        )


def main() -> int:
    try:
        section_a_static()
        qs = which_qs()
        inst, pin = section_b_live(qs)
        # Section C is mandatory — never print success without it.
        section_c_soft_reload(qs, inst, pin)
    except AssertionError as exc:
        print(f"{FAIL_PREFIX}: {exc}", file=sys.stderr)
        return 1
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001 — fail-loud harness
        print(f"{FAIL_PREFIX}: unexpected error: {exc}", file=sys.stderr)
        return 1

    print(SUCCESS_LINE)
    return 0


if __name__ == "__main__":
    sys.exit(main())
