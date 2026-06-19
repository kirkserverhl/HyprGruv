#!/usr/bin/env python3
"""Waypaper-style wallpaper picker for theme switcher (GTK3)."""

from __future__ import annotations

import os
import random
import re
import subprocess
import sys
import threading
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
CACHE_DIR = HOME / ".cache" / "colorschemes-wallpaper-thumbs"
STYLE_FILE = HOME / ".config" / "waypaper" / "style.css"
MATUGEN_CONF = HOME / ".config/hypr/colors/custom/matugen.conf"
AWWW_SCRIPT = COLORSCHEMES / "awww-wallpaper.sh"
STATE_FILE = COLORSCHEMES / ".wallpaper-state"
MONITOR_STATE = COLORSCHEMES / ".wallpaper-monitor"
GRID_COLUMNS = 3
GRID_GAP = 10
PANEL_PADDING = 16
CELL_BORDER = 3
CELL_INSET = 1
THUMB_ASPECT_W = 16
THUMB_ASPECT_H = 9
THUMB_SOURCE_MAX = 960
SCROLLBAR_RESERVE = 14
RESIZE_DEBOUNCE_MS = 120


def resolve_wallpaper_dir(theme: str) -> Path | None:
    folder_map = {"nord-darker": "nord"}
    folder = folder_map.get(theme, theme)
    for root in (
        HOME / "Wallpapers" / "themed-wallpapers",
        HOME / "wallpapers" / "themed-wallpapers",
    ):
        candidate = root / folder
        if candidate.is_dir():
            return candidate
    fallback = COLORSCHEMES / theme / "wallpapers"
    return fallback if fallback.is_dir() else None


def list_wallpapers(directory: Path) -> list[str]:
    if get_image_paths:
        paths = get_image_paths("awww", [directory], False, False, False, False)
        return sorted(paths)
    exts = {".jpg", ".jpeg", ".png", ".webp", ".svg"}
    return sorted(
        str(p)
        for p in directory.iterdir()
        if p.is_file() and p.suffix.lower() in exts
    )


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


