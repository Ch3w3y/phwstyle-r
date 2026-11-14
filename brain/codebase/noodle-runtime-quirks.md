# Noodle runtime quirks (v0.1.5)

- **The scheduler holds a slot.** Noodle keeps the schedule session alive after its turn ends, and `atMaxConcurrency` counts it as active. With `max_concurrency = 1`, no worker stage ever starts and orders sit pending. Keep `max_concurrency = 2`.
- **Usage-limit stalls look like hangs.** A session that hits the Claude usage limit exits at once, but Noodle does not advance. Check the session's `meta.json` for "hit your" before you debug anything else.
- **`fsnotify: queue or buffer overflow`** kills `noodle start` after about 25 minutes of a stalled loop. Restart it; the loop resets stale active stages on startup.
- Session transcripts live in `.noodle/sessions/<session>/canonical.ndjson`. Run `tail -f` on one to watch an agent.
