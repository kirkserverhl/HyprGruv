#!/usr/bin/env bash
# Status for one workspace number button (Waybar custom module).
# Clicks use hypr-ws.sh (Lua dispatch). Hidden IDs take no bar space.
set -euo pipefail

id="${1:?workspace id required}"
[[ "$id" =~ ^[0-9]+$ ]] || exit 1

uid="$(id -u)"
cache_dir="${XDG_RUNTIME_DIR:-/run/user/$uid}"
cache="$cache_dir/waybar-ws-list.json"
lock="$cache_dir/waybar-ws-list.lock"
machine_file="${XDG_CONFIG_HOME:-$HOME/.config}/settings/machine.sh"
machine="$(tr -d '[:space:]' <"$machine_file" 2>/dev/null || true)"

# Always fetch active workspace (cheap, keeps highlight in sync).
active="$(hyprctl activeworkspace -j 2>/dev/null || echo '{}')"

# Share the heavier workspaces list for ~1s across all buttons.
refresh_list() {
	exec 9>"$lock"
	flock 9
	if [[ -f "$cache" ]]; then
		local mtime now
		mtime=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
		now=$(date +%s)
		if (( now - mtime < 1 )); then
			return 0
		fi
	fi
	hyprctl workspaces -j 2>/dev/null >"$cache.tmp" || echo '[]' >"$cache.tmp"
	mv -f "$cache.tmp" "$cache"
}

refresh_list

if [[ "$machine" == "laptop" ]]; then
	baseline='[1,2]'
else
	baseline='[1,2,3,4,5,6,7,8]'
fi

mapfile -t fields < <(
	jq -r --argjson id "$id" --argjson baseline "$baseline" --argjson active "$active" '
		. as $wss
		| ($baseline | index($id) != null) as $always
		| ($wss | map(select(.id == $id)) | .[0]) as $ws
		| ($active.id // 0) as $aid
		| if ($ws == null) and ($always | not) then
				["", "hidden", ""]
			else
				($ws.windows // 0) as $wins
				| (if $aid == $id then "active"
					 elif $wins > 0 then "occupied"
					 else "empty" end) as $cls
				| (if $aid == $id then "Workspace \($id) (active)"
					 elif $wins > 0 then "Workspace \($id) — \($wins) window(s)"
					 else "Workspace \($id)" end) as $tip
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
