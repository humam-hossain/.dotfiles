#!/usr/bin/env python3
# DEPRECATED: No longer invoked by CpuGpuPopup.qml as of Phase 43.6. Retained as standalone CLI diagnostic utility.
"""
Fast launcher delegating to process_tree.sh for maximum performance and zero duplicate logic.
"""
import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
sh_script = os.path.join(script_dir, "process_tree.sh")
if os.path.exists(sh_script):
    os.execv(sh_script, [sh_script] + sys.argv[1:])
else:
    print('{"top_cpu":[],"top_gpu":[]}')
