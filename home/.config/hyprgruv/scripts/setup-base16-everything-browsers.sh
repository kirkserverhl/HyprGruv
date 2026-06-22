#!/usr/bin/env bash
# setup-base16-everything-browsers.sh — one-shot Base16 Everything + matugen wiring
#
# - Installs native messaging host (Chrome, Brave, Chromium)
# - Syncs ~/.config/base16-everything/config.yaml from matugen palette
# - Enables Base16 Everything in Chrome Profile 2
# - Copies extension into Brave Default (close Brave first for prefs to stick)
# - Symlinks brave matugen CSS vars to chrome output

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
EXT_ID="jmofeafhkeohbpbedgbnkdlfaomjbnkf"
EXT_VER="1.1.1_0"

running() {
    pgrep -x "$1" >/dev/null 2>&1
}

warn_if_running() {
    if running brave; then
        echo "Note: Brave is running — close and reopen it so the extension registers." >&2
    fi
    if pgrep -f 'google-chrome|chrome' >/dev/null 2>&1; then
        echo "Note: Chrome is running — close and reopen it so enablement sticks." >&2
    fi
}

"$SCRIPTS/install-base16-everything-host.sh"
python3 "$SCRIPTS/sync-base16-everything-from-matugen.py"
"$SCRIPTS/matugen-posthook-browsers.sh"

python3 - <<'PY'
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

EXT_ID = "jmofeafhkeohbpbedgbnkdlfaomjbnkf"
EXT_VER = "1.1.1_0"
home = Path.home()

chrome_prefs = home / ".config/google-chrome/Profile 2/Preferences"
if chrome_prefs.is_file():
    prefs = json.loads(chrome_prefs.read_text())
    entry = prefs.get("extensions", {}).get("settings", {}).get(EXT_ID)
    if entry is not None:
        entry["disable_reasons"] = []
        chrome_prefs.write_text(json.dumps(prefs, separators=(",", ":")))
        print("Chrome Profile 2: Base16 Everything enabled")

src = home / f".config/google-chrome/Profile 2/Extensions/{EXT_ID}/{EXT_VER}"
dst = home / f".config/BraveSoftware/Brave-Browser/Default/Extensions/{EXT_ID}/{EXT_VER}"
if src.is_dir():
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print(f"Brave Default: extension copied to {dst}")

brave_prefs = home / ".config/BraveSoftware/Brave-Browser/Default/Preferences"
if brave_prefs.is_file() and chrome_prefs.is_file():
    brave = json.loads(brave_prefs.read_text())
    chrome = json.loads(chrome_prefs.read_text())
    brave_ext = brave.setdefault("extensions", {}).setdefault("settings", {})
    chrome_entry = chrome.get("extensions", {}).get("settings", {}).get(EXT_ID)
    if chrome_entry:
        entry = json.loads(json.dumps(chrome_entry))
        now = str(int(datetime.now(timezone.utc).timestamp() * 1_000_000))
        entry.update(
            {
                "path": f"{EXT_ID}/{EXT_VER}",
                "disable_reasons": [],
                "location": entry.get("location", 1),
                "from_webstore": True,
            }
        )
        entry.setdefault("creation_flags", 9)
        entry.setdefault("first_install_time", now)
        entry.setdefault("last_update_time", now)
        brave_ext[EXT_ID] = entry
        brave_prefs.write_text(json.dumps(brave, separators=(",", ":")))
        print("Brave Default: Base16 Everything registered and enabled")
PY

warn_if_running

cat <<'EOF'

Base16 Everything is wired to matugen.

After restarting Chrome and Brave:
  1. Open the Base16 Everything popup on each browser
  2. Settings → grant native messaging permission (premium)
  3. Confirm ~/.config/base16-everything/config.yaml shows as active
  4. Keep auto-apply enabled; reload tabs after theme switches

Native config sync requires Base16 Everything premium.
Without premium the extension uses google-dark / gruvbox-light-hard.
EOF