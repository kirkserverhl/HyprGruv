"""Shared helpers for theme-picker.py and wallpaper-picker.py."""

from __future__ import annotations

import os
import random
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

try:
    from waypaper.common import cache_image, get_cached_image_path, get_image_paths
except ImportError:
    cache_image = None
    get_cached_image_path = None
    get_image_paths = None

HOME = Path.home()
COLORSCHEMES = (HOME / ".config/colorschemes").resolve()
STYLE_FILE = HOME / ".config/waypaper/style.css"
MATUGEN_CONF = HOME / ".config/hypr/colors/custom/matugen.conf"
ACTIVE_THEMES_FILE = COLORSCHEMES / "active-themes"

GRID_COLUMNS = 3
GRID_GAP = 10
PANEL_PADDING = 16
CELL_BORDER = 3
CELL_INSET = 1
LABEL_SLOT = 26
THUMB_ASPECT_W = 16
THUMB_ASPECT_H = 9
THUMB_SOURCE_MAX = 960
SCROLLBAR_RESERVE = 14
RESIZE_DEBOUNCE_MS = 120
FOOTER_BUTTON_WIDTH = 96
FOOTER_CONTROL_HEIGHT = 32
WAYPAPER_MODE = "__waypaper__"
WAYPAPER_BIN = HOME / ".local/bin/waypaper"
MATUGEN_STYLE = HOME / ".config/waypaper/colors/matugen.css"
WAYPAPER_CONFIG = HOME / ".config/waypaper/config.ini"

THEME_LABELS = {
    "catppuccin": "Catppuccin",
    "gruvbox-dark": "Gruvbox",
    "nord-darker": "Nord",
    "everforest-dark": "Everforest",
    "noir": "Noir",
    "e-ink": "E-Ink",
    "coast-gruv": "Coast Gruv",
    "forest-night": "Forest Night",
    "warm-stone": "Warm Stone",
}

REGISTRY_FILE = COLORSCHEMES / "themes.registry.json"


@dataclass(frozen=True)
class ThemeEntry:
    theme_id: str
    label: str
    preview_path: str | None


def load_registry_labels() -> dict[str, str]:
    if not REGISTRY_FILE.is_file():
        return dict(THEME_LABELS)
    try:
        import json

        data = json.loads(REGISTRY_FILE.read_text(encoding="utf-8"))
        out = dict(THEME_LABELS)
        for entry in data.get("themes") or []:
            if isinstance(entry, dict) and entry.get("id") and entry.get("label"):
                out[str(entry["id"])] = str(entry["label"])
        return out
    except (OSError, ValueError):
        return dict(THEME_LABELS)


def load_active_themes() -> list[str]:
    default = ["catppuccin", "gruvbox-dark", "nord-darker"]
    if not ACTIVE_THEMES_FILE.is_file():
        return default
    themes: list[str] = []
    for line in ACTIVE_THEMES_FILE.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            themes.append(line)
    return themes or default


def _dir_has_wallpapers(directory: Path) -> bool:
    exts = {".jpg", ".jpeg", ".png", ".webp", ".svg"}
    try:
        return any(
            p.is_file() and p.suffix.lower() in exts for p in directory.iterdir()
        )
    except OSError:
        return False


def resolve_wallpaper_dir(theme: str) -> Path | None:
    folder = theme
    if REGISTRY_FILE.is_file():
        try:
            import json

            data = json.loads(REGISTRY_FILE.read_text(encoding="utf-8"))
            for entry in data.get("themes") or []:
                if entry.get("id") == theme and entry.get("wallpaper_folder"):
                    folder = str(entry["wallpaper_folder"])
                    break
        except (OSError, ValueError):
            pass
    folder_map = {"nord-darker": "nord"}
    if theme in folder_map and folder == theme:
        folder = folder_map[theme]

    candidates: list[Path] = []
    for root in (
        HOME / "themed-wallpapers",
        HOME / "Wallpapers" / "themed-wallpapers",
        HOME / "wallpapers" / "themed-wallpapers",
    ):
        candidates.append(root / folder)
    candidates.append(COLORSCHEMES / theme / "wallpapers")
    if folder != theme:
        candidates.append(COLORSCHEMES / folder / "wallpapers")

    seen: set[Path] = set()
    for candidate in candidates:
        try:
            resolved = candidate.resolve()
        except OSError:
            continue
        if resolved in seen or not resolved.is_dir():
            continue
        seen.add(resolved)
        if _dir_has_wallpapers(resolved):
            return resolved
    return None


