---
name: release
description: Prepare, audit, publish, verify, or correct an Architecture Studio repository release. Use only when maintaining the skills-for-architects repository or its release pull requests; not for architectural deliverable issuance, deployments, transmittals, or ordinary feature pull requests.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Architecture Studio Repository Release

<!-- architecture-studio:harness-compatibility -->
> Invoke as `$release` on Codex or as the repository-local release command on Claude Code. Use equivalent native tools when host tool names differ.

This is a repository-local maintainer skill in the **Studio Operations** practice cluster. It is not part of the installed public Architecture Studio skill catalog.

The [release checklist](../../../docs/release-checklist.md) is the authoritative operational procedure. [PATTERNS.md rule 6](../../../PATTERNS.md#6-clear-versioning-behavior) remains authoritative for versioning invariants. Read both from the active repository before acting; never work from a remembered copy.

## Authority boundary

- Treat an ambiguous request such as “check the release” as a read-only audit.
- Preparing a release authorizes only the requested branch, documentation, version-surface, test, and pull-request work. It does not authorize merging, tagging, publishing, closing unrelated tracker items, rewriting history, rebasing, or force-pushing.
- Merge, tag, and GitHub release publication require explicit release authority. If the user has not already authorized those exact effects, present one gate immediately before publication naming the version, release pull request, target branch, verified commit, tag, and release title.
- Never move, delete, or recreate a published tag. Correct documentation or credit through the mutable GitHub release body and a reviewed changelog pull request; correct shipped behavior with a later release.
- Preserve unrelated work. Use an isolated branch or worktree when the primary checkout is dirty.

## Resolve the release

1. Resolve the repository root with Git and confirm that `.codex-plugin/plugin.json` or `.claude-plugin/plugin.json` identifies the `as` plugin. Stop if this is not the Architecture Studio repository.
2. Read applicable repository instructions, the release checklist, PATTERNS rule 6, the changelog, manifests, release-contract tests, and the owning durable release plan when one exists.
3. Inspect current local and remote truth: branch, upstream, worktree status, default branch, target release pull request, included and deferred issues and pull requests, CI, reviews, tags, and published releases. A plan's forecast is not current state.
4. Identify the requested mode:
   - **Audit:** inspect readiness and report evidence without changing state.
   - **Prepare:** update the candidate release and carry it through review-ready verification.
   - **Publish:** merge the approved release, tag the exact verified default-branch commit, and create the GitHub release.
   - **Verify:** inspect the already-published release and supported installation surfaces.
   - **Correct:** repair release notes or contribution credit without rewriting release history.
5. Record the version, semantic-version rationale, release owner, intended date, base and release branches, exact candidate commit, included scope, deferred scope, compatibility or migration boundary, and required verification. Mark unknown values as unresolved rather than guessing.

## Audit scope and contribution credit

1. Read the complete public history for every included issue and pull request, not only titles or opening descriptions.
2. Classify each reviewed tracker item as resolved here, related but still open, deferred, externally blocked, or superseded. Use closing references only for work fully resolved against the default branch.
3. Build a role-specific credit map for:
   - original issue reports;
   - independent reproductions or diagnoses;
   - confirmed workarounds;
   - implementation, test, or documentation authorship;
   - substantive review findings that changed the release.
4. Use linked public handles and evidence-supported roles. Do not infer private identity data, collapse distinct roles, or omit issue-only contributors because they have no commits.
5. Reconcile the same factual credits across the changelog, release pull request, and GitHub release body before publication.

## Prepare

1. Work only on the authorized release branch or an isolated child branch. Do not absorb adjacent pull requests merely because they are open or nearby.
2. Update every required version surface and changelog link identified by PATTERNS and repository search. Preserve intentional historical references.
3. Document compatibility, migrations, tracker disposition, contribution credits, representative behavior, verification, and rollback or correction boundaries.
4. Run `./scripts/lint.sh`, every `tests/test-*.sh` contract, and focused migration, install, rollback, or cross-host checks proportional to the release. Treat every local skip as partial evidence and require CI for the skipped capability.
5. Review the exact candidate diff and commit list, resolve actionable feedback, and require terminal green CI on the current head. A missing check rollup is not a pass; obtain equivalent clean-room evidence or report the gap.
6. Open or update the release pull request only when authorized. Stop at a verified, review-ready handoff unless publication was explicitly requested.

## Publish

1. Re-fetch remote truth immediately before the publication gate. Require an approved, mergeable release pull request, current base, terminal green CI on its current head, and no unresolved release blockers.
2. Present the single publication gate when the current request did not already authorize the exact effects. The preview must name the version, pull request, target branch, candidate commit, expected merge strategy, tag, release title, and audited credit summary.
3. Merge using the repository's normal strategy, then fetch the default branch and capture its exact merge commit. Verify the intended manifests, changelog, release behavior, and tag-critical checks on that commit.
4. Create and push the annotated `vX.Y.Z` tag at that exact verified commit. Never tag an unmerged feature head or predicted merge SHA.
5. Create the GitHub release from the audited notes. Confirm its title, body, tag target, publication state, and Latest designation where applicable.
6. Verify that the default branch, manifests, changelog, tag, and GitHub release all identify the same version and commit.

## Verify or correct

- Verify rendered notes, links, role-accurate credit, migration instructions, supported-host installation or update behavior, tracker closure, deferred work, and cached badges separately from their source values.
- For a factual or credit error, update the GitHub release body and prepare a reviewed changelog correction. For a behavioral artifact error, prepare a compatible patch or appropriately scoped later release.
- Record incomplete verification and follow-up work in the owning release plan or tracker; never describe partial evidence as complete.

## Handoff

Report:

- mode and target version;
- candidate or published commit and branch;
- included, deferred, and blocked tracker items;
- contribution-credit map;
- verification evidence and local skips;
- PR, CI, tag, and release links;
- remaining blockers and the next authorized action.

State explicitly when publication was not authorized or not performed.
