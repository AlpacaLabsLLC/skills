# Architecture Studio Release

Repository-local maintainer workflow for auditing, preparing, publishing, verifying, and correcting Architecture Studio releases. It applies the canonical [release checklist](../../../docs/release-checklist.md), including role-specific contribution credit and immutable published tags.

## Usage

```text
$release audit v1.5.0
$release prepare v1.5.0
$release publish v1.5.0 after PR 17 is approved
$release correct the v1.5.0 contributor credit
```

This skill belongs to the Studio Operations practice cluster and is not installed as a public `/as:*` catalog skill.
