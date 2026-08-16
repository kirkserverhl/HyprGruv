#!/usr/bin/env bash
# Region OCR → clipboard (tesseract).
# Shift + any screenshot bind (Print / F7 / middle-click / G502 Print).
set -euo pipefail

if ! command -v grim >/dev/null || ! command -v slurp >/dev/null || ! command -v tesseract >/dev/null; then
	notify-send -e -u low "Transcribe" "Need grim, slurp, and tesseract"
	exit 1
fi

text="$(grim -g "$(slurp)" - | tesseract stdin stdout 2>/dev/null || true)"
text="${text%"${text##*[![:space:]]}"}"
if [[ -z "$text" ]]; then
	notify-send -e -u low "Transcribe" "No text found"
	exit 1
fi

printf '%s' "$text" | wl-copy
notify-send -e -u low "Transcribe" "Copied to clipboard"
