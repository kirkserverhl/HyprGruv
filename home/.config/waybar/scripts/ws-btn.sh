#!/usr/bin/env bash
# Status for one workspace number button (Waybar custom module).
# Each bar only shows workspaces that live on THAT monitor (laptop + multi-monitor desktop).
# Clicks use hypr-ws.sh (Lua dispatch). Hidden IDs take no bar space.
set -euo pipefail

id="${1:?workspace id required}"
[[ "$id" =~ ^[0-9]+$ ]] || exit 1

uid="$(id -u)"
cache_dir="${XDG_RUNTIME_DIR:-/run/user/$uid}"
cache="$cache_dir/waybar-ws-list.json"
mon_cache="$cache_dir/waybar-mon-list.json"
lock="$cache_dir/waybar-ws-list.lock"

# Which monitor this Waybar instance is drawn on (set by waybar for custom modules).
# Fallback: focused monitor when testing from a shell.
output="${WAYBAR_OUTPUT_NAME:-}"
if [[ -z "$output" ]]; then
	output="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -1 || true)"
fi
output="${output:-}"

# Share heavier hyprctl JSON for ~1s across all buttons / bars.
refresh_caches() {
	(
		flock 9
		local now mtime
		now=$(date +%s)
		need_ws=1
		need_mon=1
		if [[ -f "$cache" ]]; then
			mtime=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
			((now - mtime < 1)) && need_ws=0
		fi
		if [[ -f "$mon_cache" ]]; then
			mtime=$(stat -c %Y "$mon_cache" 2>/dev/null || echo 0)
			((now - mtime < 1)) && need_mon=0
		fi
		if ((need_ws)); then
			hyprctl workspaces -j 2>/dev/null >"$cache.tmp" || echo '[]' >"$cache.tmp"
			mv -f "$cache.tmp" "$cache"
		fi
		if ((need_mon)); then
			hyprctl monitors -j 2>/dev/null >"$mon_cache.tmp" || echo '[]' >"$mon_cache.tmp"
			mv -f "$mon_cache.tmp" "$mon_cache"
		fi
	) 9>"$lock"
}

refresh_caches

# Ensure caches exist even if flock/hyprctl failed
[[ -f "$cache" ]] || echo '[]' >"$cache"
[[ -f "$mon_cache" ]] || echo '[]' >"$mon_cache"

# Active workspace on THIS bar's monitor (not the globally focused one).
mon_active="$(
	jq -r --arg o "$output" '
		[.[] | select(.name == $o) | .activeWorkspace.id][0] // empty
	' "$mon_cache" 2>/dev/null || true
)"
[[ "$mon_active" =~ ^[0-9]+$ ]] || mon_active=0

mapfile -t fields < <(
	jq -r --argjson id "$id" --arg o "$output" --argjson mon_active "$mon_active" '
		. as $wss
		| ($wss | map(select(.id == $id)) | .[0]) as $ws
		# Hide: missing, special, or belongs to another monitor
		| if ($ws == null)
				or (($ws.id // 0) <= 0)
				or ($o != "" and ($ws.monitor // "") != $o)
			then
				["", "hidden", ""]
			else
				($ws.windows // 0) as $wins
				| (if $mon_active == $id then "active"
					 elif $wins > 0 then "occupied"
					 else "empty" end) as $cls
				| (if $mon_active == $id then "Workspace \($id) (active on \($o))"
					 elif $wins > 0 then "Workspace \($id) — \($wins) window(s) on \($o)"
					 else "Workspace \($id) on \($o)" end) as $tip
				| ["\($id)", "ws \($cls)", $tip]
			end
		| .[]
	' "$cache"
)

text="${fields[0]:-}"
class="${fields[1]:-hidden}"
tooltip="${fields[2]:-}"

jq -nc --arg t "$text" --arg c "$class" --arg p "$tooltip" \
	'{text: $t, class: $c, tooltip: $p}'
