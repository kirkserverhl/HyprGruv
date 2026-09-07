#!/usr/bin/env python3
"""MPK mini play pad helper — smoke-test, live dump, and action listener.

Pads are MIDI channel 10 (aseqdump Ch 9). Piano keys are channel 1 (Ch 0)
and are ignored so a fidget on the keybed cannot flip the desk.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

DEVICE_SUBSTR = "MPK mini play"
PAD_CH = 9  # aseqdump 0-based; MIDI channel 10
MAP_PATH = Path.home() / ".config" / "settings" / "mpk-pads.json"
SCRIPTS = Path.home() / ".config" / "hyprgruv" / "scripts"

# Akai numbering: bottom row 1–4 left→right, top row 5–8 left→right.
PAD_ORDER = ["A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8"]

# Factory-ish sequential GM-adjacent defaults. Smoke test overwrites these.
FACTORY_NOTES = {
    "A1": 36,
    "A2": 37,
    "A3": 38,
    "A4": 39,
    "A5": 40,
    "A6": 41,
    "A7": 42,
    "A8": 43,
    "B1": 44,
    "B2": 45,
    "B3": 46,
    "B4": 47,
    "B5": 48,
    "B6": 49,
    "B7": 50,
    "B8": 51,
}

FACTORY_ACTIONS = {
    "A1": "call",
    "A2": "end",
}

NOTE_ON = re.compile(r"Note on\s+(\d+),\s+note\s+(\d+),\s+velocity\s+(\d+)")
NOTE_OFF = re.compile(r"Note off\s+(\d+),\s+note\s+(\d+)")
CC = re.compile(r"Control change\s+(\d+),\s+controller\s+(\d+),\s+value\s+(\d+)")
PROG = re.compile(r"Program change\s+(\d+),\s+program\s+(\d+)")


def notify(title: str, body: str, urgency: str = "low") -> None:
    subprocess.Popen(
        ["notify-send", "-e", "-u", urgency, title, body],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def load_map() -> dict:
    data = {
        "device": DEVICE_SUBSTR,
        "learned": False,
        "pad_channel": PAD_CH,
        "pads": {
            name: {
                "note": FACTORY_NOTES[name],
                "ch": PAD_CH,
                "action": FACTORY_ACTIONS.get(name, "none"),
            }
            for name in PAD_ORDER
        },
    }
    if MAP_PATH.is_file():
        try:
            saved = json.loads(MAP_PATH.read_text())
            data["learned"] = bool(saved.get("learned", False))
            for name, pad in (saved.get("pads") or {}).items():
                if name in data["pads"] and isinstance(pad, dict):
                    data["pads"][name].update(pad)
        except (OSError, json.JSONDecodeError) as exc:
            print(f"warning: ignoring bad map {MAP_PATH}: {exc}", file=sys.stderr)
    return data


def save_map(data: dict) -> None:
    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAP_PATH.write_text(json.dumps(data, indent=2) + "\n")
    print(f"wrote {MAP_PATH}")


def note_lookup(data: dict) -> dict[tuple[int, int], str]:
    out = {}
    for name, pad in data["pads"].items():
        out[(int(pad["ch"]), int(pad["note"]))] = name
    return out


def find_aseq_port() -> str | None:
    try:
        listing = subprocess.check_output(["aconnect", "-l"], text=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    client = None
    for line in listing.splitlines():
        m = re.match(r"client (\d+):\s+'([^']+)'", line)
        if m:
            client = m.group(1) if DEVICE_SUBSTR.lower() in m.group(2).lower() else None
        elif client and "MIDI" in line:
            port_m = re.match(r"\s+(\d+)\s+", line)
            if port_m:
                return f"{client}:{port_m.group(1)}"
    return client


def find_amidi_port() -> str | None:
    try:
        listing = subprocess.check_output(["amidi", "-l"], text=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    for line in listing.splitlines():
        if DEVICE_SUBSTR.lower() in line.lower():
            parts = line.split()
            for part in parts:
                if part.startswith("hw:"):
                    return part
    return None


def light_pad(note: int, on: bool, ch: int = PAD_CH) -> None:
    port = find_amidi_port()
    if not port:
        return
    status = 0x90 + ch
    vel = 0x7F if on else 0x00
    payload = f"{status:02X} {note:02X} {vel:02X}"
    subprocess.run(["amidi", "-p", port, "-S", payload], check=False, capture_output=True)


def aseqdump_proc():
    port = find_aseq_port() or DEVICE_SUBSTR
    cmd = ["aseqdump", "-p", str(port)]
    # aseqdump block-buffers on a pipe, so Python never sees pad hits.
    if shutil.which("stdbuf"):
        cmd = ["stdbuf", "-oL", "-eL"] + cmd
    return subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )


def parse_line(line: str) -> dict | None:
    m = NOTE_ON.search(line)
    if m:
        vel = int(m.group(3))
        kind = "on" if vel > 0 else "off"
        return {"type": kind, "ch": int(m.group(1)), "note": int(m.group(2)), "vel": vel}
    m = NOTE_OFF.search(line)
    if m:
        return {"type": "off", "ch": int(m.group(1)), "note": int(m.group(2)), "vel": 0}
    m = CC.search(line)
    if m:
        return {"type": "cc", "ch": int(m.group(1)), "cc": int(m.group(2)), "val": int(m.group(3))}
    m = PROG.search(line)
    if m:
        return {"type": "pc", "ch": int(m.group(1)), "program": int(m.group(2))}
    return None


def wait_pad_note(proc, timeout: float = 45.0) -> dict | None:
    """Accept the next Note On on any channel. Print every MIDI event so a
    hang is obvious (CC mode, piano keys, buffering, etc.)."""
    deadline = time.time() + timeout
    assert proc.stdout is not None
    cc_hint = False
    pc_hint = False
    while time.time() < deadline:
        if proc.poll() is not None:
            print("  aseqdump exited — is the MPK still plugged in?", flush=True)
            return None
        line = proc.stdout.readline()
        if not line:
            continue
        ev = parse_line(line)
        if not ev:
            continue
        if ev["type"] == "on":
            print(f"  got note {ev['note']}  ch {ev['ch']}  vel {ev['vel']}", flush=True)
            return ev
        if ev["type"] == "cc":
            print(f"  got CC {ev['cc']}={ev['val']}  ch {ev['ch']}", flush=True)
            if not cc_hint:
                print("  (pads sending CC — press the CC button until that LED is off)", flush=True)
                cc_hint = True
        elif ev["type"] == "pc":
            print(f"  got Program Change {ev['program']}  ch {ev['ch']}", flush=True)
            if not pc_hint:
                print("  (pads in Prog Change mode — turn that LED off so pads send notes)", flush=True)
                pc_hint = True
    return None


def cmd_status() -> int:
    data = load_map()
    aseq = find_aseq_port()
    amidi = find_amidi_port()
    print(f"device:     {DEVICE_SUBSTR}")
    print(f"aseq port:  {aseq or 'NOT FOUND'}")
    print(f"amidi port: {amidi or 'NOT FOUND'}")
    print(f"map:        {MAP_PATH}  learned={data['learned']}")
    print()
    print("  pad  note  ch  action")
    for name in PAD_ORDER:
        pad = data["pads"][name]
        print(f"  {name:<3}  {pad['note']:<4}  {pad['ch']:<2}  {pad['action']}")
    print()
    print("Bank A/B on the hardware is red/blue. We tell banks apart by note numbers,")
    print("not by driving that LED — leave Bank A (red) for CALL/END.")
    return 0 if aseq else 1


def cmd_dump() -> int:
    data = load_map()
    lookup = note_lookup(data)
    print("Live dump — hit pads. Keys/knobs are shown but ignored for actions. Ctrl+C to stop.")
    proc = aseqdump_proc()
    assert proc.stdout is not None
    try:
        for line in proc.stdout:
            ev = parse_line(line)
            if not ev:
                continue
            if ev["type"] in {"on", "off"}:
                name = lookup.get((ev["ch"], ev["note"]), "")
                tag = name or ("pad?" if ev["ch"] == PAD_CH else "key")
                print(f"{ev['type']:3}  ch={ev['ch']} note={ev['note']:<3}  {tag}", flush=True)
            elif ev["type"] == "cc":
                print(f"cc   ch={ev['ch']} cc={ev['cc']:<3} val={ev['val']}")
    except KeyboardInterrupt:
        print()
    finally:
        proc.send_signal(signal.SIGINT)
        proc.wait(timeout=2)
    return 0


def cmd_smoke() -> int:
    if not find_aseq_port():
        print("MPK mini play not found. Plug it in (USB) and rerun.")
        return 1
    print(
        """
