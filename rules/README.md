# Rules

Rules are cross-cutting conventions that shape every skill output across the whole Architecture Studio plugin (`as`). Unlike skills (invoked with a slash command), rules are never invoked — and they are NOT auto-loaded: each skill, agent, or hook that needs a rule references its file explicitly (see [How Rules Work](#how-rules-work--honestly) below). This directory ships inside the plugin as its internal reference docs.

| Rule | What it governs |
|------|-----------------|
| [units-and-measurements](./units-and-measurements.md) | Imperial/metric defaults, area types (GSF/USF/RSF), dimension formatting |
| [code-citations](./code-citations.md) | Building code references — edition years, section symbols, jurisdiction awareness |
| [professional-disclaimer](./professional-disclaimer.md) | Disclaimer language, what AI outputs can and cannot claim |
| [csi-formatting](./csi-formatting.md) | Limited MasterFormat 2020 compatibility baseline, edition-neutral three-part organization, cross-references |
| [terminology](./terminology.md) | Style and first-use conventions; linked architecture-knowledge corpus for factual orientation |
| [output-formatting](./output-formatting.md) | Tables, headings, source attribution, file naming, list structure |
| [transparency](./transparency.md) | Show your work — link sources, expose inputs, make outputs verifiable |

## How Rules Work — honestly

Claude Code has no mechanism that auto-loads a `rules/` directory, so these bind at two different strengths:

- **Hook-enforced (2):** `professional-disclaimer` and `csi-formatting` are checked mechanically by the hooks that ship with the plugin in root `hooks/` (`post-write-disclaimer-check`, `pre-commit-spec-lint`). The disclaimer check is marker-driven — skills emit `<!-- architecture-studio:requires-disclaimer -->` and the hook verifies the canonical block.
- **Advisory (5):** the other five are conventions written into the skills and agents that need them — the skill bodies carry the relevant rules inline, and these files are the canonical reference they're kept consistent with. Nothing enforces them at runtime.

If a rule matters enough to your practice to enforce, the pattern is in the two hook-enforced rules: have skills emit a marker, check the marker in a hook. Rules are not invoked directly.
