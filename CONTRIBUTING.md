# Contributing

Contributions should preserve Architecture Studio’s governance, memory ownership, and portable file contracts.

Private firm and project skills belong in the user-owned studio workspace and do not require an upstream contribution. Use `/as:skill-maker` there. The process below is for general-purpose work proposed to the maintained public plugin.

## Add or change a skill

1. Fork the repository and create a focused branch.
2. Add or update the directory under `skills/`.
3. Keep `SKILL.md` authoritative for harness behavior and `README.md` focused on human-facing purpose, inputs, outputs, and examples.
4. Add the skill once to [`skills/README.md`](./skills/README.md).
5. Update shared rules or schemas only when behavior genuinely changes for multiple consumers.
6. Add focused contract coverage and run `./scripts/lint.sh` plus the relevant tests.
7. Open a pull request describing the behavior, verification, and representative output.

Read [PATTERNS.md](./PATTERNS.md) for naming, layout, dispatcher behavior, versioning, and lessons from prior defects.

Do not include client data, firm secrets, credentials, or proprietary procedures in a pull request. Catalog contributions use namespaced public commands such as `/as:site-history`; private workspace skills use their local `/{name}` command when discovered in that scope.

## Documentation ownership

- Root `README.md`: product, installation, first use, and architectural orientation
- `skills/README.md`: complete tooling catalog
- `docs/agents.md`: orchestration model and agent roster
- `rules/README.md`: governance conventions and enforcement strength
- `hooks/README.md`: lifecycle automation and configuration
- `schema/README.md`: shared data contracts
- `docs/`: cross-cutting product architecture and durable plans

Avoid copying authoritative instructions into multiple places. Link to the owning document instead.
