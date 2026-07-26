# Hooks

Hooks are event-driven automations that run automatically during Claude Code sessions. Unlike skills (invoked manually) and rules (reference documents), hooks fire on lifecycle events — after a file is written or edited, before a commit, etc.

## Available Hooks

| Hook | Event | What it does |
|------|-------|-------------|
| [session-start-welcome](./session-start-welcome.sh) | First session after install | Displays a short `/as:studio` and `/as:learn` discovery notice, then records that it was emitted |
| [post-write-disclaimer-check](./post-write-disclaimer-check.sh) | After Write or Edit | Flags a regulatory output (zoning, occupancy, code analysis) that is missing the professional disclaimer |
| [pre-commit-spec-lint](./pre-commit-spec-lint.sh) | Before git commit | Scans staged markdown files for malformed CSI section numbers and blocks the commit until they're fixed |
| [version-check](./version-check.sh) | Enabled session startup, at most daily | Checks for a newer release and notifies once per version |

## Installation

None. The hooks ship with the Architecture Studio plugin (`as`) via [`hooks.json`](./hooks.json) and register automatically when the plugin is enabled:

```bash
claude plugin install as@skills-for-architects
```

Run `/hooks` in Claude Code to confirm they're loaded. Disable them by disabling the plugin, or per-session via `/hooks`.

> Versions ≤ 1.1.3 distributed these hooks as a `settings-snippet.json` requiring a manual merge into `~/.claude/settings.json`. If you did that merge, remove those entries — the plugin now registers the same hooks itself, and the old entries point at a path that no longer exists.

## Behavior

All four hooks surface their output so Claude actually receives it (stderr with exit 0 is shown to no one in Claude Code):

- **session-start-welcome** (SessionStart) emits a concise visible system message once, after checking required plugin sentinels. It says the built-in tools are ready, points to `/as:tool-catalog`, optional `/as:studio` setup, and `/as:learn`, and does not rewrite the user’s first response. It records the one-time marker only after output succeeds.
- **pre-commit-spec-lint** (PreToolUse) exits `2` on findings, which blocks the commit and feeds the stderr message back to Claude so it fixes the staged files before retrying.
- **post-write-disclaimer-check** (PostToolUse) emits JSON `{"decision": "block", "reason": …}` on stdout on findings, which surfaces the reason to Claude so it restores the disclaimer block.
- **version-check** (SessionStart) exits before any filesystem or network work unless the user explicitly enabled it through `/as:studio`. The first enabled session seeds a private local cache silently. Later sessions make at most one two-second request per 24 hours, fail silently, and notify once for each newer version. Disable it with `/as:studio updates disable`.

The deterministic preference helper lives with the owning `/as:studio` skill; it is not a hook.

To downgrade either hook to advisory-only, replace the `exit 2` / JSON emission with a plain `exit 0` at the finding point in the script (the finding then goes unseen).

### post-write-disclaimer-check

Checks written or edited `.md` files for the `<!-- architecture-studio:requires-disclaimer -->` marker that regulatory skills emit. If the marker is present but the canonical disclaimer block is missing (or the marker appears more than once), it emits a `block` decision telling Claude to restore the block from `rules/professional-disclaimer.md`. Marker-driven — silent on files without the marker. Edit provides no full content in its tool input, so the hook always reads the file from disk.

### pre-commit-spec-lint

Fires on any Bash command containing `git commit` as a standalone token — including compound forms like `git add -A && git commit -m …`, `git -C <dir> commit`, and `cd <dir> && git commit`. `git commitish` / `git commit-tree` do not trigger it; a quoted string containing `git commit` (e.g. `echo "git commit"`) is a known, harmless false positive — the lint just runs and passes.

Checks staged `.md` files for CSI section number formatting errors:

- Missing spaces: `092900` → should be `09 29 00`
- Dashed format: `09-29-00` → should be `09 29 00`
- Dotted format: `09.29.00` → should be `09 29 00`
- Missing section title: `09 29 00` → should be `09 29 00 — Gypsum Board`

## Customization

Each script is a standalone bash file, portable across macOS (BSD sed/grep) and Linux. Edit to fit your workflow:

- Downgrade enforcement to advisory: replace the `exit 2` / JSON `block` output with `exit 0`
- Adjust CSI lint patterns for your specification style
