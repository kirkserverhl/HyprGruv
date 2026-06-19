#!/usr/bin/env python3
"""GTK theme picker — same shell as wallpaper-picker (Waypaper float/blur)."""

from __future__ import annotations

import random
import re
import sys
import threading
from pathlib import Path

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

from wallpaper_picker_support import (
    CELL_BORDER,
    CELL_INSET,
    COLORSCHEMES,
    GRID_COLUMNS,
    GRID_GAP,
    LABEL_SLOT,
    PANEL_PADDING,
    RESIZE_DEBOUNCE_MS,
    SCROLLBAR_RESERVE,
    THUMB_ASPECT_H,
    THUMB_ASPECT_W,
    THEME_LABELS,
    WAYPAPER_MODE,
    ThemeEntry,
    cover_pixbuf,
    init_waypaper_window,
    list_wallpapers,
    load_active_themes,
    load_stylesheet,
    preview_pixbuf_for,
    random_waypaper_preview,
    resolve_wallpaper_dir,
    thumb_css_overrides,
    uniform_footer_button,
)

CACHE_DIR = Path.home() / ".cache" / "colorschemes-theme-thumbs"


class ThemePicker(Gtk.Window):
    def __init__(self, themes: list[ThemeEntry]) -> None:
        super().__init__(title="Waypaper")
        self.themes = themes
        self.selected_index = 0
        self.result: str | None = None
        self.previews: list[GdkPixbuf.Pixbuf | None] = [None] * len(themes)
        self.cell_width = 0
        self.cell_height = 0
        self._grid_ready = False
        self._grid_reloading = False
        self._resize_timeout_id = 0
        self._pending_cell_width = 0
        self._pending_cell_height = 0

        self.set_default_size(820, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self._enable_transparency()
        self.connect("delete-event", self._on_cancel)
        self.connect("key-press-event", self._on_key_press)

        load_stylesheet(extra_css=thumb_css_overrides() + self._theme_label_css())
        self._build_ui()
        threading.Thread(target=self._load_previews, daemon=True).start()

    def _theme_label_css(self) -> bytes:
        return b"""
        .theme-cell-label {
            color: #dde4e3;
            font-weight: 600;
            padding: 2px 0 0 0;
        }
        """

    def _enable_transparency(self) -> None:
        screen = Gdk.Screen.get_default()
        if screen is not None and screen.is_composited():
            visual = screen.get_rgba_visual()
            if visual is not None:
                self.set_visual(visual)
            self.set_app_paintable(True)

    def _build_ui(self) -> None:
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.main_box.set_can_focus(True)
        self.main_box.set_name("main-window")
        self.add(self.main_box)

        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=GRID_GAP)
        content.set_name("wallpaper-content")
        content.set_margin_start(PANEL_PADDING)
        content.set_margin_end(PANEL_PADDING)
        content.set_margin_top(PANEL_PADDING)
        content.set_margin_bottom(PANEL_PADDING)
        self.main_box.pack_start(content, True, True, 0)

        preview_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        preview_panel.set_name("wallpaper-preview")
        content.pack_start(preview_panel, True, True, 0)

        self.scrolled = Gtk.ScrolledWindow()
        self.scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scrolled.set_can_focus(False)
        self.scrolled.connect("size-allocate", self._on_scrolled_allocate)
        self.scrolled.connect("key-press-event", self._on_key_press)
        preview_panel.pack_start(self.scrolled, True, True, 0)

        self.grid_shell = Gtk.Alignment.new(0.5, 0.0, 0.0, 0.0)
        self.grid_shell.set_vexpand(False)
        self.grid = Gtk.Grid()
        self.grid.set_column_spacing(GRID_GAP)
        self.grid.set_row_spacing(GRID_GAP)
        self.grid.set_valign(Gtk.Align.START)
        self.grid.set_vexpand(False)
        self.grid.set_hexpand(True)
        self.grid_shell.add(self.grid)
        self.scrolled.add(self.grid_shell)

        self.loading_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        preview_panel.pack_end(self.loading_box, False, False, 0)
        self.loading_label = Gtk.Label(label="Loading themes...")
        self.loading_box.pack_start(self.loading_label, False, False, 0)

        footer_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        footer_panel.set_name("wallpaper-footer")
        footer_panel.get_style_context().add_class("bottom-controls")
        content.pack_end(footer_panel, False, False, 0)

        footer_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        footer_panel.pack_start(footer_row, False, False, 0)
        footer_align = Gtk.Alignment.new(0.5, 0.5, 0.0, 0.0)
        footer_row.pack_start(footer_align, True, False, 0)

        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.selection_label = Gtk.Label(label="")
        self.selection_label.set_size_request(220, -1)
        self.selection_label.set_halign(Gtk.Align.START)
        self.selection_label.set_xalign(0.0)
        footer.pack_start(self.selection_label, False, False, 0)

        continue_btn = uniform_footer_button(Gtk.Button(label="Continue"))
        continue_btn.connect("clicked", lambda *_: self._apply_selection())
        footer.pack_start(continue_btn, False, False, 0)

        self.hint_label = Gtk.Label(label="Enter · choose wallpaper")
        footer.pack_start(self.hint_label, False, False, 0)

        footer_align.add(footer)
        self.main_box.connect("key-press-event", self._on_key_press)
        self.connect("map", self._on_window_map)

    def _load_previews(self) -> None:
        thumbs: list[GdkPixbuf.Pixbuf | None] = []
        for entry in self.themes:
            thumbs.append(preview_pixbuf_for(entry.preview_path, CACHE_DIR))
        GLib.idle_add(self._previews_ready, thumbs)

    def _previews_ready(self, thumbs: list[GdkPixbuf.Pixbuf | None]) -> None:
        self.previews = thumbs
        self.loading_box.set_visible(False)
        self._grid_ready = True
        self.selected_index = 0
        self._update_selection_label()
        self._reload_grid()
        return False

    def _update_selection_label(self) -> None:
        if not self.themes:
            self.selection_label.set_text("")
            return
        entry = self.themes[self.selected_index]
        self.selection_label.set_text(entry.label)
        if entry.theme_id == WAYPAPER_MODE:
            self.hint_label.set_text("Enter · open Waypaper GUI")
        else:
            self.hint_label.set_text("Enter · choose wallpaper")

    def _stable_viewport_width(self) -> int:
        width = self.get_allocation().width
        if width < 100:
            width = self.get_default_size()[0]
        return max(100, width - SCROLLBAR_RESERVE)

    def _grid_columns(self) -> int:
        return min(GRID_COLUMNS, max(1, len(self.themes)))

    def _compute_cell_dimensions(self, viewport_width: int) -> tuple[int, int]:
        cols = self._grid_columns()
        inner_w = viewport_width - (PANEL_PADDING * 2) - (GRID_GAP * (cols - 1))
        width = max(96, inner_w // cols)
        height = max(54, (width * THUMB_ASPECT_H) // THUMB_ASPECT_W)
        height += LABEL_SLOT
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
        if self._grid_reloading or not self._grid_ready:
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

        cols = self._grid_columns()
        cell_w = self.cell_width
        cell_h = self.cell_height
        pad = CELL_BORDER + CELL_INSET
        img_w = max(1, cell_w - (pad * 2))
        img_h = max(1, cell_h - (pad * 2) - LABEL_SLOT)

        for slot, entry in enumerate(self.themes):
            row, col = divmod(slot, cols)
            thumb = self.previews[slot] if slot < len(self.previews) else None

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

            cell_inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            cell_inner.set_halign(Gtk.Align.CENTER)

            img_align = Gtk.Alignment.new(0.5, 0.5, 0.0, 0.0)
            img_align.set_size_request(img_w, img_h)
            if thumb:
                preview = cover_pixbuf(thumb, img_w, img_h)
                image = Gtk.Image.new_from_pixbuf(preview)
                image.set_size_request(img_w, img_h)
            else:
                image = Gtk.Image.new_from_icon_name("image-x-generic", Gtk.IconSize.DIALOG)
            image.set_tooltip_text(entry.label)
            img_align.add(image)

            name_label = Gtk.Label(label=entry.label)
            name_label.get_style_context().add_class("theme-cell-label")

            cell_inner.pack_start(img_align, False, False, 0)
            cell_inner.pack_start(name_label, False, False, 0)
            cell_frame.add(cell_inner)

            cell_frame.connect("button-press-event", self._on_cell_pressed, entry.theme_id)
            self.grid.attach(cell_frame, col, row, 1, 1)

        self.grid.show_all()

    def _on_window_map(self, *_args) -> None:
        GLib.idle_add(self._focus_grid)

    def _focus_grid(self) -> bool:
        self.main_box.grab_focus()
        return False

    def _move_selection(self, delta: int) -> None:
        if not self.themes:
            return
        last = len(self.themes) - 1
        self.selected_index = max(0, min(self.selected_index + delta, last))
        self._update_selection_label()
        self._reload_grid()

    def _apply_selection(self) -> None:
        if not self.themes:
            return
        self.result = self.themes[self.selected_index].theme_id
        Gtk.main_quit()

    def _on_cell_pressed(self, _widget: Gtk.Widget, event, theme_id: str) -> bool:
        if event.button != 1:
            return False
        for index, entry in enumerate(self.themes):
            if entry.theme_id == theme_id:
                self.selected_index = index
                break
        self._apply_selection()
        return True

    def _on_cancel(self, *_args) -> bool:
        Gtk.main_quit()
        return False

    def _on_key_press(self, _widget, event) -> bool:
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        if not self.themes:
            return False
        cols = self._grid_columns()
        if event.keyval == Gdk.KEY_Left:
            self._move_selection(-1)
            return True
        if event.keyval == Gdk.KEY_Right:
            self._move_selection(1)
            return True
        if event.keyval == Gdk.KEY_Up:
            self._move_selection(-cols)
            return True
        if event.keyval == Gdk.KEY_Down:
            self._move_selection(cols)
            return True
        if event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            self._apply_selection()
            return True
        return False


def build_theme_entries() -> list[ThemeEntry]:
    entries: list[ThemeEntry] = []
    for theme_id in load_active_themes():
        theme_dir = COLORSCHEMES / theme_id
        if not theme_dir.is_dir():
            continue
        wp_dir = resolve_wallpaper_dir(theme_id)
        preview_path = None
        if wp_dir:
            images = list_wallpapers(wp_dir)
            if images:
                preview_path = random.choice(images)
        label = THEME_LABELS.get(theme_id, theme_id.replace("-", " ").title())
        entries.append(ThemeEntry(theme_id=theme_id, label=label, preview_path=preview_path))
    entries.append(
        ThemeEntry(
            theme_id=WAYPAPER_MODE,
            label="Waypaper",
            preview_path=random_waypaper_preview(),
        ),
    )
    return entries


def main() -> int:
    themes = build_theme_entries()
    if not themes:
        print("No active themes found", file=sys.stderr)
        return 1

    init_waypaper_window(sys.argv)
    picker = ThemePicker(themes)
    picker.show_all()
    Gtk.main()

    if picker.result:
        print(picker.result)
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())