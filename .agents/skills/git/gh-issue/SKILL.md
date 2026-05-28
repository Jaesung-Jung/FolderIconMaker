---
name: gh-issue
description: Draft repository-compliant GitHub issues with the `gh` CLI. Use when Codex needs to inspect the current repository's issue templates and title rules, classify a request into the repository's supported issue types, and create or update an issue with labels discovered from GitHub.
---

# GitHub Issue

Draft or create GitHub issues by following the current repository's templates, lint rules, and live labels.
Use files under `.github/` as the source of truth and use the `gh` CLI for live GitHub metadata and issue creation or editing.
Prefer `gh` over connector tools for this skill.

## Discover repository context

Do not hardcode the repository name or assume issue rules.

Prefer commands such as:

```zsh
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
rg --files .github | rg 'ISSUE_TEMPLATE|issue_template|issue'
rg --files .github/workflows | rg 'issue|title|lint'
gh label list --repo "$repo" --limit 200
```

Use the current repository contents to determine:

- which issue templates exist
- whether blank issues are allowed
- what title format is enforced
- which labels actually exist

## Read the source of truth

Before drafting or revising an issue, inspect:

- issue template files under `.github/ISSUE_TEMPLATE/` or equivalent paths
- `.github/ISSUE_TEMPLATE/config.yml` when present
- issue lint workflows under `.github/workflows/`
- live labels from GitHub

If the repository has frontmatter-based issue forms or multiple Markdown templates, choose the template that best matches the request.
If a workflow enforces a title pattern, follow it exactly.

## Choose the issue type from repository reality

Select the issue type supported by the repository, not by this skill.

Common mappings:

- Bug-like templates for broken behavior, regressions, crashes, incorrect output, or mismatches between expected and actual behavior
- Feature-like templates for new capabilities, product enhancements, or user-facing improvements
- Task-like templates for refactors, docs, tooling, migrations, maintenance, cleanup, CI, or internal engineering work

When the repository exposes explicit categories such as `Bug`, `Feature`, and `Task`, use them exactly.
When the request is ambiguous, prefer:

1. Bug-like templates if current behavior is wrong.
2. Feature-like templates if the request adds or expands behavior.
3. Task-like templates for engineering work that is neither of the above.

## Query and apply labels from GitHub

Always query labels with `gh` before recommending or applying them.
Do not assume label names from memory.

Required step:

```zsh
gh label list --repo "$repo" --limit 200
```

Label selection rules:

- Match only labels confirmed to exist in the live repository.
- Normalize names only for matching; apply the exact live label text.
- Prefer one work-type label when the repository has them.
- Add a priority or severity label only when it exists and the request provides enough signal.
- Common work-type patterns to look for include feature, enhancement, bug, bugfix, fix, task, refactor, docs, documentation, test, chore, ci, dependencies, performance, and security.
- Common urgency patterns include `P0` to `P3`, `priority:*`, `severity:*`, `critical`, `high`, `medium`, and `low`.
- If the repository lacks a fitting label, omit it instead of inventing one.
- If the user requests specific labels and they exist, include them.

When editing an existing issue, inspect current labels first and add only the missing ones unless the user asked you to replace labels.

Prefer commands such as:

```zsh
gh issue view <number> --repo "$repo" --json labels
gh issue edit <number> --repo "$repo" --add-label "<label>"
```

## Fill the selected template correctly

Use the actual template headings and required fields from the repository.

- Preserve required headings exactly as the template defines them.
- Remove instructional comments or placeholder guidance from the final body.
- Keep optional sections only when they add value or the template requires them.
- If required information is missing, state what is unknown instead of inventing facts.
- Follow repository language conventions from the template or recent issues.
- Keep technical identifiers such as library names, API names, file paths, commands, and error codes in their original form when that improves clarity.

If the repository uses GitHub issue forms with structured prompts, mirror the expected sections in the generated body as closely as possible.

## Drafting workflow

1. Discover the current repository and inspect its issue templates, config, lint rules, and live labels.
2. Determine which issue type best fits the request.
3. Extract the minimum concrete facts needed to make the issue actionable.
4. Draft a title that matches the repository's enforced pattern.
5. Query live labels with `gh label list`.
6. Recommend labels using only labels confirmed to exist.
7. Fill the selected template with concrete, reviewable content.
8. If the user asked to create the issue, create it with labels.
9. If the issue already exists, update the title, body, and any missing labels.

Prefer commands such as:

```zsh
gh issue create --repo "$repo" --title "<title>" --body-file <file> --label "<label>"
gh issue edit <number> --repo "$repo" --title "<title>" --body-file <file>
gh issue edit <number> --repo "$repo" --add-label "<label>"
```

When adding more than one label, pass multiple `--label` or `--add-label` flags as needed.

## Output format

When asked to draft an issue, provide:

```md
Type: <selected issue type or template>
Title: <repository-compliant title>

Recommended labels:
- <label>
- <label>

Body:
<full issue body that matches the repository template>
```

If `gh` is unavailable, still provide the final title, body, and recommended labels so the issue can be created without rewriting.
