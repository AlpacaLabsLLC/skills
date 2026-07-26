# Firm deployment guide

Architecture Studio v1.4 is a local-first, one-writer pilot framework, not a hosted governance platform. A firm should assign a technology owner before distributing it and keep its studio workspace in firm-controlled storage.

## Pilot ownership

- Name an owner who approves private studio skills, plugin updates, shared rules, and rollback decisions.
- Test updates in a non-production studio before changing the firm-wide installation.
- Keep firm skills in private source control when they encode confidential procedures. Contribute upstream only after removing client, project, credential, and proprietary content.
- Document the supported Claude surface, Claude Code version, operating systems, and local dependencies used by the pilot. Repository tests do not establish parity for every Claude surface or operating system.

## Records and collaboration

- Treat `STUDIO.md`, each `PROJECT.md`, and canonical task or time registers as one-writer records. Do not have two Claude sessions edit the same canonical record concurrently.
- Network and synchronized folders inherit their provider's conflict, sharing, retention, and recovery behavior. Architecture Studio does not provide locking or conflict resolution.
- Back up the studio before structural changes. Recovery means restoring user-owned files through the firm's backup or source-control process; plugin reinstall does not restore records.
- Restrict filesystem access to the people and systems authorized for the underlying projects.

## Data, secrets, and incidents

- Apply the firm's Anthropic account, retention, and administrator controls to prompts and files. See [data governance](./data-governance.md).
- Keep credentials out of Markdown, CSV, skill bodies, and source control. Connector authentication is administered separately; the empty studio `.mcp.json` does not configure a provider.
- Define retention and deletion rules for studio records, generated outputs, logs, and backups before the pilot.
- For accidental disclosure, compromised credentials, or incorrect regulated output, stop the affected workflow, preserve relevant local evidence, rotate credentials where applicable, and follow the firm's incident and professional-review procedures. ALPA does not receive or administer the firm's project records.

## Distribution, rollback, and support

Distribute the public plugin through the documented marketplace installation. Distribute private firm skills through firm-controlled source control or deployment tooling into the studio's `.claude/skills/` directory. Pin and record the tested plugin version. To roll back, reinstall the previously approved plugin version and restore user-owned records only from a reviewed backup; never replace a studio workspace with plugin files.

Architecture Studio issues belong in `/as:studio-feedback` after the outbound fields are reviewed. Claude account, billing, model, and retention questions belong with Anthropic or the firm's Claude administrator. Storage, sync, access, and backup incidents belong with the firm's provider and internal owners.
