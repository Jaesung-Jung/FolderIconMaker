---
name: revise-agents-md
description: Capture useful learnings from the current Codex session and propose concise updates to AGENTS.md files. Use near the end of a session, or when the user asks to revise AGENTS.md, capture project instructions, record missing context, update Codex project memory, or save recurring commands, workflows, gotchas, testing approaches, environment quirks, or codebase conventions discovered while working.
---

# Revise AGENTS.md

Review the current session for learnings that would help future Codex sessions work more effectively in this codebase. Propose concise updates to the relevant AGENTS.md file, then edit only after user approval.

## Workflow

### 1. Reflect

Identify reusable context discovered during this session:

- Commands or workflows that were used, fixed, or discovered
- Code style patterns followed in this repository
- Testing approaches that worked
- Environment or configuration quirks
- Warnings, gotchas, or non-obvious repo behavior
- Project-specific user preferences that should apply to future Codex work

Only keep information likely to recur. Skip one-off fixes, obvious facts, and generic engineering advice.

### 2. Find AGENTS.md Files

Find candidate instruction files:

```bash
find . -name "AGENTS.md" 2>/dev/null | head -50
```

Choose the narrowest appropriate file:

- `./AGENTS.md` for repo-wide instructions shared by all future sessions
- Nested `AGENTS.md` for instructions that apply only to a package, module, or subdirectory

If no AGENTS.md exists, propose creating one before editing.

### 3. Draft Additions

Keep additions compact because AGENTS.md is prompt context.

Preferred format:

```markdown
- `<command or pattern>` - <brief project-specific guidance>
```

Use a short section only when it improves scanability. Avoid long explanations.

### 4. Show Proposed Changes

For each proposed update, show:

```markdown
### Update: ./AGENTS.md

**Why:** <one-line reason>

\```diff
+ <the addition - keep it brief>
\```
```

### 5. Apply With Approval

Ask whether the user wants to apply the proposed changes. Only edit files they approve.

When applying updates:

- Preserve the existing AGENTS.md structure
- Add only the approved lines
- Remove or revise text only when the user approves that exact change
- Keep the result concise and actionable
