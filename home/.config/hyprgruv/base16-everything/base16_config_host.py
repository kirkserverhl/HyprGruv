#!/usr/bin/env python3
"""Native messaging host for Base16 Everything (upstream-compatible)."""

import json
import re
import struct
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "base16-everything" / "config.yaml"


def parse_yaml_palette(yaml_content: str) -> list[str]:
    palette: list[str] = []
    base_keys = [
        "base00",
        "base01",
        "base02",
        "base03",
        "base04",
        "base05",
        "base06",
        "base07",
        "base08",
        "base09",
        "base0A",
        "base0B",
        "base0C",
        "base0D",
        "base0E",
        "base0F",
        "base10",
        "base11",
        "base12",
        "base13",
        "base14",
        "base15",
        "base16",
        "base17",
    ]

    for key in base_keys:
        pattern = rf'{key}:\s*["\']?#?([0-9a-fA-F]{{6}})["\']?'
        match = re.search(pattern, yaml_content)
        if match:
            palette.append("#" + match.group(1).lower())

    return palette


def parse_config(yaml_content: str) -> dict:
    palette = parse_yaml_palette(yaml_content)
    if len(palette) == 24:
        return {"palette": palette}
    return {
        "palette": None,
        "error": f"Invalid palette - expected 24 colors, got {len(palette)}",
    }


def read_config() -> dict:
    if not CONFIG_PATH.exists():
        return {"error": f"Config file not found: {CONFIG_PATH}"}

    try:
        content = CONFIG_PATH.read_text(encoding="utf-8")
        config = parse_config(content)
        config["path"] = str(CONFIG_PATH)
        config["exists"] = True
        return config
    except OSError as exc:
        return {"error": str(exc)}


def get_message():
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        return None
    message_length = struct.unpack("=I", raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode("utf-8")
    return json.loads(message)


def send_message(message: dict) -> None:
    encoded = json.dumps(message).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("=I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def main() -> None:
    while True:
        message = get_message()
        if message is None:
            break

        msg_type = message.get("type")
        if msg_type == "GET_CONFIG":
            send_message(read_config())
        elif msg_type == "PING":
            send_message({"pong": True})
        else:
            send_message({"error": "Unknown message type"})


if __name__ == "__main__":
    main()