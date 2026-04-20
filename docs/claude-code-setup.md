# Claude Code Setup — The Meta-Agent

Claude Code is the agent you use to build the other agents. It runs locally on your machine, has access to this repo, and knows how to edit markdown, commit, and push.

This guide gets you from "Claude Code installed" to "ready to author your first agent."

## Why Claude Code

Every file in `agents/` is markdown. Every rule is text. Every handoff is a git commit. Claude Code is already shaped to this kind of work — reviewing code, editing files, running shell commands, using git. It's the lowest-friction tool for maintaining a fleet of agents.

You **author** agents in Claude Code. You **run** them in Tasklet.

## Step 1 — Install Claude Code

See [https://claude.com/product/claude-code](https://claude.com/product/claude-code). Install the CLI for your OS.

## Step 2 — Open the repo

```bash
cd <your-fork-of-this-repo>
claude
```

## Step 3 — Enable bypass mode (optional but recommended)

By default, Claude Code asks for permission on most commands. When you're actively authoring, this gets tiring fast. In Claude Code settings (`~/.claude/settings.json`), enable permission bypass — or use the `--dangerously-skip-permissions` flag for specific sessions.

Trade-off: less friction at the cost of less supervision. Use it only in repos you already trust.

## Step 4 — Authenticate GitHub

Claude Code uses `gh` under the hood:

```bash
gh auth login --web
```

Follow the prompts. Once done, Claude Code can read GitHub issues and PRs, check out branches, and push commits on your behalf.

## Step 5 — Prime Claude Code on this repo

On your first session after cloning, give Claude Code a priming prompt. This helps it understand the structure before you start asking for specific agents.

Paste something like:

```
This repo is a generic framework for building a fleet of AI agents using
Todoist + Tasklet, with an optional Supabase memory layer.

Agents are defined as markdown files in `agents/<name>/SKILL.md`. Shared
behavior lives in `agents/RULES.md`, `agents/priority-map.md`,
`agents/auto-resolver.md`, `agents/HEARTBEAT.md`, `agents/HANDOFFS.md`,
and `agents/TOOLS.md`. Identity and config live in `config.yaml`.

Read the README, docs/principles.md, docs/architecture.md, and the
framework files in agents/. Summarize in your own words what you
understood so I can correct any gaps. After that, you'll help me
author, edit, and review agents in this repo.
```

After it summarizes, correct anything that's off. That is now shared context for the rest of the session (and future sessions if you save a `CLAUDE.md` with your project conventions — see Step 7).

## Step 6 — Typical authoring patterns

Once Claude Code is primed, these prompts cover most of the work.

### Creating a new agent

```
Create an agent called <name>. Its role is <one-line>. It owns:
- <item>
- <item>
It does NOT own:
- <item>

Interview me until you have enough to fill in `agents/AGENT_TEMPLATE.md`.
Then create `agents/<name>/SKILL.md` and update `config.yaml`. At the
end, produce the exact prompt to paste into Tasklet to create the
runtime — including "pull the GitHub repo, read `agents/<name>/SKILL.md`,
follow the startup reads."
```

### Updating shared rules

```
I want to add a rule: <description>. Figure out whether it belongs in
`agents/RULES.md`, an agent's SKILL.md, `priority-map.md`, or `auto-resolver.md`.
Show me the change you want to make before writing it.
```

### Reviewing an agent

```
Read `agents/<name>/SKILL.md`. Look for:
- Scope overlap with other agents in this repo
- Missing safety constraints
- Conflicting rules against `agents/RULES.md`
- Anything too vague to be actionable

Report issues before suggesting fixes.
```

### Porting an existing agent from a different repo

```
I have an agent SKILL.md from a different setup. Here it is:
<paste>

Adapt it to fit this repo's conventions: move shared rules out, reference
our `agents/RULES.md`, declare tools against our `TOOLS.md` registry, and
match the AGENT_TEMPLATE.md structure. Show me a diff before writing.
```

## Step 7 — Project conventions (optional)

If you want Claude Code to remember repo-specific conventions across sessions, create `CLAUDE.md` at the repo root with whatever matters to you:

- Your branch/commit conventions
- Any tools that are always manual for your org
- Style preferences for how agents should introduce themselves

Claude Code reads `CLAUDE.md` at the start of every session.

## The "recursive context" pitfall

When you ask Claude Code to create an agent, there are two distinct contexts at play:

1. **Claude Code's context** — it understands this repo and knows how to write a SKILL.md.
2. **The Tasklet agent's context** — it will run in a separate runtime and needs to be told, explicitly, that its protocol lives here.

A well-crafted Tasklet setup prompt mentions BOTH:

> "You are the runtime for an agent defined in `<repo-url>`. On every run, pull the latest from that repo. Find `agents/<name>/SKILL.md` and follow the Startup Reads listed there."

Missing that second piece is the #1 reason a newly-deployed agent behaves like a generic chatbot.

## When to use Claude Code vs. a Tasklet agent's chat

- **Editing files, committing, running scripts, reviewing diffs, writing new agents** → Claude Code on your laptop.
- **Giving live feedback to a running agent** ("too formal", "stop doing X") → that agent's Tasklet interface or Todoist comments. Per Rule 8, the agent should then update its own SKILL.md and push.

## Tips

- Keep sessions focused on one agent at a time. Long-running cross-fleet sessions drift.
- When Claude Code produces a long diff, ask for a short summary of intent before applying.
- If you're making a risky change, branch first: `git checkout -b refactor/<area>`.
- Commit often. A wrong turn is cheap to back out when commits are small.
