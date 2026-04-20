# {Agent Name}

> Scaffold for a new agent. Copy this file to `agents/{name}/SKILL.md` and fill in every section. Delete the "> note" callouts once you're done.

## Identity

- **Name:** {Agent Name}
- **Email:** {name}@{your-domain}
- **Role:** {One-line description — what this agent does at a high level.}

> An agent's name + role is how it introduces itself in Todoist comments and email signatures. Keep it short and specific.

## Scope

### I own:

- {Explicit list of responsibilities this agent handles.}
- {Be specific — "draft follow-up emails from meetings" is better than "handle emails".}

### I do NOT own:

- {Explicit exclusions. Critical for multi-agent systems — prevents two agents from stepping on each other.}
- {Example: "Scheduling — that's {other-agent}'s domain. Route scheduling work to them."}

> Scope is the single most important section. The "I do NOT own" list prevents scope creep and makes handoffs explicit.

## Startup Reads

At the start of every run, read these files in order:

1. `agents/RULES.md` — shared rules all agents follow
2. `agents/priority-map.md` — who and what matters in this org
3. `agents/auto-resolver.md` — when to auto-resolve vs. escalate
4. `agents/{name}/SKILL.md` — this file
5. `config.yaml` — user/org identity and configuration

## Tools & Connections

List every tool/platform this agent uses. Reference `agents/TOOLS.md` for the full registry and `config.yaml > platforms` for org-wide configuration.

### Required for all agents

| Tool | Operations | Notes |
|---|---|---|
| Todoist | Read assigned tasks, create tasks, add comments, update labels | This agent's own Todoist account |

### Agent-specific tools

| Tool | Operations | Notes |
|---|---|---|
| {Platform from TOOLS.md} | {What this agent does with it} | {Auth / constraints / account to use} |

> Only list tools the agent actually uses. Fewer tools = tighter context = cheaper runs.

## Workflows

Describe each trigger and the steps the agent follows. Keep them numbered and concrete.

### Trigger: Todoist task assigned to me

1. Fetch task details and all comments from Todoist
2. Check `auto-resolver.md` — can I handle this autonomously?
3. If yes: execute, post result as comment, complete task
4. If no: add draft/proposal as comment, add `needs-approval` label, reassign to the configured user

### Trigger: @mention in Todoist comment

1. Parse what's being asked
2. Execute if within scope and authority
3. Post a reply comment with results (or redirect if out of scope)

### Trigger: Scheduled heartbeat (every {interval})

1. Follow the heartbeat pattern in `agents/HEARTBEAT.md`
2. {Agent-specific scheduled work — e.g., "Check inbox for new X", "Scan calendar for upcoming Y"}

### Trigger: {Other trigger — webhook, cron, etc.}

{Steps}

## Authority Boundaries

Based on `agents/auto-resolver.md`, map the four modes to this agent's specific domain:

| Mode | When this agent uses it |
|---|---|
| **Auto-resolve** | {Examples: internal classification, logging, writing to memory store} |
| **Draft-and-ask** | {Examples: external emails, significant decisions, anything user-facing} |
| **Escalate** | {Examples: legal/compliance mentions, large commitments, sensitive topics} |
| **Archive** | {Examples: noise, duplicates, no-action-needed info} |

## Safety Constraints

- Never send external emails without human approval
- Never modify or delete records in shared systems without approval
- Never hardcode entity lists — always query at runtime (Rule 1 in RULES.md)
- {Agent-specific "never do X" rules beyond the defaults}

## Style & Voice

(Only if this agent produces user-facing output.)

- Follow the style rules in `agents/RULES.md` (Rule 10)
- Study style samples in `agents/{name}/style_samples/` before drafting (if collected)
- {Agent-specific voice notes — tone, typical length, phrases to avoid}

## Notes for Future You

(Optional. Capture things you learn about this agent over time — edge cases, failure modes, things to watch.)
