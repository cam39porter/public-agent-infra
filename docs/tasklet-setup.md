# Tasklet Setup

How to configure Tasklet as the runtime for agents defined in this repo.

## What Tasklet Does

Tasklet is the execution layer. It provides:

- **A virtual computer per agent** (isolated filesystem + sandboxed browser)
- **MCP connectors** (Todoist, email, calendar, CRM, etc.)
- **Trigger plumbing** — cron schedules and incoming webhooks
- **Credit budgeting** — per-agent daily limits
- **A persistent filesystem and SQL store** per agent, for scratch state

This repo provides the agent definitions (SKILL.md, RULES.md, etc.). Tasklet provides the runtime.

## Creating a Tasklet agent

1. In Tasklet, create a new agent. Name it to match the `agents/<name>/` folder in this repo.

2. **Set intelligence level**. Start at the higher end; ratchet down once it's working (see `docs/principles.md` — "Start with the smartest model, ratchet down").
   - `basic` — simple lookups, formatting
   - `advanced` — sensible default for most agents
   - `expert` — multi-source reasoning, research
   - `genius` — extended thinking, demanding analysis

3. **Set a daily credit limit.** Default 4,000/day is a reasonable starting point. Adjust based on observed consumption.

## Connecting tools

### Required for every agent

**Todoist**

- Authenticate with the agent's own Todoist account (the dedicated agent email, not your personal one).
- This gives the agent read/write on tasks assigned to it.

**GitHub**

- Give the agent read access to this repo.
- Required for the daily sync pattern (Rule 7 in `RULES.md`) — agents pull their own SKILL.md every day.
- Grant push access if you want the agent to write adaptive updates back (Rule 8 in `RULES.md`).

### Agent-specific connectors

From the agent's `SKILL.md > Tools & Connections` section, add each listed connector. Cross-reference `agents/TOOLS.md` for auth details.

**Principle:** fewer connectors = cheaper, faster runs. Only connect what's in SKILL.md.

## Pointing the agent at this repo

This is the step most often underspecified. The Tasklet agent must know:

1. Where this repo lives
2. Its own agent name within the repo
3. That it must pull the latest at the start of each day

A good startup prompt in Tasklet:

```
You are the runtime for an agent defined in the GitHub repo <repo-url>.

On every run:
1. If this is your first run of the day, pull the latest from main.
2. Read the startup files in order:
   - agents/RULES.md
   - agents/priority-map.md
   - agents/auto-resolver.md
   - agents/<name>/SKILL.md
   - config.yaml
3. Follow your SKILL.md.

Use `config.yaml` for identity — never hardcode names, emails, or roles.
```

Substitute `<name>` and `<repo-url>` with the actual values. If Claude Code generated the prompt for you (Step 8 in `docs/creating-an-agent.md`), paste that instead.

## Uploading agent files to Tasklet's filesystem (optional)

If your Tasklet runtime can read directly from GitHub, you don't need to upload. The agent pulls on each run.

If it can't, upload a snapshot of:

```
agents/RULES.md
agents/priority-map.md
agents/auto-resolver.md
agents/HEARTBEAT.md
agents/HANDOFFS.md
agents/TOOLS.md
agents/<name>/SKILL.md
agents/<name>/style_samples/   (if applicable)
config.yaml
```

…and tell the agent to re-upload on daily sync.

## Triggers

### Schedule trigger (heartbeat)

- Cron interval matching the agent's domain:
  - Email triage / meeting processing: every 15 min during working hours
  - Daily reports: once a day
  - Weekly digests: once a week

Most active-workday agents fit `*/15 7-21 * * *` in local time.

### Webhook trigger (per external service)

- **Todoist** — see `docs/todoist-setup.md`. Every agent needs this.
- **Other services** (email, calendar, chat) — wire each one as its own trigger if the service supports webhooks. Filter in the agent for relevance.

### Event-driven triggers

For services without real webhooks, poll in the scheduled heartbeat. Do not try to simulate webhooks from polling — just check during the heartbeat and move on.

## Filesystem & memory

Each Tasklet agent has:

- **Persistent filesystem** — survives across sessions. Use for the repo snapshot, generated artifacts, and any long-lived scratch.
- **SQL database** — use for cross-session state that isn't shared with other agents (e.g., deduplication of events this agent has already processed).
- **Working context** — rebuilt each session from files + connected tools. Don't rely on in-memory state between runs.

Shared state across agents lives in Supabase (if enabled) — not in Tasklet's per-agent stores.

## Credit optimization

When a running agent is burning more credits than expected:

- Add filters to triggers (e.g., only webhook on tasks with specific labels)
- Lower the intelligence level
- Remove unused tool connections (more tools = more tokens in context)
- Reduce schedule frequency
- Tighten the SKILL.md (less text = cheaper runs)

If you have style samples, load only the ones matching the current category, not all of them.

## Daily sync pattern

On the first run of each day, the agent pulls this repo and reloads its instructions. Implement this as an explicit step in the SKILL.md workflow or in the Tasklet startup prompt:

```
if first_run_of_day:
    git pull origin main
    reload_startup_files()
```

This is how changes to `RULES.md`, `SKILL.md`, and the other shared files propagate across the fleet without any manual deploy.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Agent behaves like a generic chatbot | Startup prompt doesn't tell it to read SKILL.md from GitHub | Add the explicit pull + read instructions above |
| Agent is slow and expensive | Too many connectors loaded | Remove anything not in SKILL.md |
| Agent ignores updated rules | Daily sync not implemented or GitHub access missing | Add daily pull; verify GitHub read access |
| Agent takes the same action twice | No deduplication store | Use the per-agent SQL store for "already processed" state |
| Webhook fires but agent doesn't respond | Intelligence level too low for the task | Bump one tier up and re-test |
