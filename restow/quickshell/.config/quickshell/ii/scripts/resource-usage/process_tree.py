#!/usr/bin/env python3
"""
Lightweight process tree and DRM GPU memory attribution scanner.
Aggregates multi-process applications under application roots and
calculates delta CPU ticks and DRM resident memory in < 50ms.
Outputs JSON for Quickshell consumption.
"""

import os
import sys
import json
import time

def main():
    now = time.time()
    num_cpus = os.cpu_count() or 1
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    state_path = os.path.join(runtime_dir, "qs_proc_state.json")

    prev_state = None
    if os.path.exists(state_path):
        try:
            with open(state_path, "r") as f:
                prev_state = json.load(f)
        except Exception:
            prev_state = None

    # Read system total ticks from /proc/stat
    sys_ticks = 0
    try:
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("cpu "):
                    sys_ticks = sum(map(int, line.split()[1:9]))
                    break
    except OSError:
        pass

    procs = {}
    try:
        pids = [int(p) for p in os.listdir("/proc") if p.isdigit()]
    except OSError:
        pids = []

    # 1. Parse /proc/[pid]/stat for all processes
    for pid in pids:
        try:
            with open(f"/proc/{pid}/stat", "r") as f:
                content = f.read()
                rp = content.rfind(")")
                if rp == -1:
                    continue
                comm = content[content.find("(") + 1 : rp]
                rest = content[rp + 2 :].split()
                if len(rest) < 20:
                    continue
                ppid = int(rest[1])
                utime = int(rest[11])
                stime = int(rest[12])
                starttime = int(rest[19])
                procs[pid] = {
                    "pid": pid,
                    "ppid": ppid,
                    "comm": comm,
                    "ticks": utime + stime,
                    "starttime": starttime,
                    "cpu": 0.0,
                    "gpu_mem_kib": 0
                }
        except (OSError, IndexError, ValueError):
            continue

    # 2. Targeted DRM GPU memory accounting via /proc/[pid]/fd
    for pid, pdata in procs.items():
        if pid == 2 or pdata["ppid"] == 2:
            continue
        fd_dir = f"/proc/{pid}/fd"
        try:
            dri_fds = []
            for fd in os.listdir(fd_dir):
                try:
                    target = os.readlink(f"{fd_dir}/{fd}")
                    if "/dev/dri/" in target:
                        dri_fds.append(fd)
                except OSError:
                    pass

            if dri_fds:
                seen_clients = set()
                total_kib = 0
                for fd in dri_fds:
                    try:
                        with open(f"/proc/{pid}/fdinfo/{fd}", "r") as f:
                            cid = None
                            res = 0
                            for line in f:
                                if line.startswith("drm-client-id:"):
                                    cid = line.split(":", 1)[1].strip()
                                elif line.startswith("drm-resident-"):
                                    parts = line.split(":", 1)[1].strip().split()
                                    if parts:
                                        res += int(parts[0])
                            if cid and cid not in seen_clients:
                                seen_clients.add(cid)
                                total_kib += res
                    except (OSError, ValueError):
                        pass
                procs[pid]["gpu_mem_kib"] = total_kib
        except OSError:
            pass

    # 3. Calculate CPU % (Delta vs Previous run state)
    if prev_state and (now - prev_state.get("time", 0)) < 10.0 and sys_ticks > prev_state.get("sys_ticks", 0):
        d_sys = sys_ticks - prev_state["sys_ticks"]
        prev_pids = prev_state.get("pids", {})
        for pid, pdata in procs.items():
            spid = str(pid)
            if spid in prev_pids:
                prev_val = prev_pids[spid]
                prev_ticks = prev_val[0] if isinstance(prev_val, list) else prev_val
                d_proc = max(0, pdata["ticks"] - prev_ticks)
                pdata["cpu"] = max(0.0, round((d_proc / d_sys) * 100.0 * num_cpus, 1))
    else:
        # Fallback to lifetime average on first frame or stale state
        for pid, pdata in procs.items():
            elapsed = max(1, sys_ticks - pdata["starttime"])
            pdata["cpu"] = max(0.0, round((pdata["ticks"] / elapsed) * 100.0 * num_cpus, 1))

    # Save state for next delta
    try:
        new_state = {
            "time": now,
            "sys_ticks": sys_ticks,
            "pids": {str(p): (d["ticks"], d["starttime"]) for p, d in procs.items()}
        }
        tmp_state = state_path + ".tmp"
        with open(tmp_state, "w") as f:
            json.dump(new_state, f)
        os.replace(tmp_state, state_path)
    except OSError:
        pass

    # 4. Build application root clusters
    SYSTEM_ROOTS = {"systemd", "init", "hyprland", "Hyprland", "login", "pipewire", "seatd", "(sd-pam)"}
    TERMINAL_EMULATORS = {"kitty", "alacritty", "foot", "wezterm", "gnome-terminal", "konsole"}

    def find_app_root(pid):
        curr = pid
        visited = set()
        while curr not in visited:
            visited.add(curr)
            d = procs.get(curr)
            if not d or d["ppid"] <= 1:
                return curr
            pd = procs.get(d["ppid"])
            if not pd:
                return curr
            if pd["comm"] in SYSTEM_ROOTS or "systemd" in pd["comm"]:
                return curr
            if pd["comm"] in TERMINAL_EMULATORS:
                return curr
            if d["comm"] == pd["comm"] or pd["comm"] in ("sh", "bash", "zsh", "fish"):
                curr = d["ppid"]
                continue
            curr = d["ppid"]
        return curr

    clusters = {}
    for pid in procs:
        root_pid = find_app_root(pid)
        clusters.setdefault(root_pid, []).append(pid)

    aggregated = []
    for root_pid, members in clusters.items():
        rd = procs.get(root_pid)
        if not rd:
            continue
        tot_cpu = sum(procs[m]["cpu"] for m in members)
        tot_gpu_kib = sum(procs[m]["gpu_mem_kib"] for m in members)

        children = []
        for m in members:
            md = procs[m]
            if md["cpu"] >= 0.5 or md["gpu_mem_kib"] >= 5120:
                children.append({
                    "pid": m,
                    "name": md["comm"],
                    "cpu": md["cpu"],
                    "gpu_mb": round(md["gpu_mem_kib"] / 1024, 1)
                })

        app_name = rd["comm"]
        lower_name = app_name.lower()
        if "chrome" in lower_name:
            app_name = "Google Chrome"
        elif "discord" in lower_name:
            app_name = "Discord"
        elif "librewolf" in lower_name:
            app_name = "LibreWolf"
        elif "kitty" in lower_name:
            app_name = "Kitty"
        elif "hyprland" in lower_name:
            app_name = "Hyprland"
        elif "qs" == lower_name or "quickshell" in lower_name:
            app_name = "Quickshell"
        elif "code" in lower_name:
            app_name = "VS Code"

        aggregated.append({
            "pid": root_pid,
            "name": app_name,
            "total_cpu": round(tot_cpu, 1),
            "total_gpu_mb": round(tot_gpu_kib / 1024, 1),
            "count": len(members),
            "children": sorted(children, key=lambda x: x["cpu"], reverse=True)[:3]
        })

    top_cpu = sorted(aggregated, key=lambda x: x["total_cpu"], reverse=True)[:7]
    top_gpu = sorted([a for a in aggregated if a["total_gpu_mb"] > 0], key=lambda x: x["total_gpu_mb"], reverse=True)[:7]

    print(json.dumps({"top_cpu": top_cpu, "top_gpu": top_gpu}))

if __name__ == "__main__":
    main()
