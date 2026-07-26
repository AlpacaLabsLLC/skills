# Data governance

Architecture Studio is local-first: its durable records are files in the user-selected studio workspace, not an ALPA-hosted account or database.

## Storage boundary

- Architecture Studio does not upload or store studio or project records with ALPA.
- The user chooses the local, network, or synchronized folder containing the studio.
- If that folder is managed by a third-party sync provider, the provider’s storage and sharing terms apply.
- Prompts and files sent to the configured LLM are governed by that provider account and its data terms.
- A future cloud-hosted Architecture Studio service could require an account, but this local version does not.

## Network behavior

Research skills contact the public sources named in their documentation only when the user runs them.

Background update checking is disabled by default. If enabled explicitly through `/as:studio`, it makes at most one bare request per 24 hours to `version.alpa.llc`, sends no project content or Architecture Studio identifier, fails silently, and notifies once per newer version. Cloudflare still processes ordinary request metadata such as IP address, request headers, and timestamps.

`/as:studio-feedback` prepares report fields locally. It never files an issue automatically. Opening the reviewed, prefilled GitHub URL transmits the displayed query parameters immediately to GitHub.

## Connectors

The studio owns one `.mcp.json` boundary. New studios begin with:

```json
{
  "mcpServers": {}
}
```

Architecture Studio does not bundle connector credentials, select providers, configure OAuth, or create connector manifests inside projects. Users and firms remain responsible for provider selection, authentication, access control, and workspace-sharing policy.

## Consent

Material file changes, record promotion, feedback transmission, and connector configuration require a visible preview and one confirmation gate. Skills should not ask for natural-language confirmation immediately before presenting the harness’s own confirmation gate; that creates duplicate consent prompts without adding protection.
