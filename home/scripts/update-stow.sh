#!/bin/bash
# update-stow.sh - Restow ~/.hyprgruv/home using --adopt (recommended for your case)

set -euo pipefail

DOTFILES_DIR="$HOME/.hyprgruv"
PACKAGE="home"
TARGET="$HOME"
BACKUP_DIR="$DOTFILES_DIR/backups/$(date +%Y%m%d-%H%M%S)"

cd "$DOTFILES_DIR" || {
    echo "Error: Cannot cd to $DOTFILES_DIR"
    exit 1
}

echo "=== GNU Stow Update for $PACKAGE (using --adopt) ==="
echo "Package      : $PACKAGE"
echo "Target       : $TARGET"
echo "Backups will go to: $BACKUP_DIR (in case you need to recover anything)"
echo

mkdir -p "$BACKUP_DIR"

if [[ ! -d "$PACKAGE" ]]; then
    echo "Error: Package '$PACKAGE' not found!"
    exit 1
fi

# Dry-run first
if [[ "${1:-}" != "--force" ]]; then
    echo "=== DRY-RUN ==="
    stow -n -v -t "$TARGET" "$PACKAGE"
    echo
    echo "⚠️  You will see many 'cannot stow ... --adopt not specified' warnings in dry-run."
    echo "This is normal."
    read -p "Proceed with actual stow using --adopt? (y/N) " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    echo
fi

# Optional: Backup the entire package before adopting (extra safety)
echo "Backing up current package before adopt..."
cp -a "$PACKAGE" "$BACKUP_DIR/package-before-adopt/" 2>/dev/null || true

echo "=== Adopting and stowing $PACKAGE ==="
stow --adopt -v -R -t "$TARGET" "$PACKAGE"

echo
echo "=== Done! ==="
echo "Stow has adopted any differing files into ~/.hyprgruv/home"
echo "Backups saved in: $BACKUP_DIR"
echo
echo "Recommended next steps:"
echo "1. Review changes:   cd ~/.hyprgruv && git status"
echo "2. Check what was adopted:   git diff HEAD -- home"
echo "3. Commit the result:   git add home && git commit -m 'stow adopt: update configs' && git push"
echo
echo "Verify symlinks:"
echo "   ls -l ~/.config/ | head -20"
