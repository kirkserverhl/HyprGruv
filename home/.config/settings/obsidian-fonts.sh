#!/bin/bash
# Push fonts.sh roles into Obsidian vault appearance.json + matugen snippet CSS.
set -euo pipefail

FONTS_SH="${FONTS_SH:-$HOME/.config/settings/fonts.sh}"
[[ -f "$FONTS_SH" ]] && source "$FONTS_SH"

FONT_TEXT="${FONT_TEXT:-ShureTechMono Nerd Font}"
FONT_UI="${FONT_UI:-Agave Nerd Font Propo}"

update_vault_appearance() {
    local appearance="$1"
    python3 - "$appearance" "$FONT_TEXT" "$FONT_UI" <<'PY'
import json, os, sys

path, text_font, ui_font = sys.argv[1:4]
data = {}
if os.path.isfile(path):
    with open(path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {}

data["textFontFamily"] = text_font
data["interfaceFontFamily"] = ui_font
data["monospaceFontFamily"] = text_font

snippets = list(data.get("enabledCssSnippets") or [])
if "matugen" not in snippets:
    snippets.append("matugen")
data["enabledCssSnippets"] = snippets

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

OBSIDIAN_TYPOGRAPHY_BLOCK='/* Document body text */
.markdown-source-view.mod-cm6 .cm-scroller,
.markdown-preview-view .markdown-preview-sizer {
    font-family: var(--font-text-theme) !important;
}

/* Document headings → UI font (Agave) */
.markdown-source-view.mod-cm6 .cm-header.cm-header-1,
.markdown-source-view.mod-cm6 .cm-header.cm-header-2,
.markdown-source-view.mod-cm6 .cm-header.cm-header-3,
.markdown-source-view.mod-cm6 .cm-header.cm-header-4,
.markdown-source-view.mod-cm6 .cm-header.cm-header-5,
.markdown-source-view.mod-cm6 .cm-header.cm-header-6,
.markdown-preview-view h1,
.markdown-preview-view h2,
.markdown-preview-view h3,
.markdown-preview-view h4,
.markdown-preview-view h5,
.markdown-preview-view h6 {
    font-family: var(--font-interface-theme) !important;
}'

patch_obsidian_css() {
    local css="$1"
    [[ -f "$css" ]] || return 0

    if grep -q '--font-text-theme:' "$css"; then
        sed -i \
            -e 's|--font-interface-theme: "[^"]*"|--font-interface-theme: "'"$FONT_UI"'", sans-serif|g' \
            -e 's|--font-text-theme: "[^"]*"|--font-text-theme: "'"$FONT_TEXT"'", monospace|g' \
            -e 's|--font-monospace-theme: "[^"]*"|--font-monospace-theme: "'"$FONT_TEXT"'", monospace|g' \
            "$css"
        return 0
    fi

    sed -i \
        -e '/--graph-background:/a\
\
    /* ── Typography (fonts.sh: UI = Agave, TEXT = ShureTechMono) ─ */\
    --font-interface-theme: "'"$FONT_UI"'", sans-serif;\
    --font-text-theme: "'"$FONT_TEXT"'", monospace;\
    --font-monospace-theme: "'"$FONT_TEXT"'", monospace;' \
        "$css"

    if ! grep -q 'Document body text' "$css"; then
        printf '\n%s\n' "$OBSIDIAN_TYPOGRAPHY_BLOCK" >>"$css"
    fi
}

discover_vaults() {
    local -a vaults=()
    local obsidian_json="$HOME/.config/obsidian/obsidian.json"
    local vault

    for vault in \
        "$HOME/Documents/Obsidian" \
        "$HOME/Obsidian" \
        "$HOME/vaults" \
        "$HOME/Documents/hyprcourse/Hyprland"; do
        [[ -d "$vault/.obsidian" ]] && vaults+=("$vault")
    done

    if [[ -f "$obsidian_json" ]]; then
        while IFS= read -r vault; do
            [[ -n "$vault" && -d "$vault/.obsidian" ]] && vaults+=("$vault")
        done < <(python3 - "$obsidian_json" <<'PY'
import json, sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

for entry in (data.get("vaults") or {}).values():
    path = entry.get("path")
    if path:
        print(path)
PY
)
    fi

    printf '%s\n' "${vaults[@]}" | awk '!seen[$0]++'
}

updated=0
while IFS= read -r vault; do
    [[ -n "$vault" ]] || continue
    appearance="$vault/.obsidian/appearance.json"
    mkdir -p "$(dirname "$appearance")"
    update_vault_appearance "$appearance"
    patch_obsidian_css "$vault/.obsidian/snippets/matugen.css"
    echo "  ✓ Obsidian vault: $vault"
    echo "      text=$FONT_TEXT, headings/ui=$FONT_UI"
    updated=1
done < <(discover_vaults)

patch_obsidian_css "$HOME/.config/obsidian/matugen.css"

if [[ "$updated" -eq 0 ]]; then
    echo "  (no Obsidian vaults found)"
else
    echo "  ✓ Obsidian fonts applied — reload Obsidian if it is open"
fi