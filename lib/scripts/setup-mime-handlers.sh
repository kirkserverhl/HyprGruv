#!/usr/bin/env bash
# setup-mime-handlers.sh — file openers for nvim, yazi, handlr, Zathura, LibreOffice
set -euo pipefail

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$HYPR_DIR/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "$HYPR_DIR/lib/common.sh"
fi

log() {
    if declare -F log_status >/dev/null 2>&1; then
        log_status "$1"
    else
        echo "$1"
    fi
}

warn() {
    if declare -F log_warning >/dev/null 2>&1; then
        log_warning "$1"
    else
        echo "Warning: $1" >&2
    fi
}

# shellcheck source=apply-mimeapps.sh
source "$SCRIPT_DIR/apply-mimeapps.sh"

log "Installing MIME handler packages (handlr, Zathura, LibreOffice, Ark, sqlitebrowser)..."
sudo pacman -S --needed --noconfirm \
    handlr-regex zathura zathura-pdf-mupdf xdg-utils libreoffice-fresh \
    ark sqlitebrowser shared-mime-info || warn "some MIME handler packages failed to install"

if command -v yay >/dev/null 2>&1 && ! pacman -Q aphototoollibre &>/dev/null; then
    log "Installing aphototoollibre (image handler from mimeapps.list)..."
    yay -S --needed --noconfirm aphototoollibre || warn "aphototoollibre install failed — image MIME types may not open"
fi

if pacman -Q masterpdfeditor &>/dev/null; then
    log "Removing masterpdfeditor..."
    sudo pacman -Rns --noconfirm masterpdfeditor
fi

ICON_DIR="$HYPR_DIR/home/.local/share/icons"
if [[ -d "$ICON_DIR" ]]; then
    log "Removing Master PDF Editor icon leftovers..."
    sudo find "$ICON_DIR" \( -iname '*masterpdf*' -o -iname '*net.codeindustry*MasterPDF*' \) \
        -delete 2>/dev/null || true
fi

# After stow, ~/.local/{bin,share/mime} often resolve into the repo tree.
# GNU install refuses to copy a file onto itself ("are the same file").
same_path() {
    local a b
    a="$(readlink -f "$1" 2>/dev/null || true)"
    b="$(readlink -f "$2" 2>/dev/null || true)"
    [[ -n "$a" && -n "$b" && "$a" == "$b" ]]
}

install_unless_same() {
    local mode="$1" src="$2" dst="$3"
    mkdir -p "$(dirname "$dst")"
    if same_path "$src" "$dst"; then
        return 0
    fi
    install -m "$mode" "$src" "$dst"
}

XDG_OPEN="$HOME/.local/bin/xdg-open"
if [[ ! -x "$XDG_OPEN" && -f "$HYPR_DIR/home/.local/bin/xdg-open" ]]; then
    install_unless_same 0755 "$HYPR_DIR/home/.local/bin/xdg-open" "$XDG_OPEN"
    chmod +x "$XDG_OPEN" 2>/dev/null || true
elif [[ -f "$XDG_OPEN" ]]; then
    chmod +x "$XDG_OPEN"
fi

# Empty per-user mimeapps overrides shadow ~/.config/mimeapps.list and break xdg-open
# for Electron apps (Obsidian, etc.) — links fail silently.
LOCAL_MIMEAPPS="$HOME/.local/share/applications/mimeapps.list"
if [[ -f "$LOCAL_MIMEAPPS" ]] && { [[ ! -s "$LOCAL_MIMEAPPS" ]] || ! grep -q '=' "$LOCAL_MIMEAPPS" 2>/dev/null; }; then
    log "Removing empty mimeapps override: $LOCAL_MIMEAPPS"
    rm -f "$LOCAL_MIMEAPPS"
fi

SQLITE_BIN="$HYPR_DIR/home/.local/bin/hyprgruv-sqlite"
if [[ -f "$SQLITE_BIN" ]]; then
    chmod +x "$SQLITE_BIN"
    mkdir -p "$HOME/.local/bin"
    if [[ ! -e "$HOME/.local/bin/hyprgruv-sqlite" ]]; then
        install_unless_same 0755 "$SQLITE_BIN" "$HOME/.local/bin/hyprgruv-sqlite"
    fi
fi

MIME_SRC="$HYPR_DIR/home/.local/share/mime/packages/hyprgruv-sqlite.xml"
MIME_DST="$HOME/.local/share/mime/packages/hyprgruv-sqlite.xml"
if [[ -f "$MIME_SRC" ]]; then
    log "Registering SQLite globs (*.db, *.sqlite)..."
    mkdir -p "$(dirname "$MIME_DST")"
    if same_path "$MIME_SRC" "$MIME_DST"; then
        log "SQLite MIME package already deployed via stow — skipping copy"
    else
        install -m 0644 "$MIME_SRC" "$MIME_DST"
    fi
    if command -v update-mime-database >/dev/null 2>&1; then
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
    fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
log "Applying MIME defaults from $MIMEAPPS via handlr"
apply_mimeapps_file "$MIMEAPPS"

log "PDF handler: $(xdg-mime query default application/pdf)"
log "Text handler: $(xdg-mime query default text/plain)"
if command -v handlr >/dev/null 2>&1; then
    log "handlr: $(command -v handlr)"
else
    warn "handlr not on PATH after install"
fi
if [[ -x "$XDG_OPEN" ]]; then
    log "xdg-open wrapper: $XDG_OPEN"
fi