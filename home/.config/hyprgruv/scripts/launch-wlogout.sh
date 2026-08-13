#!/bin/bash
#
# launch-wlogout.sh
#
# Launcher for wlogout.
#
# Follows the strict rule: wlogout does *not* source any static wallpaper image.
# Background blur is handled 100% by Hyprland layerrules (real-time, no pre-rendered images).
# Only SDDM and the rofi 50x30 generator are permitted to load wallpaper files.
#
# Geometry is computed from the focused monitor's *logical* size so a 2x3
# (or 3x2 portrait) card stays readable on 720p laptops through 4K desktops.
# Do not put comments after a line-continuation backslash — bash treats that
# as "end of command" and drops every flag after it.
#

set -euo pipefail

# Toggle: if already open, just close it
if pgrep -x wlogout >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

# Small delay to let any in-progress wallpaper transition settle on screen.
# This prevents the common "blurred background is one wallpaper behind" issue.
sleep 0.3

layout="${HOME}/.config/wlogout/layout"
css="${HOME}/.config/wlogout/style.css"

# Focused monitor: physical px + fractional scale. GTK layer-shell sees logical px.
read -r mon_w mon_h mon_scale < <(
    hyprctl monitors -j 2>/dev/null | jq -r '
        ([.[] | select(.focused == true)][0] // .[0] // empty) |
        "\(.width) \(.height) \(.scale)"
    ' 2>/dev/null || true
)

mon_w=${mon_w:-1920}
mon_h=${mon_h:-1080}
mon_scale=${mon_scale:-1}

read -r cols rows \
        margin_left margin_right margin_top margin_bottom \
        col_spacing row_spacing < <(
    awk -v w="$mon_w" -v h="$mon_h" -v s="$mon_scale" 'BEGIN {
        if (s <= 0) s = 1
        lw = int(w / s)
        lh = int(h / s)
        if (lw < 320) lw = 320
        if (lh < 240) lh = 240

        # Landscape: 3x2. Portrait / tall: 2x3 so labels keep vertical room.
        cols = (lh > lw) ? 2 : 3
        rows = (lh > lw) ? 3 : 2

        # Gaps between cards — scale with the axis, keep a readable floor.
        csp = int(lw * 0.016); if (csp < 14) csp = 14; if (csp > 36) csp = 36
        rsp = int(lh * 0.024); if (rsp < 18) rsp = 18; if (rsp > 42) rsp = 42

        # Target card size: wide enough for "Hibernate"/"Shutdown", taller
        # than wide so the glyph sits above the label instead of on it.
        bw = int(lw * 0.145); if (bw < 168) bw = 168; if (bw > 260) bw = 260
        bh = int(lh * 0.26)
        if (bh < bw + 40) bh = bw + 40
        if (bh < 200) bh = 200
        if (bh > 300) bh = 300

        min_outer = 24
        for (i = 0; i < 4; i++) {
            gw = cols * bw + (cols - 1) * csp
            gh = rows * bh + (rows - 1) * rsp
            leftover_w = lw - gw
            leftover_h = lh - gh
            if (leftover_w >= min_outer * 2 && leftover_h >= min_outer * 2) break
            if (leftover_w < min_outer * 2) {
                over = min_outer * 2 - leftover_w
                shrink = int((over + cols - 1) / cols)
                bw -= shrink
                if (bw < 140) bw = 140
                if (csp > 12) csp -= 2
            }
            if (leftover_h < min_outer * 2) {
                over = min_outer * 2 - leftover_h
                shrink = int((over + rows - 1) / rows)
                bh -= shrink
                if (bh < 160) bh = 160
                if (rsp > 14) rsp -= 2
            }
        }

        gw = cols * bw + (cols - 1) * csp
        gh = rows * bh + (rows - 1) * rsp
        ml = int((lw - gw) / 2)
        mt = int((lh - gh) / 2)
        if (ml < min_outer) ml = min_outer
        if (mt < min_outer) mt = min_outer

        printf "%d %d %d %d %d %d %d %d\n", cols, rows, ml, ml, mt, mt, csp, rsp
    }'
)

exec wlogout \
    --protocol layer-shell \
    -b "${cols}" \
    -c "${col_spacing}" \
    -r "${row_spacing}" \
    -L "${margin_left}" \
    -R "${margin_right}" \
    -T "${margin_top}" \
    -B "${margin_bottom}" \
    --layout "${layout}" \
    --css "${css}" \
    "$@"
