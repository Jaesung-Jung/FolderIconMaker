---
name: git-commit
description: 'Prompt and workflow for generating conventional commit messages using a structured XML format. Guides users to create standardized, descriptive commit messages in line with the Conventional Commits specification, including instructions, examples, and validation.'
---

### Instructions

```xml
	<description>This file contains a prompt template for generating conventional commit messages. It provides instructions, examples, and formatting guidelines to help users write standardized, descriptive commit messages in accordance with the Conventional Commits specification.</description>
```

### Workflow

**Follow these steps:**

1. Run `git status` to review changed files.
2. Run `git diff` or `git diff --cached` to inspect changes.
3. Stage your changes with `git add <file>`.
4. Construct your commit message using the following XML structure.
5. After generating your commit message, Copilot will automatically run the following command in your integrated terminal (no confirmation needed):

```bash
git commit -m "type(scope): description" -m "- Summarize one concrete part of the change
- Summarize another concrete part of the change"
```

6. Just execute this prompt and Copilot will handle the commit for you in the terminal.

### Commit Message Structure

```xml
	<commit-message>
		<type>feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert</type>
		<scope>A required scope that identifies the affected area</scope>
		<description>A short, imperative summary of the change</description>
		<body>A required concise bullet list summarizing what changed, grouped by the actual changes</body>
		<footer>(optional: e.g. BREAKING CHANGE: details, or issue references)</footer>
	</commit-message>
```

### Body Guidelines

```xml
<body-guidelines>
	<format>Use bullet points for the detailed description. Each bullet must start with "- ".</format>
	<content>Summarize the staged changes by concrete change area, not by restating every file.</content>
	<style>Keep each bullet short, direct, and written in the imperative mood when possible.</style>
	<count>Use only as many bullets as the change needs, usually 2-4.</count>
	<avoid>Do not write the body as one long paragraph or a comma-separated list.</avoid>
</body-guidelines>
```

### Examples

```xml
<examples>
	<example>
		<subject>feat(parser): add ability to parse arrays</subject>
		<body>- Add array token handling for nested values
- Preserve parsed output so it matches the source structure</body>
	</example>
	<example>
		<subject>fix(ui): correct button alignment</subject>
		<body>- Adjust button layout constraints
- Align primary actions consistently across compact and regular widths</body>
	</example>
	<example>
		<subject>docs(readme): update usage instructions</subject>
		<body>- Document the current setup flow
- Add command examples for running the project</body>
	</example>
	<example>
		<subject>feat(auth)!: send email on registration</subject>
		<body>- Add the registration email flow
- Require email service configuration before account creation</body>
		<footer>BREAKING CHANGE: email service configuration is now required.</footer>
	</example>
</examples>
```

### Validation

```xml
<validation>
	<type>Must be one of the allowed types. See <reference>https://www.conventionalcommits.org/en/v1.0.0/#specification</reference></type>
	<scope>Required by this skill. Choose the narrowest affected area, such as ui, parser, auth, docs, build, or config.</scope>
	<description>Required. Use the imperative mood (e.g., "add", not "added").</description>
	<body>Required. Write the detailed description as concise bullet points based on the staged changes.</body>
	<footer>Optional. Use for breaking changes or issue references.</footer>
</validation>
```

### Final Step

```xml
<final-step>
	<cmd>git commit -m "type(scope): description" -m "- First concise bullet
- Second concise bullet"</cmd>
	<note>Replace both message parts with your constructed subject and required bullet-list detailed description. Add another -m for a footer when needed.</note>
</final-step>
```
