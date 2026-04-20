# Heartbeat — Agent Run Pattern

Every agent follows this pattern on each run. Individual agents extend it with domain-specific work in their own SKILL.md.

## Dual-Trigger Architecture

Agents operate on two trigger types:

| Trigger | Source | Latency | Purpose |
|---|---|---|---|
| **Webhook** | External service event (e.g., Todoist `item:completed`, `note:added`, `item:updated`) | Real-time (seconds) | Execute approved tasks immediately when the human takes action |
| **Scheduled Heartbeat** | Cron schedule (e.g., every 5–30 min) | Minutes | Check for new domain work, proactive maintenance, catch anything webhooks missed |

**Webhooks are the primary trigger for task execution.** When a human completes, comments on, or reassigns a task in Todoist, the webhook fires and the agent processes it immediately — no waiting for the next heartbeat.

**The heartbeat handles everything else:** new work in the agent's domain (e.g., a new inbound email, a newly-scheduled meeting), stale item cleanup, and serves as a safety net for webhook events that may have been missed.

## Webhook Run Sequence

When invoked by a webhook event:

### 1. Parse the Event

- Read the webhook payload to identify: event type, task ID, relevant data
- Filter for relevance — only process events matching this agent's labels or `todoist_user_id`
- Ignore events that don't require action (e.g., tasks without `needs-approval` or without a mention of this agent)

### 2. Fetch Full Context

- Get task details and all comments from Todoist
- Load any referenced data from other connected tools or the memory store (if Supabase is enabled)

### 3. Execute

- Follow this agent's SKILL.md workflow
- `item:completed` → execute the approved work (send email, take action)
- `note:added` → read the comment, update drafts, or execute if instructed; check for @mention of this agent
- `item:updated` → check if reassigned to this agent → pick up and process

### 4. Update State

- Post results as a Todoist comment
- Complete or relabel the task as appropriate
- Update any memory-store metadata if applicable

## Scheduled Heartbeat Run Sequence

### 1. Load Context

Read the startup files (if not already loaded this session):

- `agents/RULES.md`
- `agents/priority-map.md`
- `agents/auto-resolver.md`
- Own `SKILL.md`
- `config.yaml`

On the first run of each day, pull the latest from GitHub first (Rule 7 in RULES.md).

### 2. Check for New Work in My Domain

Each agent has sources to check that don't have webhook support. Define these in your SKILL.md "Workflows" section.

Examples:

- Inbox for new emails matching a filter
- Calendar for new meetings or scheduling requests
- A feed, CRM, or other system that only supports polling

### 3. Check Todoist (Safety Net)

Scan Todoist for anything webhooks may have missed:

- Active tasks assigned to this agent that haven't been processed
- Recent `needs-approval` tasks that weren't picked up

### 4. Proactive Maintenance (If Idle)

If steps 2 and 3 produced no work:

- Stale `needs-approval` tasks > 3 days old
- Entity or record gaps (missing IDs, unresolved references)
- Overdue follow-ups: past commitments with no action
- P1–P2 items in `priority-map.md` that may need attention

If maintenance work is found, process it.

### 5. Report Idle

If truly idle, log a heartbeat entry. Do NOT create noise — no Todoist tasks, no notifications. Just confirm the agent is alive and checked everything.

## Timing

- **Webhooks**: process immediately.
- **Heartbeat**: cadence depends on the agent's domain.
  - High-frequency domains (email triage, meeting processing): every 5–15 minutes during active hours.
  - Low-frequency domains (weekly reports, slow pipelines): every 30–60 minutes or less.
- If there is remaining capacity after main work, look for maintenance items.
- If truly idle, stop. Do not invent work.

## Setting Up Triggers for a New Agent

1. **Webhook trigger**: create a Tasklet webhook trigger → register the URL with the external service.
   - For Todoist specifically, see `agents/TOOLS.md` (Todoist section) — the OAuth authorization step is easy to miss.
2. **Heartbeat trigger**: create a Tasklet schedule trigger with the desired cron and time window.
3. Document both triggers in the agent's SKILL.md "Workflows" section.
