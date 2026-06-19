#!/usr/bin/env python3
"""Parse Hyprland Lua keybinds into searchable menu lines."""

from __future__ import annotations

import re
import sys
from pathlib import Path

HOME = Path.home()
SCRIPTS = str(HOME / ".config/hyprgruv/scripts")

KEYBIND_FILES = [
    HOME / ".config/hypr/conf/keybinds.lua",
    HOME / ".config/hypr/hyprland.lua",
]

VARS: dict[str, str] = {"mainMod": "SUPER", "mod": "ALT", "SCRIPTS": SCRIPTS}

SECTION_RE = re.compile(r"--\s*=+\s*([A-Za-z][^=]+?)\s*=+")
VAR_RE = re.compile(r'^local\s+(\w+)\s*=\s*["\']([^"\']+)["\']')
BIND_RE = re.compile(
    r"hl\.bind\((.+?),\s*(.+?)\)(?:\s*,\s*\{[^}]*\})?(?:\s*--\s*(.+))?$"
)
FOR_RE = re.compile(r"for\s+(\w+)\s*=\s*(\d+)\s*,\s*(\d+)\s+do")
INLINE_COMMENT_RE = re.compile(r"\s*--\s*(.+)$")

DIR_NAMES = {"l": "left", "r": "right", "u": "up", "d": "down"}


def lua_concat(expr: str, loop_var: str | None = None, loop_value: int | None = None) -> str:
    expr = expr.strip()
    literal = re.fullmatch(r'["\'](.*)["\']', expr)
    if literal:
        return literal.group(1)

    parts = re.split(r"\s*\.\.\s*", expr)
    out = ""
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if part in VARS:
            out += VARS[part]
            continue
        lit = re.fullmatch(r'["\'](.*)["\']', part)
        if lit:
            out += lit.group(1)
            continue
        if loop_var and part == loop_var and loop_value is not None:
            out += str(loop_value)
            continue
        if part.isdigit():
            out += part
            continue
        out += part
    return normalize_combo(out)


def normalize_combo(combo: str) -> str:
    combo = re.sub(r"\s+", " ", combo.strip())
    combo = re.sub(r"\s*\+\s*", " + ", combo)
    combo = re.sub(r"(?:\s*\+\s*)+", " + ", combo)
    return combo.strip(" +")


def humanize_command(cmd: str) -> str:
    name = Path(cmd.split()[0]).name if cmd else cmd
    friendly = {
        "rofi-apps.sh": "Favorites app launcher",
        "rofi-full.sh": "Full app launcher",
        "fuzzel-apps.sh": "Favorites app launcher",
        "fuzzel-full.sh": "Full app launcher",
        "fuzzel-keybinds.sh": "Keybind reference menu",
        "terminal.sh": "Open terminal",
        "dev-workspace.sh": "Open dev tmux workspace",
        "hyprshot.sh": "Screenshot menu",
        "quickshot.sh": "Quick screenshot to clipboard",
        "cliphist.sh": "Clipboard history",
        "launch-wlogout.sh": "Power menu",
        "waypaper": "Wallpaper picker",
        "brave": "Open Brave",
        "google-chrome-stable": "Open Chrome",
        "firefox": "Open Firefox",
        "alacritty": "Open Alacritty",
        "dolphin": "Open Dolphin",
        "mac-shortcut.sh": "Mac-style shortcut",
    }
    if name in friendly:
        if name == "mac-shortcut.sh" and " " in cmd:
            return f"Mac-style shortcut ({cmd.split(maxsplit=1)[1]})"
        return friendly[name]
    return cmd


def simplify_command(cmd: str) -> str:
    cmd = cmd.replace(SCRIPTS, "~/.config/hyprgruv/scripts")
    cmd = cmd.replace(str(HOME), "~")
    cmd = re.sub(r"\s+", " ", cmd).strip()
    if len(cmd) > 72:
        return cmd[:69] + "..."
    return cmd


def lua_command_expr(expr: str) -> str:
    expr = expr.strip()
    literal = re.fullmatch(r'["\'](.*)["\']', expr)
    if literal:
        return literal.group(1)

    parts = re.split(r"\s*\.\.\s*", expr)
    out = ""
    for part in parts:
        part = part.strip()
        if part in VARS:
            out += VARS[part]
        elif lit := re.fullmatch(r'["\'](.*)["\']', part):
            out += lit.group(1)
        elif part.isdigit():
            out += part
        else:
            out += part
    return out


