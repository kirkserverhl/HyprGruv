#!/usr/bin/env bash
# cache-wallpapers.sh — opt-in waypaper preview warmer
#
# Writes the same 240px thumbnails waypaper keeps in ~/.cache/waypaper
# (MD5 of each image's real path). Makes the picker load without decoding
# full-size wallpapers. Safe to re-run; existing thumbs are left alone.
#
# Does not import waypaper/GTK (works in a TTY / pre-graphical setup).
#
# Usage:
#   cache-wallpapers.sh              # show plan, confirm (default: No), then warm
#   cache-wallpapers.sh --yes        # skip confirm
#   cache-wallpapers.sh --dry-run    # print plan only
#   CACHE_WALLPAPERS=1 cache-wallpapers.sh   # same as --yes
#   CACHE_WALLPAPERS=0 cache-wallpapers.sh   # skip
#
# Palette: common.sh → gruvbox default / matugen if present

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="${HYPRGRUV_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

YES=0
DRY_RUN=0
NESTED=0

usage() {
  cat <<'EOF'
cache-wallpapers.sh — pre-generate waypaper preview thumbnails

  cache-wallpapers.sh            Confirm (default No), then warm ~/.cache/waypaper
  cache-wallpapers.sh --yes      Skip confirmation
  cache-wallpapers.sh --dry-run  Print counts / size estimate only
  -h, --help                     This help

Environment:
  CACHE_WALLPAPERS=1   same as --yes
  CACHE_WALLPAPERS=0   skip without prompting

Skip this on low disk or a slow machine. Re-run after adding images.
Pressing r in waypaper wipes the cache; run this again to rebuild it.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --dry-run|--plan) DRY_RUN=1 ;;
    --nested) NESTED=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ "${CACHE_WALLPAPERS:-}" == "1" ]]; then
  YES=1
elif [[ "${CACHE_WALLPAPERS:-}" == "0" ]]; then
  if [[ $DRY_RUN -eq 0 ]]; then
    log_status "CACHE_WALLPAPERS=0 — skipping waypaper preview cache"
    declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "skipped"
    exit 0
  fi
fi

bytes_human() {
  local b="${1:-0}"
  [[ "$b" =~ ^-?[0-9]+$ ]] || b=0
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$b" 2>/dev/null || echo "${b}B"
  else
    echo "${b}B"
  fi
}

# Prints KEY=VALUE lines for bash eval. --warm writes missing thumbs.
waypaper_cache_py() {
  python3 - "$@" <<'PY'
import hashlib
import os
import sys
from configparser import ConfigParser
from pathlib import Path

WIDTH = 240
BYTES_PER_THUMB = 48 * 1024
EXTS = {".gif", ".jpg", ".jpeg", ".png", ".jxl", ".webp", ".bmp", ".pnm", ".tiff", ".tif", ".avif"}

def cache_dir() -> Path:
    try:
        from platformdirs import user_cache_path
        return Path(user_cache_path("waypaper"))
    except Exception:
        return Path.home() / ".cache" / "waypaper"

def read_settings():
    folders = [Path.home() / "Pictures" / "Wallpapers"]
    subfolders = True
    all_subfolders = False
    show_hidden = False
    cfg_path = Path.home() / ".config" / "waypaper" / "config.ini"
    if not cfg_path.is_file():
        return folders, subfolders, all_subfolders, show_hidden
    parser = ConfigParser()
    parser.read(cfg_path, encoding="utf-8")
    if not parser.has_section("Settings"):
        return folders, subfolders, all_subfolders, show_hidden
    raw = parser.get("Settings", "folder", fallback="~/Pictures/Wallpapers")
    parsed = [Path(line.strip()).expanduser() for line in raw.splitlines() if line.strip()]
    if parsed:
        folders = parsed
    subfolders = parser.getboolean("Settings", "subfolders", fallback=subfolders)
    all_subfolders = parser.getboolean("Settings", "all_subfolders", fallback=all_subfolders)
    show_hidden = parser.getboolean("Settings", "show_hidden", fallback=show_hidden)
    return folders, subfolders, all_subfolders, show_hidden

def collect(folders, subfolders, all_subfolders, show_hidden):
    images = []
    for folder in folders:
        folder = folder.expanduser()
        if not folder.is_dir():
            continue
        folder_s = os.path.normpath(str(folder))
        for root, directories, files in os.walk(folder_s, followlinks=True):
            if not show_hidden:
                directories[:] = [d for d in directories if not d.startswith(".")]
            if root != folder_s:
                if not subfolders:
                    continue
                if not all_subfolders:
                    depth = root.count(os.sep) - folder_s.count(os.sep)
                    if depth > 1:
                        continue
            for name in files:
                if not show_hidden and name.startswith("."):
                    continue
                if Path(name).suffix.lower() not in EXTS:
                    continue
                path = os.path.join(root, name)
                try:
                    if os.path.getsize(path) == 0:
                        continue
                except OSError:
                    continue
                images.append(path)
    return images

def cached_path(image_path: str, dest: Path) -> Path:
    digest = hashlib.md5(os.path.realpath(image_path).encode("UTF-8")).hexdigest()
    return dest / f"{digest}.png"

def estimate_bytes(misses: int, dest: Path) -> int:
    sizes = []
    if dest.is_dir():
        for png in dest.glob("*.png"):
            try:
                sizes.append(png.stat().st_size)
            except OSError:
                continue
            if len(sizes) >= 80:
                break
    avg = int(sum(sizes) / len(sizes)) if sizes else BYTES_PER_THUMB
    return misses * avg

def write_thumb(image_path: str, dest_file: Path) -> None:
    from PIL import Image

    dest_file.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(image_path) as img:
        if getattr(img, "n_frames", 1) > 1:
            img.seek(0)
        frame = img.convert("RGBA" if "A" in img.getbands() else "RGB")
        if frame.width <= 0 or frame.height <= 0:
            raise ValueError("invalid image size")
        height = max(1, int(WIDTH * frame.height / frame.width))
        frame = frame.resize((WIDTH, height), Image.Resampling.BILINEAR)
        tmp = dest_file.with_suffix(".png.tmp")
        frame.save(tmp, "PNG")
        tmp.replace(dest_file)

def emit_plan(total, hits, misses, dest, est):
    print(f"TOTAL={total}")
    print(f"HITS={hits}")
    print(f"MISSES={misses}")
    print(f"EST_BYTES={est}")
    print(f"CACHE_DIR={dest}")

def main():
    action = "plan"
    if "--warm" in sys.argv:
        action = "warm"
    folders, subfolders, all_subfolders, show_hidden = read_settings()
    dest = cache_dir()
    images = collect(folders, subfolders, all_subfolders, show_hidden)
    hits = []
    misses = []
    for path in images:
        (hits if cached_path(path, dest).is_file() else misses).append(path)
    est = estimate_bytes(len(misses), dest)
    if action == "plan":
        emit_plan(len(images), len(hits), len(misses), dest, est)
        return 0

    dest.mkdir(parents=True, exist_ok=True)
    wrote = 0
    failed = 0
    for i, path in enumerate(misses, 1):
        try:
            write_thumb(path, cached_path(path, dest))
            wrote += 1
        except Exception as exc:
            failed += 1
            print(f"FAIL {os.path.basename(path)}: {exc}", file=sys.stderr)
        if i == 1 or i == len(misses) or i % 25 == 0:
            print(f"PROGRESS {i}/{len(misses)}", file=sys.stderr, flush=True)
    print(f"WROTE={wrote}")
    print(f"FAILED={failed}")
    emit_plan(len(images), len(hits) + wrote, len(misses) - wrote, dest, 0)
    return 1 if failed and not wrote else 0

if __name__ == "__main__":
    raise SystemExit(main())
PY
}

