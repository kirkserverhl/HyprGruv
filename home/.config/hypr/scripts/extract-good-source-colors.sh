#!/usr/bin/env bash
# extract-good-source-colors.sh
#
# Purpose: Given a wallpaper, output 4 high-quality, reasonably saturated
# source colors that are *confident* to produce good (non-grey) matugen palettes.
#
# Strategy:
#   - Create a temporary saturation-boosted + contrast-stretched version
#   - Extract a generous palette of unique colors from the boosted image
#   - Filter out near-grays, near-blacks, and near-whites
#   - Score remaining colors for "vibrancy"
#   - Select 4 colors with good hue spread so they are distinct
#
# Output: One #RRGGBB per line (N lines, default 4, up to ~12)
#
# Usage:
#   extract-good-source-colors.sh [wallpaper.png] [count]
#   count defaults to 4. Higher values give you more choices to pick from.

set -euo pipefail

WALLPAPER="${1:-}"
DESIRED_COUNT="${2:-4}"
if [[ -z "$WALLPAPER" ]]; then
    CURRENT_WP_CACHE="$HOME/.config/settings/cache/current_wallpaper"
    if [[ -f "$CURRENT_WP_CACHE" ]]; then
        WALLPAPER=$(cat "$CURRENT_WP_CACHE")
    elif [ -f "$HOME/.config/settings/default" ]; then
        WALLPAPER=$(cat "$HOME/.config/settings/default")
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Error: No valid wallpaper" >&2
    exit 1
fi

# --- Tunables (tweak if you want more/less aggressive filtering) ---
BOOST_SAT=185          # 100 = no change, 160-220 is the useful range
BOOST_CONTRAST="1.5%x1.5%"
CANDIDATE_COUNT=28     # how many raw unique colors we pull before filtering
MIN_SAT=0.18           # 0.0-1.0, discard anything below this (0.18 = fairly gray)
MIN_LUMA=0.10
MAX_LUMA=0.86
TARGET_COUNT=4

TMPDIR=$(mktemp -d /tmp/good-sources-XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

BOOSTED="$TMPDIR/boosted.png"
magick "$WALLPAPER" \
    -resize 640x640\> \
    -modulate 100,"$BOOST_SAT",100 \
    -contrast-stretch "$BOOST_CONTRAST" \
    -quality 92 \
    "$BOOSTED" 2>/dev/null || cp "$WALLPAPER" "$BOOSTED"

# Extract many unique colors from the boosted image
mapfile -t CANDIDATES < <(
    magick "$BOOSTED" -colors "$CANDIDATE_COUNT" +dither -unique-colors txt:- 2>/dev/null \
    | grep -oP '#[0-9A-Fa-f]{6}' | sort -u || true
)

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    # Total fallback - shouldn't happen
    printf '#a78a9d\n#eda9a1\n#838095\n#e9ccb8\n'
    exit 0
fi

# Python does the smart filtering + selection (portable, only stdlib)
python3 - "$DESIRED_COUNT" "$MIN_SAT" "$MIN_LUMA" "$MAX_LUMA" "${CANDIDATES[@]}" <<'PYEOF'
import sys, colorsys

target = int(sys.argv[1])
min_sat = float(sys.argv[2])
min_luma = float(sys.argv[3])
max_luma = float(sys.argv[4])
raw_colors = sys.argv[5:]

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_luma(r, g, b):
    return 0.299*r + 0.587*g + 0.114*b

def score_color(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    luma = rgb_to_luma(r, g, b)
    # Reward high saturation, penalize extreme lightness
    mid_luma_bonus = 1.0 - abs(luma - 0.48) * 1.1
    return s * max(0.15, mid_luma_bonus)

def hue_dist(h1, h2):
    d = abs(h1 - h2)
    return min(d, 1.0 - d)

# Filter + score
scored = []
for hx in raw_colors:
    try:
        r, g, b = hex_to_rgb(hx)
        l = rgb_to_luma(r, g, b)
        if l < min_luma or l > max_luma:
            continue
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        if s < min_sat:
            continue
        sc = score_color(r, g, b)
        scored.append((sc, h, s, hx))
    except Exception:
        continue

if not scored:
    # Very desaturated image - relax the filter and just take the best available
    scored = []
    for hx in raw_colors:
        try:
            r, g, b = hex_to_rgb(hx)
            l = rgb_to_luma(r, g, b)
            if l < 0.06 or l > 0.92:
                continue
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            sc = score_color(r, g, b)
            scored.append((sc, h, s, hx))
        except Exception:
            continue
    if not scored:
        # Absolute last resort
        print("#c48b5f")
        print("#7a9e8e")
        print("#b37a6e")
        print("#8a9a7a")
        sys.exit(0)

scored.sort(reverse=True)  # best first

# Greedy selection with hue diversity
selected = []
used_hues = []

for sc, h, s, hx in scored:
    if len(selected) >= target:
        break
    if any(hue_dist(h, uh) < 0.12 for uh in used_hues):
        # Too close in hue to something we already picked - skip unless we are desperate
        if len(selected) < 2:
            continue
    selected.append(hx)
    used_hues.append(h)

# If we still don't have enough, just append the next best regardless of hue
for sc, h, s, hx in scored:
    if len(selected) >= target:
        break
    if hx not in selected:
        selected.append(hx)

while len(selected) < target:
    selected.append(selected[-1] if selected else "#8a7f6e")

for c in selected[:target]:
    print(c)
PYEOF