def describe_action(action: str) -> str:
    action = action.strip()

    if match := re.search(r"hl\.dsp\.exec_cmd\((.+)\)", action):
        cmd = simplify_command(lua_command_expr(match.group(1)))
        return humanize_command(cmd)

    if match := re.search(r"hl\.dsp\.focus\(\{([^}]+)\}\)", action):
        inner = match.group(1)
        if m := re.search(r'direction\s*=\s*"([^"]+)"', inner):
            return f"Focus window {DIR_NAMES.get(m.group(1), m.group(1))}"
        if m := re.search(r'workspace\s*=\s*"?([^",}]+)"?', inner):
            return f"Focus workspace {m.group(1)}"

    if "hl.dsp.window.close()" in action:
        return "Close active window"
    if "hl.dsp.window.fullscreen()" in action:
        return "Toggle fullscreen"
    if "hl.dsp.window.pseudo()" in action:
        return "Toggle pseudo-tiling"
    if "hl.dsp.workspace.toggle_special()" in action:
        return "Toggle scratchpad workspace"

    if match := re.search(r"hl\.dsp\.window\.float\(\{([^}]+)\}\)", action):
        if "toggle" in match.group(1):
            return "Toggle floating"
    if match := re.search(r"hl\.dsp\.window\.move\(\{([^}]+)\}\)", action):
        inner = match.group(1)
        if m := re.search(r'direction\s*=\s*"([^"]+)"', inner):
            return f"Move window {DIR_NAMES.get(m.group(1), m.group(1))}"
        if m := re.search(r'workspace\s*=\s*"?([^",}]+)"?', inner):
            return f"Move window to workspace {m.group(1)}"
    if match := re.search(r"hl\.dsp\.window\.resize\(\{([^}]+)\}\)", action):
        return "Resize window"
    if match := re.search(r"hl\.dsp\.window\.drag\(\)", action):
        return "Drag window"
    if match := re.search(r"hl\.dsp\.window\.resize\(\)", action):
        return "Resize window (mouse)"

    if match := re.search(r'hl\.dsp\.layout\("([^"]+)"\)', action):
        return f"Layout: {match.group(1)}"
    if match := re.search(r"hl\.dsp\.pass\(\{([^}]+)\}\)", action):
        return "Pass key to window"

    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", action):
        return action.replace("_", " ")

    return action


def parse_inline_comment(line: str) -> str | None:
    if match := INLINE_COMMENT_RE.search(line):
        text = match.group(1).strip()
        if text.startswith("="):
            return None
        return text
    return None


def format_entry(combo: str, description: str, section: str | None) -> str:
    combo = normalize_combo(combo)
    if section:
        return f"[{section}] {combo}  →  {description}"
    return f"{combo}  →  {description}"


def parse_file(path: Path) -> list[str]:
    if not path.exists():
        return []

    entries: list[str] = []
    section: str | None = None
    loop_var: str | None = None
    loop_start = 0
    loop_end = 0
    loop_depth = 0

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("--[[") or line == "--":
            continue

        if match := VAR_RE.match(line):
            VARS[match.group(1)] = match.group(2)
            continue

        if line.startswith("--"):
            if match := SECTION_RE.search(line):
                section = match.group(1).strip()
            continue

        if match := FOR_RE.search(line):
            loop_var = match.group(1)
            loop_start = int(match.group(2))
            loop_end = int(match.group(3))
            loop_depth = 1
            continue

        if loop_depth and line == "end":
            loop_depth -= 1
            if loop_depth == 0:
                loop_var = None
            continue

        if not line.startswith("hl.bind("):
            continue

        bind_line = line
        inline_desc = parse_inline_comment(bind_line)
        bind_line = INLINE_COMMENT_RE.sub("", bind_line).rstrip()

        match = BIND_RE.match(bind_line)
        if not match:
            continue

        key_expr, action, trailing_desc = match.groups()

        loop_values = (
            range(loop_start, loop_end + 1) if loop_var and loop_depth else [None]
        )
        for value in loop_values:
            resolved_action = action
            if loop_var and value is not None:
                resolved_action = re.sub(
                    rf"\b{re.escape(loop_var)}\b",
                    str(value),
                    resolved_action,
                )
            description = trailing_desc or describe_action(resolved_action)
            combo = lua_concat(
                key_expr,
                loop_var=loop_var,
                loop_value=value if value is not None else None,
            )
            entries.append(format_entry(combo, description, section))

    return entries


def main() -> int:
    seen: set[str] = set()
    lines: list[str] = []

    for path in KEYBIND_FILES:
        for entry in parse_file(path):
            if entry in seen:
                continue
            seen.add(entry)
            lines.append(entry)

    lines.sort(key=lambda s: s.lower())
    sys.stdout.write("\n".join(lines))
    if lines:
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())