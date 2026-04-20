# Agent Rules & Patterns

Shared rules every agent in this repo follows. Individual agents add specifics in their own `SKILL.md` files; this file is the common contract.

## Agent Convention

Every agent is defined by a `SKILL.md` file at `agents/{name}/SKILL.md`, following the template in `agents/AGENT_TEMPLATE.md`. The SKILL.md contains the agent's identity, scope, tools, workflows, authority boundaries, and safety constraints.

At the start of every run, agents must read (in order):

1. `agents/RULES.md` (this file)
2. `agents/priority-map.md`
3. `agents/auto-resolver.md`
4. Their own `SKILL.md`
5. `config.yaml`

## 1. Never Hardcode Entities

Do NOT put lists of people, companies, projects, or other entities directly in agent instructions. These change over time and across users.

Instead, look them up at runtime. If you use the optional Supabase add-on, query the `entities` table. Otherwise, rely on the tools (CRM, calendar, inbox) configured in `config.yaml` and resolve on demand.

## 2. Use `config.yaml` for Identity

Never hardcode names, emails, or roles. Read `config.yaml` at startup:

- `config.user.name` / `config.user.email` — whose perspective this agent operates from
- `config.user.timezone` — for any time-sensitive reasoning
- `config.organization` — team structure
- `config.agents` — other agents' emails, roles, and Todoist user IDs

## 3. Task Management via Todoist

Agents use **Todoist** for all task management, approvals, and human communication. Each agent has its own Todoist account. See `agents/TOOLS.md` for full API reference and `docs/todoist-setup.md` for setup.

### Trigger Architecture: Webhooks + Heartbeat

Agents support two trigger models. **Webhooks are preferred** for task execution because they fire instantly when a human takes action.

| Trigger | Purpose | Latency |
|---|---|---|
| **Todoist Webhook** (primary) | Fires instantly on task completion, comment, or update | Real-time (seconds) |
| **Scheduled Heartbeat** (secondary) | Catches non-webhook work: new domain events, stale items, proactive maintenance | Minutes |

### Key Webhook Events

| Event | When it fires | Agent action |
|---|---|---|
| `item:completed` | Human completes/approves a `needs-approval` task | Execute the approved work |
| `note:added` | Human adds a comment (edits, instructions, @mention) | Read comment, update draft, or execute if instructed |
| `item:updated` | Task is reassigned, relabeled, or edited | If reassigned to this agent → pick up and process |

Enable all three on each agent's Todoist app.

### Creating Tasks for Human Review

- Create a Todoist task assigned to the configured user
- Add a comment with the draft/proposal/context
- Add the `needs-approval` label plus source/type labels
- If Supabase is enabled, record the mapping in `todoist_sync`

### Executing Approved Tasks

When a task is completed or reassigned back to the agent:

1. Fetch task details and all comments from Todoist
2. Check the latest comment for edits or instructions
3. Execute per this agent's SKILL.md
4. Post result as a comment on the task
5. Complete the task (if not already completed)

### Clarification Flow

- Add a comment with the question
- Add the `awaiting-info` label
- Reassign to the configured user
- Wait for response (webhook will fire when they reply)

## 4. Authority & Approval

All agents follow the four resolution modes in `agents/auto-resolver.md`:

| Mode | What it means |
|---|---|
| **Auto-resolve** | Agent executes directly. Low-risk, reversible, internal only. |
| **Draft-and-ask** | Agent creates a Todoist task with a proposal. Default for external comms. |
| **Escalate** | Agent creates a high-priority Todoist task. Sensitive or ambiguous situations. |
| **Archive** | No action needed. Log context if applicable. |

**No agent may send external communications, make commitments, or take irreversible actions without explicit human approval.**

## 5. When Unsure, Ask

If an agent is not confident how to classify or act on something:

- Create a Todoist task assigned to the configured user with `needs-approval`
- Include enough context in a comment for a quick answer
- Do not guess — asking is always safer than wrong action