def list_wallpapers(directory: Path, *, include_subfolders: bool = False) -> list[str]:
    if get_image_paths:
        paths = get_image_paths(
            "awww",
            [directory],
            include_subfolders,
            False,
            False,
            False,
        )
        return sorted(paths)
    exts = {".jpg", ".jpeg", ".png", ".webp", ".svg"}
    if include_subfolders:
        return sorted(
            str(p)
            for p in directory.rglob("*")
            if p.is_file() and p.suffix.lower() in exts
        )
    return sorted(
        str(p)
        for p in directory.iterdir()
        if p.is_file() and p.suffix.lower() in exts
    )


def resolve_waypaper_folder() -> Path | None:
    """Waypaper wallpaper root from ~/.config/waypaper/config.ini (folder key)."""
    folder = HOME / "Wallpapers"
    if WAYPAPER_CONFIG.is_file():
        for line in WAYPAPER_CONFIG.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line.startswith("folder ="):
                continue
            raw = line.split("=", 1)[1].strip()
            folder = Path(raw).expanduser()
            break
    return folder if folder.is_dir() else None


def random_waypaper_preview() -> str | None:
    """Random thumbnail from the Waypaper library (respects subfolders setting)."""
    folder = resolve_waypaper_folder()
    if not folder:
        return None
    include_subfolders = True
    if WAYPAPER_CONFIG.is_file():
        for line in WAYPAPER_CONFIG.read_text(encoding="utf-8").splitlines():
            line = line.strip().lower()
            if line.startswith("subfolders ="):
                include_subfolders = line.split("=", 1)[1].strip() in {"true", "1", "yes"}
                break
    images = list_wallpapers(folder, include_subfolders=include_subfolders)
    return random.choice(images) if images else None


