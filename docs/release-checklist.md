# Architecture Studio Release Checklist

The versioning policy in [PATTERNS.md rule 6](../PATTERNS.md#6-clear-versioning-behavior) is authoritative. This checklist operationalizes that policy for maintainers and release agents. Use it for every published Architecture Studio version; copy the applicable checks into the release plan or release pull request when a durable run record is needed.

Publishing is a state-changing operation. Do not merge, tag, publish, close issues, or edit a public release without explicit authority for the release and its scope.

## Release record

- [ ] Record the target version, semantic-version rationale, release owner, intended publication date, base branch, and release branch.
- [ ] Name every included issue and pull request, plus every explicitly deferred or excluded item reviewed during preparation.
- [ ] State whether the release is compatible, breaking, or migration-bearing and identify the user action required after installation.
- [ ] Identify the exact verification expected before merge and the post-release evidence that will prove publication succeeded.
- [ ] Work from a clean, isolated branch or worktree when the primary checkout contains unrelated changes.

## Scope and tracker disposition

- [ ] Refresh the target branch and tracker state before finalizing scope; do not rely on a plan's forecasted branch, date, or issue status.
- [ ] Confirm that every included change belongs in this version and that unrelated reviewed work is not being pulled in by proximity.
- [ ] Classify each reviewed tracker item as resolved here, related but still open, deferred, externally blocked, or superseded.
- [ ] Use a closing reference such as `Fixes #123` only when the release pull request fully resolves that issue against the default branch. Use `Related: #123` for partial, follow-up, or contextual work.
- [ ] Leave unfinished issues and pull requests open. A review, comment, rebase need, or release boundary is not completion.
- [ ] Record any dependent pull request that must be rebased or refreshed after this release lands.

## Contribution-credit audit

- [ ] Inspect the complete public history of every included issue and pull request before drafting the changelog or release notes.
- [ ] Map contribution roles separately, including the original issue author, anyone who supplied an independent reproduction or diagnosis, anyone who confirmed a workaround, implementation authors, documentation or test authors, and reviewers whose substantive finding changed the release.
- [ ] Credit each person for the role the evidence supports. Do not collapse “report,” “diagnosis,” “workaround,” and “implementation” into one attribution when different people performed them.
- [ ] Use linked GitHub handles by default and preserve any clearly stated public credit preference. Do not publish private names, email addresses, client information, or other non-public identity data.
- [ ] Recognize issue-only contributors explicitly. GitHub's repository contributor list is commit-based and may not display the people who reported, reproduced, or diagnosed the problem.
- [ ] Keep credit wording factual and proportionate. Routine maintainer administration does not require a release credit; a substantive report, reproduction, diagnosis, workaround, implementation, or review does.
- [ ] Put the same role-accurate acknowledgements in the versioned changelog and the GitHub release body. Re-read both surfaces before publication.
- [ ] When one person performed several roles, combine them clearly. When roles were split, name the split explicitly, for example: “Thanks to `@reporter` for the original report and `@investigator` for extending the diagnosis and confirming the workaround.”
- [ ] If attribution is genuinely ambiguous, pause publication and ask rather than guessing or omitting a likely contributor.

## Versioned release surfaces

- [ ] Update `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, and `.claude-plugin/marketplace.json` according to the versioning policy; cross-harness releases keep all three versions equal.
- [ ] Add the version heading and actual publication date to `CHANGELOG.md`, update the `[Unreleased]` comparison target, and add the version link.
- [ ] Ensure the changelog describes the shipped behavior, compatibility or migration boundary, issue relationships, and audited contribution credit.
- [ ] Update every hardcoded version and user-facing release surface identified by repository search, including `README.md`, `docs/firm-deployment.md`, release-contract tests, integration pins, component counts, and migration instructions where applicable.
- [ ] Draft the GitHub release title and body from the final changelog, then edit for clarity without changing scope, compatibility claims, or contribution credit.
- [ ] Search for the previous version and forecasted dates before committing. Explain any intentional historical references rather than replacing them mechanically.

## Pre-merge verification

- [ ] Confirm the release branch contains the current target base or document the exact rebase/update still required.
- [ ] Review the final three-dot diff and commit list. Verify that every changed file belongs to the release and no user-owned or unrelated files were captured.
- [ ] Run `./scripts/lint.sh` and every `tests/test-*.sh` contract on the exact candidate commit.
- [ ] Read local skip notices. Missing `pyyaml`, `jq`, or `shellcheck` means local success is partial; require CI to exercise the skipped checks.
- [ ] Run focused smoke, install, migration, rollback, or cross-host checks required by the release's behavior and risk.
- [ ] For a breaking migration, verify both forward migration and recovery from a deliberate failure before publication.
- [ ] Ensure the release pull request describes behavior, verification, representative output, included and deferred tracker items, and the final contribution credits.
- [ ] Resolve actionable review feedback and require terminal green CI on the current head. Recheck mergeability after the final change.

## Merge and publication

- [ ] Merge the approved release pull request using the repository's normal strategy and capture the exact default-branch merge commit.
- [ ] Fetch the default branch, verify the merge commit contains the intended versions, changelog, checklist results, and release behavior, and rerun any tag-critical check against that commit.
- [ ] Create the annotated `vX.Y.Z` tag at that exact verified commit. Never tag an unmerged feature-branch head or a predicted merge SHA.
- [ ] Push the tag and create the GitHub release from the audited notes. Confirm the title, body, tag target, publication state, and “Latest” designation where applicable.
- [ ] Verify the remote tag commit, GitHub release tag, default-branch release commit, manifest versions, and changelog version all agree.
- [ ] Do not begin an unrelated release or merge deferred scope while publication verification is still open.

## Post-release verification

- [ ] Open the public release URL and inspect the rendered title, notes, links, contribution credits, and migration instructions.
- [ ] Verify installation or update behavior from the published version on every supported host affected by the release.
- [ ] Confirm that only issues fully resolved by the merged change closed automatically. Add a concise release link where it materially helps the issue record.
- [ ] Recheck deferred pull requests and issues. Update stale expectations and note required rebases without closing unfinished work.
- [ ] Inspect README badges and other cached surfaces separately from their source configuration; a cache delay is not a version-source mismatch.
- [ ] Re-run the contribution-credit audit against the published changelog and GitHub release body.
- [ ] Record deviations, partial verification, external blockers, or follow-up work in the owning release plan or tracker item.

## Corrections after publication

- [ ] Stop and correct any error discovered before publication rather than carrying it into the release for convenience.
- [ ] For a factual or contribution-credit error found afterward, update the mutable GitHub release body and correct the changelog on the default branch through a reviewed pull request.
- [ ] Do not move, delete, or recreate a published tag to repair documentation or attribution. The tag remains the immutable historical release commit.
- [ ] If the tagged installed artifacts are behaviorally wrong, prepare a new compatible patch or an appropriately scoped later release instead of rewriting the published version.
- [ ] Verify every correction publicly and link the correcting pull request from the relevant issue or release when it improves traceability.

## Release sign-off

The release is complete only when all applicable checks above have evidence and these final statements are true:

- [ ] Scope, tracker disposition, and deferred work are accurate.
- [ ] Contribution credits are complete, public, and role-accurate.
- [ ] Tests, review, and migration or compatibility checks match the release risk.
- [ ] Default branch, manifests, changelog, tag, and GitHub release identify the same version and commit.
- [ ] Post-release installation and public-surface verification are complete or their blockers are explicitly recorded.
