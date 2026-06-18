#!/usr/bin/env bash
# networkmanager.sh — launch nm-connection-editor (GUI) with cleaned GTK env

set -euo pipefail

# Clean noisy GTK environment variables for this launch only.
# This prevents some debug spam and theme issues that can appear
# when launching GTK apps from certain contexts.
env -u GDK_DEBUG -u GDK_DISABLE \
    GDK_DEBUG= \
    GDK_DISABLE= \
    nm-connection-editor
