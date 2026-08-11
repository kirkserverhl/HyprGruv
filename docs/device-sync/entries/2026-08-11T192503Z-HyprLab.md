---
id: 2026-08-11T192503Z-HyprLab
date: 2026-08-11T15:25:03-04:00
date_utc: 2026-08-11T192503Z
host: HyprLab
role: deploy
direction: to-source
branch: main
git_head: 9c60a21cd
summary: Laptop (HyprLab) authored machine profiles + reciprocal git-sync + device-sync handoff index. Main should pull and become source of truth; laptop stays ROLE=deploy, FOLLOW=hyprgruv only.
---

# Laptop (HyprLab) authored machine profiles + reciprocal git-sync + device-sync handoff index. Main should pull and become source of truth; laptop stays ROLE=deploy, FOLLOW=hyprgruv only.

## Context

| Field | Value |
|-------|-------|
| Host | `HyprLab` |
| Role | `deploy` |
| Direction | `to-source` |
| Branch | `main` @ `9c60a21cd` |
| When | 2026-08-11T15:25:03-04:00 |

## For the other machine

- [ ] On main: git pull; git-sync brief; git-sync init source; enable git-eod-remind.timer; populate ~/Projects then git-sync follow as needed. Push may need SSH/credentials from laptop first if 9c60a21 not on origin yet.

## Notes

_(optional — edit this entry before commit if needed)_

## Avoid overlaps

- Pull this handoff before editing the same areas on the other device.
- Device-local state stays in `~/.local/state/hyprgruv/` — do not commit it.
