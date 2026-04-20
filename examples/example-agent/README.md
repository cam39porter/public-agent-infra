# Example Agent

A fully-commented walkthrough of a minimal agent. **This is for learning only** — the file lives under `examples/` so it does not pollute your actual `agents/` folder.

The example agent here is `echo`: a stateless agent that acknowledges every task assigned to it and completes it. It does nothing useful, but it exercises the full lifecycle:

- Todoist webhook fires on assignment
- Agent reads task + startup files
- Agent adds a comment ("got it")
- Agent completes the task

Use it as a reference when authoring real agents. Do not deploy it.

## Files

- [`SKILL.md`](SKILL.md) — the agent definition, with inline commentary

## How to use this example

1. Read `SKILL.md` top to bottom — the callouts explain why each section is there.
2. When you create your first real agent, `cp agents/AGENT_TEMPLATE.md agents/<your-name>/SKILL.md` and start from the template. Refer back here if you get stuck on what to put in a section.

## What it intentionally omits

- **Style samples** — `echo` doesn't produce user-facing text, so none are needed. Real agents that send emails should collect 15–20 samples.
- **Memory store usage** — `echo` is stateless. Real agents may read/write Supabase (see `docs/adding-supabase.md`).
- **Handoffs to other agents** — `echo` handles everything in scope itself. Real agents use Todoist assignment to hand off to peers (see `agents/HANDOFFS.md`).