MPK pad smoke test
------------------
1. Turn Internal Sounds OFF on the MPK (USB MIDI only — pads should be silent).
2. Bank A/B button: RED = Bank A. Start there.
3. Pad 1 is BOTTOM LEFT (not the right one). Hit pads in this order,
   one at a time:

     [5] [6] [7] [8]     top
     [1] [2] [3] [4]     bottom   ← start at 1, far left

   Bank A 1–8, then switch to Bank B (BLUE) and hit 1–8 the same way.
   You should see "got note …" immediately. If you see CC instead, the
   CC button on the MPK is on — turn it off.

A1 will become CALL, A2 END CALL. Everything else is logged only.
Ctrl+C aborts without saving.
"""
    )
    proc = aseqdump_proc()
    data = load_map()
    seen: dict[tuple[int, int], str] = {}
    try:
        for name in PAD_ORDER:
            bank = "A (RED)" if name.startswith("A") else "B (BLUE)"
            print(f"Hit pad {name[1]} on Bank {bank} ...", flush=True)
            ev = wait_pad_note(proc, timeout=45)
            if not ev:
                print("timed out waiting for a pad")
                return 1
            key = (ev["ch"], ev["note"])
            if key in seen:
                print(f"  that note is already {seen[key]} — hit a different pad")
                # keep asking this slot
                while key in seen:
                    ev = wait_pad_note(proc, timeout=45)
                    if not ev:
                        print("timed out")
                        return 1
                    key = (ev["ch"], ev["note"])
            seen[key] = name
            data["pads"][name]["note"] = ev["note"]
            data["pads"][name]["ch"] = ev["ch"]
            data["pads"][name]["action"] = FACTORY_ACTIONS.get(name, "none")
            print(f"  {name}  note {ev['note']}  vel {ev['vel']}")
            light_pad(ev["note"], True, ev["ch"])
            time.sleep(0.15)
            light_pad(ev["note"], False, ev["ch"])
        data["learned"] = True
        save_map(data)
        notify("MPK smoke", "Pad map saved. A1=CALL  A2=END")
        print("\nSaved. Start the listener with:  mpk-listen.sh")
        print("Keyboard fallback: Super+Alt+C  /  Super+Alt+Shift+C")
        return 0
    except KeyboardInterrupt:
        print("\naborted — map not saved")
        return 130
    finally:
        proc.send_signal(signal.SIGINT)
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()


def run_action(action: str, pad: str) -> None:
    script = SCRIPTS / "call-mode.sh"
    if action == "call":
        subprocess.Popen(["bash", str(script), "call"])
    elif action == "end":
        subprocess.Popen(["bash", str(script), "end"])
    elif action == "toggle":
        subprocess.Popen(["bash", str(script), "toggle"])
    elif action != "none":
        print(f"unknown action {action} from {pad}", file=sys.stderr)


def cmd_listen() -> int:
    data = load_map()
    lookup = note_lookup(data)
    last_fire: dict[str, float] = {}
    debounce = 0.35
    print(f"mpk-listen: waiting on {DEVICE_SUBSTR}  map learned={data['learned']}", flush=True)
    while True:
        if not find_aseq_port():
            time.sleep(2)
            continue
        proc = aseqdump_proc()
        assert proc.stdout is not None
        try:
            for line in proc.stdout:
                ev = parse_line(line)
                if not ev or ev["type"] != "on":
                    continue
                name = lookup.get((ev["ch"], ev["note"]))
                if not name:
                    for (ch, note), n in lookup.items():
                        if note == ev["note"]:
                            name = n
                            break
                if not name:
                    continue
                now = time.time()
                if now - last_fire.get(name, 0) < debounce:
                    continue
                last_fire[name] = now
                action = data["pads"][name].get("action", "none")
                print(f"{name} note={ev['note']} action={action}", flush=True)
                if action == "none":
                    continue
                if action == "call":
                    light_pad(ev["note"], True, ev["ch"])
                elif action == "end":
                    # turn off whatever we lit for CALL (A1)
                    call_note = int(data["pads"]["A1"]["note"])
                    light_pad(call_note, False, int(data["pads"]["A1"]["ch"]))
                run_action(action, name)
        except KeyboardInterrupt:
            return 0
        finally:
            if proc.poll() is None:
                proc.send_signal(signal.SIGINT)
                try:
                    proc.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    proc.kill()
        time.sleep(1)


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd in {"status", "map"}:
        return cmd_status()
    if cmd == "dump":
        return cmd_dump()
    if cmd in {"smoke", "learn"}:
        return cmd_smoke()
    if cmd == "listen":
        return cmd_listen()
    print(f"usage: {sys.argv[0]} status|dump|smoke|listen", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
