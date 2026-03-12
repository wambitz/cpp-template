# AI Assistant Configuration Guide

This project includes configuration for **Claude Code** and **GitHub Copilot**
so AI tools generate code that matches the project's conventions out of the box.

Think of these files as onboarding documentation for AI pair programmers.

## What's Configured

### Claude Code

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project context: build commands, structure, conventions, anti-patterns |

The following are **recommended additions** (not yet in the repo):

| File | Purpose |
|------|---------|
| `.claude/settings.json` | Pre-approved commands and auto-format hook |
| `.claude/commands/*.md` | Custom slash commands (e.g., `/project:build`, `/project:test`) |

### GitHub Copilot

| File | Purpose |
|------|---------|
| `.github/copilot-instructions.md` | Code style, architecture patterns, naming conventions |

## Claude Code Features Explained

### CLAUDE.md (repository root)

Automatically loaded into every Claude Code conversation. Contains build
commands, project structure, code conventions, and anti-patterns. Claude uses
this to generate code that matches `.clang-format` and `.clang-tidy` rules
without needing to run the formatters.

Supports hierarchical placement — a `CLAUDE.md` in a subdirectory adds context
for that subtree (e.g., `tests/CLAUDE.md` could add test-specific instructions).

### .claude/settings.json — Pre-approved Commands

Without this file, Claude asks permission every time it runs `cmake`, `ctest`,
or `./scripts/build.sh`. The settings file pre-approves safe commands:

```jsonc
{
  "permissions": {
    "allow": [
      "Bash(./scripts/build.sh*)",
      "Bash(cmake *)",
      "Bash(ctest *)"
      // ... additional commands
    ]
  }
}
```

This eliminates repetitive permission prompts and makes Claude significantly
faster to work with. Dangerous commands (`rm -rf /`, `sudo`) are explicitly denied.

Personal overrides should go in `.claude/settings.local.json`; add this path
to your `.gitignore` so local settings aren't committed.

### .claude/settings.json — Auto-Format Hook

The `PostToolUse` hook automatically runs `clang-format` on any `.cpp`, `.hpp`,
or `.h` file that Claude writes or edits. This means Claude's output always
matches the project's formatting rules — even if Claude's generation doesn't
perfectly follow `.clang-format`.

### .claude/commands/ — Custom Slash Commands

These are reusable workflows invoked with `/project:command-name`:

| Command | What it does |
|---------|-------------|
| `/project:build [config]` | Build the project (default: Debug), run tests |
| `/project:test [filter]` | Run test suite, optionally filter by name |
| `/project:check` | Run full CI pipeline locally (format + build + lint + test) |
| `/project:add-library <name>` | Scaffold a new library target with CMake, source, header, and tests |

Commands are invoked with the `/project:` prefix (e.g., `/project:build`).
They accept arguments via `$ARGUMENTS` and are markdown files that tell Claude
what steps to follow — not shell scripts.

### .github/copilot-instructions.md

GitHub Copilot reads this for code generation context. It's intentionally more
concise than `CLAUDE.md` since Copilot uses it as supplementary context alongside
its own code analysis. Focused on naming conventions, architectural patterns,
and build commands.

## How to Customize for Your Project

When you fork this template:

1. **Update `CLAUDE.md`** — Replace example library descriptions with your
   actual architecture
2. **Update `.github/copilot-instructions.md`** — Adjust style rules to match
3. **Add slash commands** — Create `.claude/commands/your-workflow.md` for
   project-specific workflows
4. **Adjust permissions** — Edit `.claude/settings.json` to pre-approve your
   project's build tools

**Tips:**
- Be specific: "Variables use `lower_case`" beats "write clean code"
- Document anti-patterns: "do not use X" prevents common AI mistakes
- Keep `CLAUDE.md` under 200 lines — longer files waste context and reduce adherence
- Test your instructions: ask the AI to generate a file and verify it follows conventions

## Further Reading

- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub Copilot custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
