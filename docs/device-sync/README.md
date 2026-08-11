# Cross-device sync index

This folder is the **shared memory** between machines (and between Grok sessions on each).

## Why this exists

| Approach | Good for | Not good for |
|----------|----------|--------------|
| **Handoff log (this folder)** | Durable intent, summaries, “what the other machine should do next” | Real-time chat |
| **Git push/pull** | Shipping code/config | Explaining *why* without a note |
| **SSH between PCs** | Live debugging while both are on | Offline machines; history; multi-agent coordination |

**Recommendation: both, with roles**

1. **Always** write a short handoff before/after meaningful work, then push.
2. **Optional** SSH when both machines are on the same network and you need a live shell.

That avoids overlaps: the other side (human or Grok) reads `INDEX.md` + latest entry **before** editing the same area.

## Workflow (no weird overlaps)

```text
1. git pull / git-eod-pull          # get latest + handoffs
2. git-sync log                    # or open docs/device-sync/INDEX.md
3. Do work on THIS machine only in areas the handoff allows
4. git-sync handoff "summary…"     # log what you did + next steps
5. git-eod  (source)  or  git commit + push  (rare deploy exception)
```

### Roles

| Machine | Role | Usually |
|---------|------|---------|
| Main desktop | `source` | Author + `git-eod` push |
| Laptop | `deploy` | `git-eod-pull` only |

Exceptions (like building features on the laptop) are fine if you **handoff + push**, then main **pulls** and becomes source of truth again.

## Commands

```bash
git-sync handoff "What changed and what the other machine should do"
git-sync handoff -t to-source "Laptop → main: please pull and review"
git-sync handoff -t to-deploy "Main → laptop: pull hyprgruv, skip Wallpapers"
git-sync log                 # recent handoffs
git-sync log -n 3
git-sync brief               # INDEX + latest entry (great for Grok)
git-sync index               # rebuild INDEX.md only
```

## Layout

```text
docs/device-sync/
  README.md                 # this file
  INDEX.md                  # auto-generated table of recent handoffs
  LATEST.md                 # copy of the newest entry (easy for agents)
  entries/
    2026-08-11T…-HyprLab.md # one file per handoff (append-only → few conflicts)
```

## SSH (optional)

Only when both devices are reachable (LAN/Tailscale/etc.):

```bash
# On each machine once: ssh-keygen + ssh-copy-id user@other-host
ssh kirk@main-hostname
```

Do **not** rely on SSH as the log. If a machine is off, the handoff file still works after the next push/pull.

## Rules of thumb

1. **Pull before you push** (or pull before starting a second agent session).
2. **One writer per concern** until the next handoff (e.g. don’t both edit `git-eod` the same hour).
3. Prefer **handoff checklists** over long chat transcripts.
4. Device-local state stays out of git (`~/.local/state/hyprgruv/`). Shared intent goes here.