def selection_border_colors() -> tuple[str, str]:
    """Primary + secondary from matugen (matches Hyprland active border tones)."""
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
    grid frame.wallpaper-cell {{
        padding: 0;
        margin: 0;
        border: none;
        background-color: transparent;
    }}
    grid frame.wallpaper-cell > border {{
        border: {CELL_BORDER}px solid transparent;
        border-radius: 8px;
        background-color: transparent;
        padding: 0;
        margin: 0;
    }}
    grid frame.wallpaper-cell:hover > border {{
        background-color: alpha({primary}, 0.10);
    }}
    grid frame.wallpaper-cell.selected > border {{
        border: {CELL_BORDER}px solid {primary};
        background-color: alpha({secondary}, 0.40);
        box-shadow: inset 0 0 0 1px alpha({secondary}, 0.95),
                    0 0 0 1px {primary},
                    0 0 12px alpha({primary}, 0.55);
    }}
    .wallpaper-cell image {{
        padding: 0;
        margin: 0;
        border-radius: 5px;
    }}
    """.encode()


def load_stylesheet() -> None:
    """Load waypaper style.css (matugen colors + blurred panel alpha)."""
    provider = Gtk.CssProvider()
    fallback = b".highlighted-button { border: 1px solid @theme_selected_bg_color; }"
    thumb_overrides = thumb_css_overrides()
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


def _tag_widget(widget: Gtk.Widget, name: str) -> None:
    widget.set_name(name)


def cover_pixbuf(pixbuf: GdkPixbuf.Pixbuf, width: int, height: int) -> GdkPixbuf.Pixbuf:
    """Scale and center-crop to fill width×height (palette-style cover)."""
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


def thumbnail_for(path: str) -> GdkPixbuf.Pixbuf | None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        if cache_image and get_cached_image_path:
            cache_image(path, CACHE_DIR)
            cached = get_cached_image_path(path, CACHE_DIR)
            if cached.is_file():
                return GdkPixbuf.Pixbuf.new_from_file_at_size(
                    str(cached), THUMB_SOURCE_MAX, THUMB_SOURCE_MAX
                )
        return GdkPixbuf.Pixbuf.new_from_file_at_size(
            path, THUMB_SOURCE_MAX, THUMB_SOURCE_MAX
        )
    except GLib.Error:
        return None


def save_state(theme: str, monitor: str, path: str) -> None:
    STATE_FILE.touch(exist_ok=True)
    lines = STATE_FILE.read_text().splitlines()
    key = f"{theme}@{monitor}:"
    lines = [ln for ln in lines if not ln.startswith(key)]
    lines.append(f"{theme}@{monitor}:{path}")
    if monitor == "all":
        lines = [ln for ln in lines if not ln.startswith(f"{theme}:")]
        lines.append(f"{theme}:{path}")
    STATE_FILE.write_text("\n".join(lines) + "\n")


def apply_wallpaper(path: str, monitor: str) -> None:
    if os.environ.get("THEME_SWITCHER_APPLY"):
        return
    if AWWW_SCRIPT.is_file():
        subprocess.run(
            ["bash", str(AWWW_SCRIPT), path, monitor],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


class WallpaperPicker(Gtk.Window):
    def __init__(self, theme: str, wallpaper_dir: Path, images: list[str]) -> None:
        from wallpaper_picker_support import THEME_LABELS

        label = THEME_LABELS.get(theme, theme.replace("-", " ").title())
        super().__init__(title=f"Waypaper · {label}")
        self.theme = theme
        self.wallpaper_dir = wallpaper_dir
        self.image_paths = images
        self.thumbnails: list[GdkPixbuf.Pixbuf | None] = []
        self.filtered_indices: list[int] = list(range(len(images)))
        self.selected_index = 0
        self.result: str | None = None
        self.cell_width = 0
        self.cell_height = 0
        self._grid_ready = False
        self._grid_reloading = False
        self._resize_timeout_id = 0
        self._pending_cell_width = 0
        self._pending_cell_height = 0

        self.monitor = "all"
        if MONITOR_STATE.is_file():
            saved = MONITOR_STATE.read_text().strip()
            if saved:
                self.monitor = saved

        self.set_default_size(820, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self._enable_transparency()
        self.connect("delete-event", self._on_cancel)
        self.connect("key-press-event", self._on_key_press)

        load_stylesheet()
        self._build_ui()
        threading.Thread(target=self._load_thumbnails, daemon=True).start()

    def _enable_transparency(self) -> None:
        """Semi-transparent CSS backgrounds; Hyprland decoration blur shows through."""
        screen = Gdk.Screen.get_default()
        if screen is not None and screen.is_composited():
            visual = screen.get_rgba_visual()
            if visual is not None:
                self.set_visual(visual)
            self.set_app_paintable(True)

    def _build_ui(self) -> None:
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.main_box.set_can_focus(True)
        _tag_widget(self.main_box, "main-window")
        self.add(self.main_box)

        self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=GRID_GAP)
        _tag_widget(self.content, "wallpaper-content")
        self.content.set_margin_start(PANEL_PADDING)
        self.content.set_margin_end(PANEL_PADDING)
        self.content.set_margin_top(PANEL_PADDING)
        self.content.set_margin_bottom(PANEL_PADDING)
        self.main_box.pack_start(self.content, True, True, 0)

        self.preview_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        _tag_widget(self.preview_panel, "wallpaper-preview")
        self.content.pack_start(self.preview_panel, True, True, 0)

        self.scrolled = Gtk.ScrolledWindow()
        self.scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scrolled.set_can_focus(False)
        self.scrolled.connect("size-allocate", self._on_scrolled_allocate)
        self.scrolled.connect("key-press-event", self._on_key_press)
        self.preview_panel.pack_start(self.scrolled, True, True, 0)

        self.grid_shell = Gtk.Alignment.new(0.5, 0.0, 0.0, 0.0)
        self.grid_shell.set_vexpand(False)

        self.grid = Gtk.Grid()
        self.grid.set_column_spacing(GRID_GAP)
        self.grid.set_row_spacing(GRID_GAP)
        self.grid.set_column_homogeneous(False)
        self.grid.set_row_homogeneous(False)
        self.grid.set_valign(Gtk.Align.START)
        self.grid.set_vexpand(False)
        self.grid.set_hexpand(True)
        self.grid_shell.add(self.grid)
        self.scrolled.add(self.grid_shell)

        self.loading_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        self.preview_panel.pack_end(self.loading_box, False, False, 0)
        self.loading_label = Gtk.Label(label="Loading previews...")
        self.loading_box.pack_start(self.loading_label, False, False, 0)

        self.footer_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        _tag_widget(self.footer_panel, "wallpaper-footer")
        self.footer_panel.get_style_context().add_class("bottom-controls")
        self.content.pack_end(self.footer_panel, False, False, 0)

        footer_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        footer_row.set_halign(Gtk.Align.CENTER)
        self.footer_panel.pack_start(footer_row, False, False, 0)

        footer_align = Gtk.Alignment.new(0.5, 0.5, 0.0, 0.0)
        footer_row.pack_start(footer_align, True, False, 0)

        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("Search...")
        from wallpaper_picker_support import FOOTER_CONTROL_HEIGHT, uniform_footer_button

        self.search_entry.set_size_request(220, FOOTER_CONTROL_HEIGHT)
        self.search_entry.connect("changed", self._on_search_changed)
        self.search_entry.connect("key-press-event", self._on_key_press)
        footer.pack_start(self.search_entry, False, False, 0)

        self.random_button = uniform_footer_button(Gtk.Button(label="Random"))
        self.random_button.connect("clicked", self._on_random)
        footer.pack_start(self.random_button, False, False, 0)

        self.monitor_names = ["All", *get_monitors()]
        self.monitor_combo = Gtk.ComboBoxText()
        self.monitor_combo.set_size_request(120, FOOTER_CONTROL_HEIGHT)
        for name in self.monitor_names:
            self.monitor_combo.append_text(name)
        target = "All" if self.monitor == "all" else self.monitor
        if target in self.monitor_names:
            self.monitor_combo.set_active(self.monitor_names.index(target))
        self.monitor_combo.connect("changed", self._on_monitor_changed)
        footer.pack_start(self.monitor_combo, False, False, 0)

        footer_align.add(footer)
        self.main_box.connect("key-press-event", self._on_key_press)
        self.connect("map", self._on_window_map)

    def _load_thumbnails(self) -> None:
        thumbs: list[GdkPixbuf.Pixbuf | None] = []
        for path in self.image_paths:
            thumbs.append(thumbnail_for(path))
        GLib.idle_add(self._thumbnails_ready, thumbs)

    def _thumbnails_ready(self, thumbs: list[GdkPixbuf.Pixbuf | None]) -> None:
        self.thumbnails = thumbs
        self.loading_box.set_visible(False)
        self._grid_ready = True
        self.selected_index = 0
        self._reload_grid()
        self._scroll_to_selected()
        return False

    def _on_search_changed(self, _entry: Gtk.Entry) -> None:
        query = self.search_entry.get_text().strip().lower()
        if not query:
            self.filtered_indices = list(range(len(self.image_paths)))
        else:
            self.filtered_indices = [
                i
                for i, path in enumerate(self.image_paths)
                if query in Path(path).name.lower()
            ]
        self.selected_index = 0
        self._reload_grid()

    def _stable_viewport_width(self) -> int:
        """Use window width (minus scrollbar reserve) to avoid scrollbar feedback loops."""
        width = self.get_allocation().width
        if width < 100:
            width = self.get_default_size()[0]
        return max(100, width - SCROLLBAR_RESERVE)

    def _compute_cell_dimensions(self, viewport_width: int) -> tuple[int, int]:
        inner_w = viewport_width - (PANEL_PADDING * 2) - (GRID_GAP * (GRID_COLUMNS - 1))
        width = max(96, inner_w // GRID_COLUMNS)
        height = max(54, (width * THUMB_ASPECT_H) // THUMB_ASPECT_W)
        return width, height

    def _schedule_grid_resize(self, width: int, height: int) -> None:
        self._pending_cell_width = width
        self._pending_cell_height = height
        if self._resize_timeout_id:
            return
        self._resize_timeout_id = GLib.timeout_add(
            RESIZE_DEBOUNCE_MS,
            self._apply_pending_resize,
        )

    def _apply_pending_resize(self) -> bool:
        self._resize_timeout_id = 0
        if not self._grid_ready or self._grid_reloading:
            return False
        new_w = self._pending_cell_width
        new_h = self._pending_cell_height
        if new_w <= 0 or new_h <= 0:
            return False
        if self.cell_width and abs(new_w - self.cell_width) < 4:
            return False
        self.cell_width = new_w
        self.cell_height = new_h
        self._reload_grid()
        return False

    def _on_scrolled_allocate(self, _scrolled: Gtk.ScrolledWindow, _allocation) -> None:
        new_w, new_h = self._compute_cell_dimensions(self._stable_viewport_width())
        if self.cell_width <= 0:
            self.cell_width = new_w
            self.cell_height = new_h
            return
        self._schedule_grid_resize(new_w, new_h)

    def _reload_grid(self) -> None:
        if self._grid_reloading:
            return
        if not self._grid_ready and not self.thumbnails:
            return

        if self.cell_width <= 0:
            self.cell_width, self.cell_height = self._compute_cell_dimensions(
                self._stable_viewport_width()
            )

        self._grid_reloading = True
        try:
            self._populate_grid()
        finally:
            self._grid_reloading = False

    def _populate_grid(self) -> None:
        for child in self.grid.get_children():
            self.grid.remove(child)

        cell_w = self.cell_width
        cell_h = self.cell_height
        pad = CELL_BORDER + CELL_INSET
        img_w = max(1, cell_w - (pad * 2))
        img_h = max(1, cell_h - (pad * 2))
        for slot, index in enumerate(self.filtered_indices):
            path = self.image_paths[index]
            thumb = self.thumbnails[index] if index < len(self.thumbnails) else None
            row, col = divmod(slot, GRID_COLUMNS)

            cell_frame = Gtk.Frame()
            cell_frame.set_shadow_type(Gtk.ShadowType.NONE)
            cell_frame.set_size_request(cell_w, cell_h)
            cell_frame.set_hexpand(False)
            cell_frame.set_vexpand(False)
            cell_frame.set_label("")
            cell_style = cell_frame.get_style_context()
            cell_style.add_class("wallpaper-cell")
            if slot == self.selected_index:
                cell_style.add_class("selected")

            align = Gtk.Alignment.new(0.5, 0.5, 0.0, 0.0)
            align.set_size_request(img_w, img_h)

            if thumb:
                preview = cover_pixbuf(thumb, img_w, img_h)
                image = Gtk.Image.new_from_pixbuf(preview)
                image.set_size_request(img_w, img_h)
            else:
                image = Gtk.Image.new_from_icon_name("image-x-generic", Gtk.IconSize.DIALOG)
            image.set_tooltip_text(Path(path).name)
            align.add(image)
            cell_frame.add(align)

            cell_frame.connect("button-press-event", self._on_cell_pressed, path)
            self.grid.attach(cell_frame, col, row, 1, 1)

        self.grid.show_all()

    def _on_window_map(self, *_args) -> None:
        GLib.idle_add(self._focus_grid)

    def _focus_grid(self) -> bool:
        self.main_box.grab_focus()
        return False

    def _scroll_to_selected(self) -> None:
        if self.cell_height <= 0 or not self.filtered_indices:
            return
        row = self.selected_index // GRID_COLUMNS
        y = row * (self.cell_height + GRID_GAP)
        self.scrolled.get_vadjustment().set_value(y)

    def _move_selection(self, delta: int) -> None:
        if not self.filtered_indices:
            return
        last = len(self.filtered_indices) - 1
        self.selected_index = max(0, min(self.selected_index + delta, last))
        self._reload_grid()
        self._scroll_to_selected()

    def _apply_selection(self) -> None:
        if not self.filtered_indices:
            return
        path = self.image_paths[self.filtered_indices[self.selected_index]]
        self._finish(path)

    def _on_monitor_changed(self, combo: Gtk.ComboBoxText) -> None:
        label = combo.get_active_text()
        self.monitor = "all" if label == "All" else label
        MONITOR_STATE.write_text(self.monitor + "\n")

    def _finish(self, path: str) -> None:
        save_state(self.theme, self.monitor, path)
        apply_wallpaper(path, self.monitor)
        self.result = path
        Gtk.main_quit()

    def _on_cell_pressed(self, _widget: Gtk.Widget, event, path: str) -> bool:
        if event.button == 1:
            self._finish(path)
            return True
        return False

    def _on_random(self, _button: Gtk.Button) -> None:
        if not self.image_paths:
            return
        self._finish(random.choice(self.image_paths))

    def _on_cancel(self, *_args) -> bool:
        Gtk.main_quit()
        return False

    def _on_key_press(self, _widget, event) -> bool:
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True

        if not self.filtered_indices:
            return False

        if event.keyval == Gdk.KEY_Left:
            self._move_selection(-1)
            return True
        if event.keyval == Gdk.KEY_Right:
            self._move_selection(1)
            return True
        if event.keyval == Gdk.KEY_Up:
            self._move_selection(-GRID_COLUMNS)
            return True
        if event.keyval == Gdk.KEY_Down:
            self._move_selection(GRID_COLUMNS)
            return True
        if event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            self._apply_selection()
            return True

        return False


def main() -> int:
    theme = sys.argv[1] if len(sys.argv) > 1 else ""
    if not theme and (COLORSCHEMES / ".current-theme").is_file():
        theme = (COLORSCHEMES / ".current-theme").read_text().strip()

    if not theme:
        print("No theme specified", file=sys.stderr)
        return 1

    wallpaper_dir = resolve_wallpaper_dir(theme)
    if not wallpaper_dir:
        print(f"No wallpaper directory for {theme}", file=sys.stderr)
        return 1

    images = list_wallpapers(wallpaper_dir)
    if not images:
        print(f"No wallpapers in {wallpaper_dir}", file=sys.stderr)
        return 1

    # Wayland app_id comes from prgname; must match Hyprland window rules.
    GLib.set_prgname("waypaper")
    Gdk.set_program_class("waypaper")
    Gtk.init(sys.argv if len(sys.argv) > 1 else None)
    picker = WallpaperPicker(theme, wallpaper_dir, images)
    picker.show_all()
    Gtk.main()

    if picker.result:
        print(picker.result)
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())