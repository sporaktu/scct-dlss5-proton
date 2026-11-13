#!/usr/bin/env bash
# kwinrun.sh SCRIPT.js TAG
# Load a KWin script, run it once, unload it, and print the journal line it printed that
# contains TAG (one window per line). The script should print("TAG ...").
# Needs: qdbus6, journalctl (user journal), KDE Plasma 6.
set -euo pipefail
script=$(readlink -f "$1"); tag=$2
name="cc$RANDOM"
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$script" "$name")
qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run >/dev/null 2>&1 || true
sleep 0.7
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$name" >/dev/null || true
journalctl --user -b --since "-5s" --no-pager -o cat 2>/dev/null | grep -- "$tag" | tail -1 | sed 's/ ;; /\n/g'
