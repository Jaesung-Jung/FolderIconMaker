---
name: gh-pr
description: Draft repository-compliant GitHub pull requests with the `gh` CLI. Use when Codex needs to inspect the current repository's PR template and lint rules, derive a PR from local changes, find related issues or precedent PRs, and create or update a PR with labels discovered from GitHub.
---

# GitHub PR

Draft or create pull requests by treating the current repository as the source of truth.
Use local git state for scope, `.github/` files for template and lint requirements, and the `gh` CLI for live GitHub metadata and label changes.
Prefer `gh` over connector tools for this skill.

## Discover repository context

Start by identifying the active repository and branch instead of hardcoding them.

Prefer commands such as:

```zsh
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
default_branch="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
branch="$(git branch --show-current)"
git status --short
git diff --stat
git log --oneline --decorate --max-count 10
```

Use the current branch, changed files, and recent commits to understand what the PR actually covers.

## Read the source of truth

Before drafting or revising a PR, inspect the repository files and live GitHub metadata that define the rules:

- PR template files under `.github/`, such as `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/*`
- PR validation workflows under `.github/workflows/`
- Live label list from GitHub
- Relevant issues and prior PRs when they help with wording, scope, or linking conventions

Prefer discovery commands such as:

```zsh
rg --files .github | rg 'pull_request_template|PULL_REQUEST_TEMPLATE'
rg --files .github/workflows | rg 'pr|pull'
gh label list --repo "$repo" --limit 200
gh issue list --repo "$repo" --state open --limit 30
gh pr list --repo "$repo" --state closed --limit 20
```

If a workflow enforces a PR title pattern or required body sections, follow that rule exactly.
If multiple templates exist, choose the one that best matches the request and current diff.

## Resolve the PR scope from local changes

Use the local diff to determine the real change set.

- Inspect changed files before writing the summary.
- Derive the topic from the branch name, touched modules, tests, and the user request.
- Keep the PR scoped to the actual diff instead of stretching it to loosely related work.
- Call out missing tests, deferred work, or partial implementations plainly.

## Find related issues before finalizing the body

Do not finalize the PR body until you have checked whether a related issue exists.

Recommended workflow:

1. Extract keywords from the branch name, feature name, module names, and changed files.
2. Search open issues first.
3. If nothing matches well, search all issues including closed ones.
4. Choose the issue with the strongest overlap in intent, affected area, and completion criteria.
5. If no issue exists, say so explicitly. Recommend creating one only when that would materially improve traceability or repository workflow compliance.

Prefer commands such as:

```zsh
gh issue list --repo "$repo" --state open --search "<keywords>" --limit 20
gh issue list --repo "$repo" --state all --search "<keywords>" --limit 20
gh issue view <number> --repo "$repo"
```

When multiple issues are plausible, keep the top candidates, explain the ambiguity briefly, and avoid linking a weak match just to satisfy a template.

## Reuse precedent PRs when useful

Search prior closed or merged PRs when they can improve:

- title wording
- body structure
- issue-linking conventions
- test reporting style
- rollback or risk framing

Prefer commands such as:

```zsh
gh pr list --repo "$repo" --state closed --search "<keywords>" --limit 20
gh pr view <number> --repo "$repo" --json title,body,labels,closingIssuesReferences
```

Use precedent only when it materially improves the current draft.

## Query and apply labels from GitHub

Always query live labels with `gh` before recommending or applying labels.
Do not rely on stale assumptions, repository memory, or examples from this skill.

Required step:

```zsh
gh label list --repo "$repo" --limit 200
```

Label selection rules:

- Match against the repository's live labels, not generic names in your head.
- Normalize label names for matching if needed, but apply the exact live label text.
- Prefer one work-type label when the repository has them.
- Add a priority or severity label only when the repository has one and the request provides enough signal.
- Common work-type patterns to look for include labels for feature, enhancement, bug, bugfix, fix, task, refactor, docs, documentation, test, chore, ci, dependencies, performance, and security.
- Common urgency patterns include `P0` to `P3`, `priority:*`, `severity:*`, `critical`, `high`, `medium`, and `low`.
- If the repository does not have a fitting label, omit it instead of inventing one.
- If the user explicitly asks for additional labels and those labels exist, include them.

When editing an existing PR, inspect current labels first and add only the missing ones unless the user asked you to replace labels.

Prefer commands such as:

```zsh
gh pr view <number> --repo "$repo" --json labels
gh pr edit <number> --repo "$repo" --add-label "<label>"
```

## Enforce repository rules

Follow the repository's actual rules, not this skill's examples.

- Use the title format enforced by the repository workflows or established merged-PR pattern.
- Use the body headings and checklist structure from the selected PR template.
- Preserve the repository's language conventions for titles and body text.
- Keep technical identifiers such as library names, API names, error codes, file paths, and commands in their original form when that improves clarity.
- Keep test claims and rollout claims truthful.
- If the repository expects linked issues in a specific format such as `Refs`, `Closes`, or `Fixes`, follow the observed convention from templates, lint rules, or recent merged PRs.

## Drafting workflow

1. Discover the current repo, default branch, branch name, and local diff.
2. Read the applicable PR template and any PR lint workflow that constrains title or body format.
3. Determine the PR type and scope from the actual changes.
4. Search for the strongest related issue.
5. Search prior PRs if they would improve the draft.
6. Query live labels with `gh label list`.
7. Draft the title and body in the repository's required format and language.
8. Recommend labels using only labels confirmed to exist in GitHub.
9. If the user asked to create the PR, push the branch first if needed and create the PR with labels.
10. If the PR already exists, update the title, body, and any missing labels.

Prefer commands such as:

```zsh
git push -u origin "$branch"
gh pr create --repo "$repo" --base "$default_branch" --head "$branch" --title "<title>" --body-file <file> --label "<label>"
gh pr edit <number> --repo "$repo" --title "<title>" --body-file <file>
gh pr edit <number> --repo "$repo" --add-label "<label>"
```

When adding more than one label, pass multiple `--label` or `--add-label` flags as needed.

## Output format

When asked to draft a PR, provide:

```md
Title: <repository-compliant title>
Linked issues:
- #123 <issue title>

Recommended labels:
- <label>
- <label>

Reference PRs:
- #456 <title>

Body:
<full PR body that matches the repository template>
```

If no related issue exists, say so clearly.
If `gh` is unavailable, still provide the final title, body, and recommended labels so the user can create the PR without rewriting.
