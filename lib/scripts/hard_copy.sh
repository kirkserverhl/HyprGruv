#!/usr/bin/env bash
# hard_copy.sh — copy asset files into $HOME with conflict-safe behavior
set -euo pipefail
IFS=$'\n\t'

# -------- Debug / tracing toggles --------
# DEBUG=1 to trace; DRY_RUN=1 to simulate
if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
fi
trap 'echo "[hard_copy] ERROR at line $LINENO: ${BASH_COMMAND}" >&2' ERR

# -------- Resolve repo root and load helpers --------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1; }
[[ -f "$HYPR_DIR/lib/state.sh"  ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh";  exit 1; }
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

display_header "Hard Copy Files"

# Ensure ASSET_DIR is set by common.sh
: "${ASSET_DIR:?ASSET_DIR is not set (check lib/common.sh)}"

ROOT_SRC="$ASSET_DIR/root"

# Print key paths for sanity
echo "[hard_copy] HYPR_DIR = $HYPR_DIR"
echo "[hard_copy] ASSET_DIR = $ASSET_DIR"
echo "[hard_copy] ROOT_SRC = $ROOT_SRC"

if [[ ! -d "$ROOT_SRC" ]]; then
  log_status "No root assets directory at $ROOT_SRC — skipping copy to \$HOME."
  exit 0
fi

# -------- Backup dir --------
TS="$(date +"%Y-%m-%d_%H-%M-%S")"
BACKUP_DIR="$HOME/.local/backup/hard_copy_$TS"
[[ "${DRY_RUN:-0}" == "1" ]] || mkdir -p "$BACKUP_DIR"

log_status "Copying files from $ROOT_SRC → $HOME"
log_status "Backups (on conflict) → $BACKUP_DIR"
command -v rsync >/dev/null 2>&1 || echo "[hard_copy] Note: rsync not found, will use cp -a"

# -------- Helpers --------
_do() {
  # Execute or echo depending on DRY_RUN
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

copy_entry() {
  local src="$1"
  local rel="${src#$ROOT_SRC/}"     # relative path under assets/root
  local dst="$HOME/$rel"

  echo "[hard_copy] • $rel"

  # Ensure parent directory exists
  _do "mkdir -p \"$(dirname "$dst")\""

  if [[ -e "$dst" || -L "$dst" ]]; then
    # Handle file/dir type conflicts
    if [[ -d "$src" && ! -d "$dst" ]]; then
      # src is dir, dst is file/symlink → back up dst
      _do "mkdir -p \"$BACKUP_DIR/$(dirname "$rel")\""
      log_status "Backing up (file→dir conflict): ~/${rel} → $BACKUP_DIR/${rel}"
      _do "mv -f \"$dst\" \"$BACKUP_DIR/${rel}\""
      _do "mkdir -p \"$dst\""
    elif [[ -f "$src" && -d "$dst" ]]; then
      # src is file, dst is directory → back up dst
      _do "mkdir -p \"$BACKUP_DIR/$(dirname "$rel")\""
      log_status "Backing up (dir→file conflict): ~/${rel} → $BACKUP_DIR/${rel}"
      _do "mv -f \"$dst\" \"$BACKUP_DIR/${rel}\""
      # parent exists; file will be copied below
    fi
  fi

  # Now copy/merge
  if [[ -d "$src" ]]; then
    if command -v rsync >/dev/null 2>&1; then
      # rsync: copy content of dir into dst dir
      _do "mkdir -p \"$dst\""
      _do "rsync -a \"$src/\" \"$dst/\""
    else
      _do "mkdir -p \"$dst\""
      _do "cp -a \"$src\"/. \"$dst\"/"
    fi
  else
    # regular file or symlink
    if command -v rsync >/dev/null 2>&1; then
      _do "rsync -a \"$src\" \"$dst\""
    else
      _do "cp -a \"$src\" \"$dst\""
    fi
  fi
}

# -------- Walk top-level entries under assets/root and copy them --------
# If you want full recursive walk, change -maxdepth 1 to a higher depth or remove it.
while IFS= read -r -d '' entry; do
  copy_entry "$entry"
done < <(find "$ROOT_SRC" -mindepth 1 -maxdepth 1 -print0)

log_success "Home files copied."
log_status "Backup saved to: $BACKUP_DIR"

