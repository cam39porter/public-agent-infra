# Creating a New Agent

Step-by-step guide for adding a new agent. Follow in order; run the validation checklist at the end.

## Prerequisites

- This repo cloned locally, `config.yaml` created
- [Claude Code](https://claude.com/product/claude-code) installed and primed on this repo (see `docs/claude-code-setup.md`)
- A Todoist account you will use as the human-facing account
- A Tasklet account
- A dedicated email for the new agent

## Step 1 — Choose the agent's identity

- **Name**: short, memorable, role-hinting (e.g. `inbox`, `meetings`, `scheduler`). This becomes the folder name.
- **Email**: `<name>@<your-domain>` — create in your mail provider. This email is the agent's identity across Todoist and any other accounts.
- **Role**: one-line description of what it does at a high level.

## Step 2 — Scope it narrowly

Write down what the agent owns AND what it does NOT own. Be blunt.

✅ Good scope: "Triage cold inbound emails where the sender's domain is not in my contacts. Draft a one-line acknowledgment for me to approve. Do NOT respond to anything from a known contact."

❌ Too broad: "Handle email."

The narrower the initial scope, the faster you get the agent working. You can widen later.

## Step 3 — Create the agent directory and SKILL.md

**Option A (recommended): ask Claude Code.**

```
I want to create an agent called <name>.
Its role is: <one-line role>.
It owns: <bulleted list>
It does NOT own: <bulleted list — this is critical>

Ask me questions to fill in `agents/AGENT_TEMPLATE.md`. When you have enough,
create `agents/<name>/SKILL.md` and update `config.yaml` to register it.
At the end, produce the exact prompt I should paste into Tasklet to create
the runtime agent — including an explicit instruction to pull this GitHub
repo, find its own SKILL.md, and follow the startup reads.
```

**Option B: do it by hand.**

```bash
mkdir -p agents/<name>
cp agents/AGENT_TEMPLATE.md agents/<name>/SKILL.md
# edit agents/<name>/SKILL.md
```

Fill every section of the template:

- **Identity** — name, email, role
- **Scope** — I own / I do NOT own
- **Startup Reads** — keep the standard list
- **Tools & Connections** — list only what you actually need
- **Workflows** — numbered steps per trigger type
- **Authority Boundaries** — apply the four auto-resolver modes to this agent
- **Safety Constraints** — agent-specific "never do X" rules
- **Style & Voice** — if the agent produces user-facing output

## Step 4 — Style samples (only if applicable)

If the agent sends emails, messages, or other user-facing text, collect 15–20 real samples of how you want it to sound:

```bash
mkdir -p agents/<name>/style_samples
```

Drop a sample per file. Format (free-form, just be consistent):

```
---
to: recipient@example.com
subject: Original subject
date: 2026-01-15
context: category_name
---

The actual text here.
```

Style samples beat style rules. Show, don't tell.

## Step 5 — Register the agent in `config.yaml`

```yaml
agents:
  <name>:
    email: "<name>@yourdomain.com"
    role: "One-line role"
    skill: "agents/<name>/SKILL.md"
    tasklet_intelligence: "advanced"     # basic | advanced | expert | genius
    todoist_user_id: ""                   # fill in after Step 6
```

## Step 6 — Create the agent's Todoist account

1. Sign up for Todoist using the agent's email.
2. From your primary Todoist account, invite the agent's email as a collaborator on your shared projects.
3. Accept the invite from the agent's account.
4. Note the agent's Todoist user ID (visible on the agent account's profile, or by inspecting a webhook payload after it's assigned a task).
5. Fill `todoist_user_id` in `config.yaml`.

## Step 7 — Set up the Todoist webhook (once per agent)

Each agent needs its own Todoist OAuth app and webhook authorization. See `docs/todoist-setup.md` for the exact flow.

Skipping Step 3 of that guide (the OAuth code exchange) is the most common setup failure.

## Step 8 — Create the Tasklet runtime

See `docs/tasklet-setup.md`. In short:

1. In Tasklet, create a new agent named after your agent.
2. Set intelligence level per `config.agents.<name>.tasklet_intelligence`.
3. Connect:
   - **Todoist** — authenticate with the agent's Todoist account
   - **GitHub** — give the agent read access to this repo (needed for the daily pull)
   - Any agent-specific tools declared in SKILL.md (email, calendar, CRM, etc.)
4. Set up triggers:
   - **Webhook** → Todoist callback URL (from Step 7)
   - **Schedule** → cron matching the agent's domain (e.g. every 15 min business hours)
5. Set a daily credit limit.
6. Paste a startup prompt (Claude Code can generate this for you in Step 3):
   > "Your source of truth is the GitHub repo at `<repo-url>`. At the start of every run, pull the latest. Read `agents/<name>/SKILL.md` and follow the Startup Reads listed there. Use `config.yaml` for identity."

## Step 9 — Commit and push

```bash
git add agents/<name>/ config.yaml
git commit -m "Add <name> agent"
git push
```

The Tasklet runtime will pick up the files on its next run (or next daily sync).

## Step 10 — Validate

Use the checklist below. Do not skip.

### Validation checklist

#### Files & config

- [ ] `agents/<name>/SKILL.md` exists and follows `AGENT_TEMPLATE.md`
- [ ] All SKILL.md sections are filled in
- [ ] Scope includes both "I own" AND "I do NOT own" declarations
- [ ] Safety Constraints include "never send external communications without approval"
- [ ] Agent registered in `config.yaml` under `agents` (email, role, skill, tasklet_intelligence, todoist_user_id)
- [ ] Style samples exist (if agent produces user-facing output)

#### Accounts & access

- [ ] Agent email created
- [ ] Todoist account exists for the agent
- [ ] Agent added as collaborator on relevant Todoist projects
- [ ] Tasklet agent created with correct intelligence level

#### Tasklet configuration

- [ ] Todoist connection authenticated with agent's account
- [ ] GitHub connection with read access to this repo
- [ ] Agent-specific tool connections added
- [ ] Schedule trigger configured
- [ ] Webhook trigger configured and OAuth-authorized (critical)
- [ ] Daily credit limit set

#### Functional tests

- [ ] Assign a test task to the agent → agent picks it up via webhook
- [ ] Agent adds a comment on the task
- [ ] Agent completes tasks after execution
- [ ] Agent creates tasks for human review with `needs-approval`
- [ ] Reassigning an approved task back triggers execution
- [ ] @mention of the agent in a comment on any task → agent responds
- [ ] Idempotent — running twice does not create duplicates

#### Cross-agent

- [ ] No scope overlap with existing agents (re-check "I own" sections across the fleet)
- [ ] If this agent routes work to other agents, a test handoff works
- [ ] Agent follows the heartbeat pattern in `agents/HEARTBEAT.md`

## Common mistakes

- **Skipping the "I do NOT own" list.** Agents collide when scope isn't explicitly bounded.
- **Not completing the Todoist OAuth authorization.** The app looks set up; webhooks never fire.
- **Forgetting to add `todoist_user_id` to `config.yaml`.** @mention detection will silently fail.
- **Making SKILL.md too long.** Long files let one rule override another. Keep it structured and terse.
- **Not telling the Tasklet agent to pull from GitHub.** It will invent its own protocol otherwise.
- **Starting with too broad a scope.** You cannot ship a wide agent day one. Narrow, trust, widen.