## 6. Thread Continuity (for email-sending agents)

**Reply on the most recent relevant thread** rather than starting a new one, unless the human explicitly requests a new thread.

Before sending:

1. Search the inbox for the most recent thread with the primary recipient
2. If a relevant thread exists (same person/company, ~30 days recent): reply on that thread
3. If not: compose a new email
4. If the human says "new thread": honor it

## 7. Daily Sync from GitHub

Once per day (on the first run), pull the latest repo and reload:

- `agents/RULES.md`
- Your agent-specific `SKILL.md`
- `agents/priority-map.md`, `agents/auto-resolver.md`, `agents/HEARTBEAT.md`
- `config.yaml`

GitHub is the source of truth for agent behavior. If the file on disk differs from `main`, `main` wins.

## 8. Adaptive Self-Update

When the user expresses a preference, correction, or feedback about how agents operate, the receiving agent must update the appropriate file in this repo and push to GitHub.

This is how the system learns and improves. Expressed preferences are not one-off instructions — they become permanent protocol.

### What counts as an expressed preference

- Direct feedback: "Always do X", "Stop doing Y"
- Corrections: "That's not how I want it"
- Style guidance: "Too formal", "Shorter"
- Workflow changes: "Reply on threads instead of new emails"
- Classification guidance: "Treat those as X, not Y"

### How to process

1. **Identify scope** — does this affect:
   - All agents? → `agents/RULES.md`
   - One agent's behavior? → `agents/{name}/SKILL.md`
   - Priority/classification? → `agents/priority-map.md`
   - Resolution policy? → `agents/auto-resolver.md`
   - Identity/config? → `config.yaml`
2. **Draft the change** as a clear, unambiguous rule a future agent can follow without prior context.
3. **Commit and push** to `main` with a descriptive message. GitHub is the system of record.
4. **Confirm to the human** — briefly say what changed and where.

Requirements:

- Every agent must have GitHub push access configured.
- Changes take effect immediately for the agent that made them, and on next daily sync (Rule 7) for others.
- If the preference is ambiguous or could conflict with an existing rule, clarify before updating (Rule 5).

## 9. @Mentions and Direct Assignment

Every agent must listen for and respond to @mentions in Todoist comments and tasks assigned directly to them.

Each agent has a `todoist_user_id` in `config.agents.{name}.todoist_user_id`. This maps to their Todoist collaborator account.

### @Mention in Comments (`note:added`)

- **Detection**: Look for `todoist-mention://{agent_todoist_user_id}` in the comment. Todoist formats @mentions as `[AgentName](todoist-mention://USER_ID)`.
- **Action**:
  1. Parse the request
  2. Execute if within scope and authority
  3. Post a reply comment with results or confirmation
  4. If out of scope, redirect: "That's in X agent's domain" + assign the task to that agent

### Direct Assignment (`item:updated`)

- **Detection**: `event_data.responsible_uid` matches the agent's `todoist_user_id`.
- **Action**:
  1. Read task content and all comments for context
  2. Determine what work is needed
  3. Execute within authority (auto-resolve for internal; draft-and-ask for external)
  4. Post results as a comment
  5. Complete the task or add `awaiting-info` if blocked

### Rules

- Webhooks MUST include `item:updated`, `item:completed`, `note:added`.
- `todoist_user_id` MUST be set in `config.yaml` for every agent.
- @mentions bypass the `needs-approval` label filter — the mention itself is the signal.
- Always reply as a comment on the same task. Never create a new task to reply to a mention.

## 10. Style (for communication-producing agents)

If the agent sends emails or messages:

- Short and action-oriented. Lead with the next step.
- No filler ("I hope this email finds you well", "It was great to discuss...").
- Do not recap — the recipient was there.
- Use numbered lists for action items, not inline prose.
- Study any style samples in `agents/{name}/style_samples/` before drafting.
- Sign off using `config.user.name`.

Agents can override or extend these in their own SKILL.md under "Style & Voice."
