#!/usr/bin/env python3
"""Step Logitech MX Mechanical backlight via HID++ 2.0 Backlight2 (0x1982)."""

from __future__ import annotations

import fcntl
import glob
import os
import struct
import sys
import time

BACKLIGHT2 = 0x1982
SWID = 0x0D
LOGITECH = 0x046D
# Logi Bolt + common MX Mechanical USB PIDs
PIDS = {0xC548, 0xB361, 0xB366, 0xB342, 0xB35F}


def hid_id(uevent: str) -> tuple[int, int] | None:
    for line in uevent.splitlines():
        if line.startswith("HID_ID="):
            parts = line.split("=", 1)[1].split(":")
            if len(parts) >= 3:
                return int(parts[1], 16), int(parts[2], 16)
    return None


def hidpp_nodes() -> list[str]:
    found: list[str] = []
    for uevent_path in glob.glob("/sys/class/hidraw/hidraw*/device/uevent"):
        try:
            txt = open(uevent_path, encoding="utf-8", errors="replace").read()
            desc = open(
                os.path.join(os.path.dirname(uevent_path), "report_descriptor"),
                "rb",
            ).read()
        except OSError:
            continue
        ids = hid_id(txt)
        if not ids or ids[0] != LOGITECH:
            continue
        if ids[1] not in PIDS and "C548" not in txt.upper():
            continue
        if b"\x85\x10" not in desc and b"\x85\x11" not in desc:
            continue
        name = os.path.basename(os.path.dirname(os.path.dirname(uevent_path)))
        node = f"/dev/{name}"
        if os.access(node, os.R_OK | os.W_OK):
            found.append(node)
    return found


def xfer(fd: int, msg: bytes, timeout: float = 0.45) -> bytes | None:
    os.write(fd, msg)
    end = time.time() + timeout
    want_swid = msg[3] & 0x0F
    while time.time() < end:
        try:
            data = os.read(fd, 32)
        except BlockingIOError:
            time.sleep(0.01)
            continue
        if not data or data[0] not in (0x10, 0x11):
            continue
        if len(data) > 3 and (data[3] & 0x0F) == want_swid:
            return data
        # error from receiver: feature index 0xFF
        if len(data) > 2 and data[2] == 0xFF:
            return data
    return None


def long_msg(dev: int, feat_idx: int, fn: int, payload: bytes = b"") -> bytes:
    body = bytes([0x11, dev, feat_idx, ((fn << 4) | SWID)]) + payload
    return body.ljust(20, b"\x00")


def get_feature(fd: int, dev: int, feat: int) -> int | None:
    resp = xfer(fd, long_msg(dev, 0x00, 0x00, bytes([(feat >> 8) & 0xFF, feat & 0xFF])))
    if not resp or len(resp) < 5 or resp[2] == 0xFF:
        return None
    return resp[4]


def step(direction: str) -> tuple[int, int]:
    nodes = hidpp_nodes()
    if not nodes:
        raise RuntimeError("no writable hid++ node")

    last_err: Exception | None = None
    for node in nodes:
        fd = os.open(node, os.O_RDWR)
        try:
            fl = fcntl.fcntl(fd, fcntl.F_GETFL)
            fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
            try:
                while True:
                    os.read(fd, 32)
            except BlockingIOError:
                pass

            for dev in (0x01, 0x02, 0x03, 0xFF):
                feat_idx = get_feature(fd, dev, BACKLIGHT2)
                if feat_idx is None:
                    continue
                info = xfer(fd, long_msg(dev, feat_idx, 0x00))
                if not info or len(info) < 16:
                    continue
                payload = info[4:]
                enabled, options, _supported, _effects, level, dho, dhi, dpow = struct.unpack(
                    "<BBBHBHHH", payload[:12]
                )
                rng = xfer(fd, long_msg(dev, feat_idx, 0x02))
                max_level = 3
                if rng and len(rng) > 4 and rng[4] > 1:
                    max_level = rng[4] - 1
                delta = 1 if direction == "inc" else -1
                new_level = max(0, min(max_level, int(level) + delta))
                # Manual mode (0x3) so level actually applies
                options = (options & 0x07) | (0x3 << 3)
                data = struct.pack("<BBBBHHH", 1 if enabled or new_level else enabled, options, 0xFF, new_level, dho, dhi, dpow)
                xfer(fd, long_msg(dev, feat_idx, 0x01, data))
                return new_level, max_level
        except OSError as exc:
            last_err = exc
        finally:
            os.close(fd)
    raise RuntimeError(str(last_err) if last_err else "backlight2 not found")


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in {"inc", "dec"}:
        print("usage: mx-kbd-backlight.py inc|dec", file=sys.stderr)
        return 2
    try:
        level, maximum = step(sys.argv[1])
    except RuntimeError as exc:
        print(f"err {exc}", file=sys.stderr)
        return 1
    print(f"ok {level} {maximum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
