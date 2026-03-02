# Skills

Claude Code skills for AEC and workplace strategy by [ALPA](https://alpa.llc).

## Available Skills

| Skill | Description |
|-------|-------------|
| [workplace-programmer](./workplace-programmer) | AI workplace strategy consultant that builds office space programs through conversation |

## Installation

Copy or symlink any skill directory into your Claude Code skills folder:

```bash
# Clone the repo
git clone https://github.com/AlpacaLabsLLC/skills.git

# Symlink a skill (recommended — stays in sync with updates)
ln -s "$(pwd)/skills/workplace-programmer" ~/.claude/skills/workplace-programmer

# Or copy it
cp -r skills/workplace-programmer ~/.claude/skills/workplace-programmer
```

Then use it in Claude Code:

```
/workplace-programmer 30,000 RSF tech company, 200 people
```

## Customization

Each skill has a `data/` directory with JSON files you can edit to change the domain knowledge. For workplace-programmer:

- `data/archetypes.json` — benchmark office profiles (dense open, traditional, legal, etc.)
- `data/space-types.json` — room and desk catalog with default SF and capacity
- `data/findings.json` — research findings from JLL, Gensler, VergeSense, and others

Edit the `SKILL.md` itself to change the persona, conversation flow, or domain expertise.

## License

MIT