def get_monitors() -> list[str]:
    try:
        out = subprocess.check_output(["awww", "query"], text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    monitors = []
    for line in out.splitlines():
        line = line.strip()
        if line.startswith(":") and ":" in line[1:]:
            name = line.split(":", 2)[1].strip()
            if name:
                monitors.append(name)
    return monitors


def _resolve_matugen_color(name: str, aliases: dict[str, str]) -> str | None:
    value = aliases.get(name)
    if not value:
        return None
    if value.startswith("$"):
        return _resolve_matugen_color(value[1:], aliases)
    match = re.fullmatch(r"rgba\(([0-9a-fA-F]{8})\)", value)
    if match:
        return f"#{match.group(1)[:6]}"
    if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        return value
    return None


def _gtk_rule_properties(css_text: str, selector: str) -> dict[str, str]:
    match = re.search(rf"{re.escape(selector)}\s*\{{([^}}]+)\}}", css_text, re.DOTALL)
    if not match:
        return {}
    props: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        props[key.strip()] = value.strip().rstrip(";").strip()
    return props


def _footer_chrome_tokens() -> tuple[str, str, str, str]:
    """Match footer fields to matugen entry/combobox chrome."""
    bg = "alpha(#1d1c14, 0.85)"
    fg = "#e7e2d5"
    border = "1px solid #cbc7b5"
    hover_bg = "alpha(#212017, 0.95)"
    if MATUGEN_STYLE.is_file():
        css_text = MATUGEN_STYLE.read_text(encoding="utf-8")
        entry_props = _gtk_rule_properties(css_text, "entry")
        combo_props = _gtk_rule_properties(css_text, "combobox")
        bg = entry_props.get("background-color", bg)
        fg = entry_props.get("color", fg)
        border = entry_props.get("border", border)
        hover_bg = combo_props.get("background-color", hover_bg)
    return bg, fg, border, hover_bg


def uniform_footer_button(
    button: Gtk.Button,
    *,
    width: int = FOOTER_BUTTON_WIDTH,
) -> Gtk.Button:
    button.set_size_request(width, FOOTER_CONTROL_HEIGHT)
    button.get_style_context().add_class("footer-control")
    return button


def _set_pointer_cursor(widget: Gtk.Widget, *_args) -> bool:
    window = widget.get_window()
    if window:
        window.set_cursor(Gdk.Cursor(widget.get_display(), Gdk.CursorType.HAND2))
    return False


def _clear_pointer_cursor(widget: Gtk.Widget, *_args) -> bool:
    window = widget.get_window()
    if window:
        window.set_cursor(None)
    return False


def _cell_enter(event_box: Gtk.EventBox, _event) -> bool:
    for child in event_box.get_children():
        if isinstance(child, Gtk.Frame):
            child.get_style_context().add_class("hovered")
    _set_pointer_cursor(event_box)
    return False


def _cell_leave(event_box: Gtk.EventBox, _event) -> bool:
    for child in event_box.get_children():
        if isinstance(child, Gtk.Frame):
            child.get_style_context().remove_class("hovered")
    _clear_pointer_cursor(event_box)
    return False


def wrap_clickable_cell(
    cell: Gtk.Widget,
    handler,
    *user_data,
) -> Gtk.EventBox:
    """Wrap a grid cell so clicks on images/labels reach the handler (GTK3)."""
    event_box = Gtk.EventBox()
    event_box.get_style_context().add_class("clickable-cell")
    event_box.add(cell)
    event_box.connect("button-press-event", handler, *user_data)
    event_box.connect("enter-notify-event", _cell_enter)
    event_box.connect("leave-notify-event", _cell_leave)
    return event_box


def launch_waypaper() -> None:
    """Open the full Waypaper GUI (detached from the theme switcher)."""
    cmd = [str(WAYPAPER_BIN)] if WAYPAPER_BIN.is_file() else ["waypaper"]
    subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def selection_border_colors() -> tuple[str, str]:
    primary = "#80d4d8"
    secondary = "#324b4c"
    if not MATUGEN_CONF.is_file():
        return primary, secondary
    aliases: dict[str, str] = {}
    for line in MATUGEN_CONF.read_text().splitlines():
        match = re.match(r"^\s*\$([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$", line)
        if match:
            aliases[match.group(1)] = match.group(2).strip()
    primary = _resolve_matugen_color("primary", aliases) or primary
    secondary = _resolve_matugen_color("secondary", aliases) or secondary
    return primary, secondary


def thumb_css_overrides() -> bytes:
    primary, secondary = selection_border_colors()
    field_bg, field_fg, field_border, field_hover_bg = _footer_chrome_tokens()
    return f"""
    #wallpaper-content {{
        padding: 0;
        margin: 0;
    }}
    #wallpaper-preview {{
        padding: 0;
        margin: 0;
    }}
    #wallpaper-footer {{
        padding: 0;
        margin: 0;
    }}
    #wallpaper-footer entry,
    #wallpaper-footer combobox,
    #wallpaper-footer button.footer-control {{
        background-color: {field_bg};
        color: {field_fg};
        border: {field_border};
        border-radius: 6px;
        padding: 5px 8px;
        background-image: none;
        box-shadow: none;
    }}
    #wallpaper-footer button.footer-control {{
        min-width: {FOOTER_BUTTON_WIDTH}px;
        min-height: {FOOTER_CONTROL_HEIGHT}px;
    }}
    #wallpaper-footer button.footer-control:hover {{
        background-color: {field_hover_bg};
        color: {field_fg};
        border: {field_border};
        background-image: none;
    }}
    #wallpaper-footer button.footer-control:active {{
        background-color: {field_bg};
        color: {field_fg};
        border: {field_border};
        background-image: none;
    }}
    #wallpaper-footer combobox button {{
        background-color: transparent;
        border: none;
        padding: 0 4px;
        min-width: 0;
        min-height: 0;
        background-image: none;
        box-shadow: none;
    }}
    #wallpaper-footer combobox button:hover {{
        background-color: alpha({primary}, 0.15);
        color: {field_fg};
    }}
    grid frame.wallpaper-cell {{
        padding: 0;
        margin: 0;
        border: none;
        background-color: transparent;
    }}
    grid eventbox.clickable-cell {{
        padding: 0;
        margin: 0;
    }}
    grid frame.wallpaper-cell > border {{
        border: {CELL_BORDER}px solid transparent;
        border-radius: 8px;
        background-color: transparent;
        padding: 0;
        margin: 0;
        transition: all 120ms ease-in-out;
    }}
    grid frame.wallpaper-cell.hovered > border {{
        border: {CELL_BORDER}px solid alpha({primary}, 0.55);
        background-color: alpha({primary}, 0.14);
        box-shadow: 0 0 10px alpha({primary}, 0.25);
    }}
    grid frame.wallpaper-cell.selected > border {{
        border: {CELL_BORDER}px solid {primary};
        background-color: alpha({secondary}, 0.40);
        box-shadow: inset 0 0 0 1px alpha({secondary}, 0.95),
                    0 0 0 1px {primary},
                    0 0 12px alpha({primary}, 0.55);
    }}
    grid frame.wallpaper-cell.selected.hovered > border {{
        border: {CELL_BORDER}px solid {primary};
        background-color: alpha({secondary}, 0.52);
        box-shadow: inset 0 0 0 1px alpha({secondary}, 0.95),
                    0 0 0 1px {primary},
                    0 0 16px alpha({primary}, 0.70);
    }}
    .wallpaper-cell image {{
        padding: 0;
        margin: 0;
        border-radius: 5px;
    }}
    """.encode()


def load_stylesheet(*, extra_css: bytes = b"") -> None:
    provider = Gtk.CssProvider()
    fallback = b".highlighted-button { border: 1px solid @theme_selected_bg_color; }"
    thumb_overrides = thumb_css_overrides() + extra_css
    try:
        if STYLE_FILE.is_file():
            css = STYLE_FILE.read_bytes() + thumb_overrides
            provider.load_from_data(css)
        else:
            raise OSError(f"missing stylesheet: {STYLE_FILE}")
    except Exception:
        provider.load_from_data(fallback + thumb_overrides)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )


def cover_pixbuf(pixbuf: GdkPixbuf.Pixbuf, width: int, height: int) -> GdkPixbuf.Pixbuf:
    src_w, src_h = pixbuf.get_width(), pixbuf.get_height()
    if src_w <= 0 or src_h <= 0:
        return pixbuf
    if src_w == width and src_h == height:
        return pixbuf

    scale = max(width / src_w, height / src_h)
    scaled_w = max(1, int(round(src_w * scale)))
    scaled_h = max(1, int(round(src_h * scale)))
    scaled = pixbuf
    if scaled_w != src_w or scaled_h != src_h:
        scaled = pixbuf.scale_simple(scaled_w, scaled_h, GdkPixbuf.InterpType.BILINEAR)

    x = max(0, (scaled.get_width() - width) // 2)
    y = max(0, (scaled.get_height() - height) // 2)
    crop_w = min(width, scaled.get_width() - x)
    crop_h = min(height, scaled.get_height() - y)
    if crop_w <= 0 or crop_h <= 0:
        return scaled
    if crop_w == scaled.get_width() and crop_h == scaled.get_height():
        cropped = scaled
    else:
        cropped = scaled.new_subpixbuf(x, y, crop_w, crop_h)
    if cropped.get_width() != width or cropped.get_height() != height:
        return cropped.scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)
    return cropped


def preview_pixbuf_for(path: str | None, cache_dir: Path) -> GdkPixbuf.Pixbuf | None:
    if not path:
        return None
    cache_dir.mkdir(parents=True, exist_ok=True)
    try:
        if cache_image and get_cached_image_path:
            cache_image(path, cache_dir)
            cached = get_cached_image_path(path, cache_dir)
            if cached.is_file():
                return GdkPixbuf.Pixbuf.new_from_file_at_size(
                    str(cached), THUMB_SOURCE_MAX, THUMB_SOURCE_MAX
                )
        return GdkPixbuf.Pixbuf.new_from_file_at_size(path, THUMB_SOURCE_MAX, THUMB_SOURCE_MAX)
    except GLib.Error:
        return None


def init_waypaper_window(argv: list[str]) -> None:
    GLib.set_prgname("waypaper")
    Gdk.set_program_class("waypaper")
    Gtk.init(argv if len(argv) > 1 else None)