confirm_cache() {
  local prompt="$1"
  if command -v gum >/dev/null 2>&1 && declare -F gum_confirm_prompt >/dev/null 2>&1; then
    gum_confirm_prompt "$prompt" --default=false
    return $?
  fi
  local ans=""
  read -rp "$prompt [y/N]: " ans || true
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

has_tty() {
  [[ -t 0 || -r /dev/tty ]]
}

if [[ $NESTED -eq 0 ]]; then
  display_header "Waypaper Previews"
fi

if ! command -v python3 >/dev/null 2>&1; then
  log_error "python3 is required to cache waypaper previews"
  exit 1
fi
if ! python3 -c "from PIL import Image" >/dev/null 2>&1; then
  log_error "python-pillow is required (install python-pillow)"
  exit 1
fi

plan_out=""
if ! plan_out="$(waypaper_cache_py --plan)"; then
  log_error "Could not scan wallpaper folders"
  exit 1
fi

TOTAL=0
HITS=0
MISSES=0
EST_BYTES=0
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waypaper"
eval "$plan_out"

if [[ $NESTED -eq 0 ]]; then
  echo ""
fi
log_status "Waypaper preview cache: $CACHE_DIR"
log_status "Images: $TOTAL  already cached: $HITS  missing: $MISSES"

if ((TOTAL == 0)); then
  log_warning "No wallpaper images found — add files to ~/Pictures/Wallpapers and re-run"
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "skipped"
  exit 0
fi

if ((MISSES == 0)); then
  log_success "Previews already cached ($HITS/$TOTAL) — waypaper can skip generation"
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "yes"
  exit 0
fi

est_h="$(bytes_human "$EST_BYTES")"
echo ""
echo "Pre-generating $MISSES thumbnail(s) uses about $est_h in $CACHE_DIR."
echo "This only speeds up the waypaper picker — theme apply still runs matugen."
if [[ $YES -eq 0 ]]; then
  echo "Skip if disk or CPU is tight. Re-run later:"
  echo "  bash $SCRIPT_DIR/cache-wallpapers.sh"
fi
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  log_status "Dry-run — not writing thumbnails"
  exit 0
fi

if [[ $YES -eq 0 ]]; then
  if ! has_tty; then
    log_status "No TTY — skipping preview cache (pass --yes or CACHE_WALLPAPERS=1)"
    declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "skipped"
    exit 0
  fi
  if ! confirm_cache "Pre-cache waypaper previews now?"; then
    log_status "Preview cache skipped"
    declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "skipped"
    exit 0
  fi
fi

log_status "Generating $MISSES preview(s)…"
warm_out=""
if ! warm_out="$(waypaper_cache_py --warm)"; then
  log_warning "Preview cache finished with errors"
  echo "$warm_out" | grep -E '^(WROTE|FAILED|TOTAL|HITS|MISSES)=' || true
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "partial"
  exit 1
fi

WROTE=0
FAILED=0
eval "$(echo "$warm_out" | grep -E '^(WROTE|FAILED|TOTAL|HITS|MISSES)=')"
if [[ "${FAILED:-0}" -gt 0 ]]; then
  log_warning "Cached $WROTE preview(s); $FAILED failed"
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "partial"
else
  log_success "Cached $WROTE preview(s) ($HITS/$TOTAL in $CACHE_DIR)"
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_previews_cached" "yes"
fi
