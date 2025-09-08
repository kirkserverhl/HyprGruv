#!/usr/bin/env bash
# hard_copy.sh — copy asset files into $HOME with conflict-safe behavior
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from lib/scripts/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1; }
[[ -f "$HYPR_DIR/lib/state.sh"  ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh";  exit 1; }
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

display_header "Hard Copy Files"

ROOT_SRC="$ASSET_DIR/root"
if [[ ! -d "$ROOT_SRC" ]]; then
  log_status "No root assets directory at $ROOT_SRC — skipping copy to \$HOME."
  exit 0
fi

# Backup dir
TS="$(date +"%Y-%m-%d_%H-%M-%S")"
BACKUP_DIR="$HOME/.local/backup/hard_copy_$TS"
mkdir -p "$BACKUP_DIR"

log_status "Copying files from $ROOT_SRC → $HOME"
log_status "Backups (on conflict) → $BACKUP_DIR"

copy_entry() {
  local src="$1"
  local rel="${src#$ROOT_SRC/}"     # relative path under assets/root
  local dst="$HOME/$rel"

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" ]]; then
    # Handle file/dir type conflicts
    if [[ -d "$src" && ! -d "$dst" ]]; then
      # src is dir, dst is file/symlink → back up dst
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      log_status "Backing up (file→dir conflict): ~/${rel} → $BACKUP_DIR/${rel}"
      mv -f "$dst" "$BACKUP_DIR/${rel}"
      mkdir -p "$dst"
    elif [[ -f "$src" && -d "$dst" ]]; then
      # src is file, dst is directory → back up dst
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      log_status "Backing up (dir→file conflict): ~/${rel} → $BACKUP_DIR/${rel}"
      mv -f "$dst" "$BACKUP_DIR/${rel}"
      # parent exists from mkdir -p above
    fi
  fi

  # Now copy/merge
  if [[ -d "$src" ]]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$src/." "$dst/"
    else
      mkdir -p "$dst"
      cp -a "$src"/. "$dst"/
    fi
  else
    # regular file or symlink
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$src" "$dst"
    else
      cp -a "$src" "$dst"
    fi
  fi
}

# Walk top-level entries under assets/root and copy them
# (Change to recursive find if you prefer; this keeps per-entry handling clear)
while IFS= read -r -d '' entry; do
  copy_entry "$entry"
done < <(find "$ROOT_SRC" -mindepth 1 -maxdepth 1 -print0)

log_success "Home files copied."
log_status "Backup saved to: $BACKUP_DIR"
sleep 0.2
