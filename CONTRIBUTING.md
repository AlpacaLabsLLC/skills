# Contributing

Contributions should preserve Architecture Studio’s governance, memory ownership, and portable file contracts.

Private firm and project skills belong in the user-owned studio workspace and do not require an upstream contribution. Use `$skill-maker` on Codex or `/as:skill-maker` on Claude Code. The process below is for general-purpose work proposed to the maintained public plugin.

## Local prerequisites

`./scripts/lint.sh` and the test suite degrade quietly when a tool is absent — checks are skipped with a notice rather than failing, and CI enforces them afterwards. Install these so a local run means what it says:

| Tool | Needed for | Without it |
|---|---|---|
| `python3` with `pyyaml` (`pip install pyyaml`) | SKILL.md frontmatter validation in `scripts/lint.sh`; `scripts/audit-skill-context.sh` | Frontmatter, JSON, count, and link checks skip; the audit script exits with an install hint |
| `jq` | JSON manifest checks | Manifest validation skips |
| `shellcheck` | Shell-script analysis | Skipped locally with a notice; CI enforces it |

A run that reports `all checks passed` with skip notices above it has not verified everything. Read the notices.

## Add or change a skill

1. Fork the repository and create a focused branch.
2. Add or update the directory under `skills/`.
3. Keep `SKILL.md` authoritative for harness behavior and `README.md` focused on human-facing purpose, inputs, outputs, and examples.
4. Add the skill once to [`skills/README.md`](./skills/README.md).
5. Update shared rules or schemas only when behavior genuinely changes for multiple consumers.
6. Add focused contract coverage and run `./scripts/lint.sh` plus the relevant tests.
7. Open a pull request describing the behavior, verification, and representative output.

A defect noticed but not fixed becomes an issue in the same session. Work turns up adjacent problems worth keeping — a latent bug, a contract two files disagree on, a rough edge in a script. Filing it takes a minute and is the only thing that carries the finding past the conversation that produced it.

Read [PATTERNS.md](./PATTERNS.md) for naming, layout, dispatcher behavior, versioning, and lessons from prior defects.

Do not include client data, firm secrets, credentials, or proprietary procedures in a pull request. Codex invokes catalog and private skills as `$name`; Claude Code uses namespaced catalog commands such as `/as:site-history` and local `/{name}` commands for private workspace skills.

## Documentation ownership

- Root `README.md`: product, installation, first use, and architectural orientation
- `skills/README.md`: complete tooling catalog
- `docs/agents.md`: orchestration model and agent roster
- `rules/README.md`: governance conventions and enforcement strength
- `hooks/README.md`: lifecycle automation and configuration
- `schema/README.md`: shared data contracts
- `docs/`: cross-cutting product architecture and durable plans

Avoid copying authoritative instructions into multiple places. Link to the owning document instead.
