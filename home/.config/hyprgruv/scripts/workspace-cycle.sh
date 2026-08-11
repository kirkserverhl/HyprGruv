#!/bin/bash
# Cycle workspaces that actually have windows (skip empty / persistent blanks).
# Usage: workspace-cycle.sh next|prev
# Special workspaces (id < 1) are ignored.

set -euo pipefail

dir="${1:-next}"

ids=()
while IFS= read -r id; do
    [[ -n "$id" ]] && ids+=("$id")
done < <(hyprctl workspaces -j 2>/dev/null | jq -r '
    [.[] | select(.id > 0 and .windows > 0) | .id] | sort | .[]
')

if ((${#ids[@]} == 0)); then
    exit 0
fi

cur="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')"
idx=0
for i in "${!ids[@]}"; do
    if [[ "${ids[$i]}" == "$cur" ]]; then
        idx=$i
        break
    fi
done

n=${#ids[@]}
case "$dir" in
    prev|-|r-1|e-1)
        next_idx=$(( (idx - 1 + n) % n ))
        ;;
    *)
        next_idx=$(( (idx + 1) % n ))
        ;;
esac

target="${ids[$next_idx]}"
# No-op if only one occupied workspace
if [[ "$target" == "$cur" ]]; then
    exit 0
fi

hyprctl dispatch "hl.dsp.focus({ workspace = $target })" >/dev/null
