#!/usr/bin/env bash
# Open pavucontrol as a compact dropdown aligned under the volume module.
set -euo pipefail

PAVU_CLASS="org.pulseaudio.pavucontrol"
DROPDOWN_W=420
DROPDOWN_H=480
DROPDOWN_MAX_W=600

dropdown_addr() {
  hyprctl clients -j | python3 -c "
import json, sys

for client in json.load(sys.stdin):
    if client.get('class') != '${PAVU_CLASS}':
        continue
    width = client.get('size', [0, 0])[0]
    if width < ${DROPDOWN_MAX_W}:
        print(client['address'])
        break
"
}

position_under_module() {
  python3 <<'PY'
import json
import subprocess

DROPDOWN_W = 420
DROPDOWN_H = 480
SPACING = 6
MODULE_W = 20
WIDGET_MARGIN = 2
SOUND_INDEX = 2  # group/sound is the 3rd modules-left entry
X_NUDGE = -6

monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], text=True))
focused = next(m for m in monitors if m.get("focused"))
focused_name = focused["name"]

layers = json.loads(subprocess.check_output(["hyprctl", "layers", "-j"], text=True))
waybar = None
for surface in layers.get(focused_name, {}).get("levels", {}).get("2", []):
    if surface.get("namespace") == "waybar":
        waybar = surface
        break

if not waybar:
    cursor = json.loads(subprocess.check_output(["hyprctl", "cursorpos", "-j"], text=True))
    print(f"{cursor['x']} {cursor['y'] + 4} {DROPDOWN_W} {DROPDOWN_H}")
    raise SystemExit(0)

wx, wy, ww, wh = waybar["x"], waybar["y"], waybar["w"], waybar["h"]

# Left edge of group/sound (pulseaudio leader), nudged to module border.
module_left = wx + WIDGET_MARGIN + SOUND_INDEX * (MODULE_W + SPACING) + X_NUDGE

x_pos = module_left
if x_pos + DROPDOWN_W > wx + ww - WIDGET_MARGIN:
    x_pos = wx + ww - WIDGET_MARGIN - DROPDOWN_W
if x_pos < wx + WIDGET_MARGIN:
    x_pos = wx + WIDGET_MARGIN

# Flush under the bar.
y_pos = wy + wh
print(f"{x_pos} {y_pos} {DROPDOWN_W} {DROPDOWN_H}")
PY
}

addr="$(dropdown_addr)"
if [[ -n "$addr" ]]; then
  hyprctl dispatch "hl.dsp.window.close({ window = 'address:${addr}' })"
  exit 0
fi

pkill -x pavucontrol 2>/dev/null || true
sleep 0.05

read -r x y w h < <(position_under_module)

# Tag + slidevert at the final position — avoids a post-move diagonal windowsMove anim.
hyprctl dispatch "hl.dsp.exec_cmd('pavucontrol', { float = true, pin = true, tag = '+pavu-dropdown', animation = 'slidevert', size = {${w}, ${h}}, move = {${x}, ${y}} })"