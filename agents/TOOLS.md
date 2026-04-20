# Tool & Platform Registry

The master list of every platform your agent fleet can touch, organized by department. Each agent's `SKILL.md` declares the subset it uses.

This repo ships with Todoist as the one required tool (it is the task queue). Every other platform — inbox, calendar, CRM, storage, banking, etc. — is something you add for your own stack. Keep this file as the single place where the "how does this platform get accessed?" question is answered.

## Access Types

Every platform declares an access type. This tells agents what they can and cannot do:

| Type | Meaning | Agent can... |
|---|---|---|
| `mcp` | Direct integration via an MCP connector | Read and write via tool calls |
| `tasklet` | Connected through a Tasklet-native integration | Read and write via the Tasklet connection |
| `api` | Direct HTTP API with credentials in the agent's environment | Read and write via HTTP |
| `partial` | Some operations are automated, others are manual | Read what's automated; ask the user for the rest |
| `indirect` | Agent triggers the platform through another channel (e.g., CC'ing an email-driven agent) | Trigger via the other channel |
| `manual` | No automation — human executes directly | Reference it, but never act on it |

Use these in `config.yaml > platforms` and in each SKILL.md's tool list.

---

## Core Infrastructure (All Agents)

### Todoist (Task Management & Approvals) — REQUIRED

Each agent has its own Todoist account. Todoist is the single interface for task creation, human-in-the-loop approval, and inter-agent handoffs. See `docs/todoist-setup.md` for the full setup walkthrough.

#### REST API (v1)

| Operation | API | Notes |
|---|---|---|
| List assigned tasks | `GET /api/v1/tasks` | Filter by assignee |
| Create task | `POST /api/v1/tasks` | Assign to human or agent |
| Update task | `POST /api/v1/tasks/{id}` | Change assignee, labels, priority |
| Complete task | `POST /api/v1/tasks/{id}/close` | Mark as done |
| Reopen task | `POST /api/v1/tasks/{id}/reopen` | Undo completion |
| Move task | `POST /api/v1/tasks/{id}/move` | Change project/section |
| Add comment | `POST /api/v1/comments` | Attach drafts, results, questions |
| List comments | `GET /api/v1/comments?task_id={id}` | Read human feedback |
| Query by filter | `GET /api/v1/tasks/by_filter` | Todoist filter syntax |

**Auth:** Bearer token from the agent's Todoist account.
**Base URL:** `https://api.todoist.com`
**Docs:** https://developer.todoist.com/api/v1/

#### Webhooks (Real-Time Events)

Todoist fires HTTP POST requests to a callback URL when events occur. Your agent platform receives these and invokes the agent immediately.

> ⚠️ **CRITICAL**: Webhooks only fire for **OAuth-authorized users**. Registering an app and enabling events is NOT enough. The account whose actions you want to track must complete the full OAuth authorization flow. Without this, Todoist silently drops all webhook events. See Step 3 in `docs/todoist-setup.md`.

**Events agents typically subscribe to:**

| Event | When it fires | Agent use |
|---|---|---|
| `item:updated` | Task edited (content, labels, assignee, priority) | Detect reassignment to this agent |
| `item:completed` | Task marked complete | Execute approved work |
| `note:added` | Comment added to a task | Read edits/instructions; detect @mentions |

Full list of events: see Todoist's developer docs. For the approval-flow pattern in this repo, enable at minimum `item:completed`, `note:added`, and `item:updated`.

**Webhook payload shape:**

```json
{
  "event_name": "item:completed",
  "user_id": "12345",
  "event_data": {
    "id": "task_id_string",
    "content": "...",
    "labels": ["needs-approval"],
    "priority": 3,
    "project_id": "..."
  }
}
```

For `note:added`, `event_data` includes `content` (the comment text), `item_id`, and a nested `item` object with the full task.

For `item:updated`, `event_data` includes `responsible_uid` — compare against the agent's `todoist_user_id` from `config.yaml` to detect direct assignment.

---

## Adding Your Own Tools

This file becomes much longer once you wire in your stack. Add new sections in a way that another agent author can pick up on cold read. A good tool entry includes:

1. **Purpose** — what the platform is and why agents would touch it
2. **Used by** — which agents (or which agent roles) use it
3. **Access** — the access type from the table above
4. **Capabilities** — a short table of operations the agents will use
5. **Key constraints** — what agents must NEVER do on this platform (e.g., banking: never initiate transactions)

### Template

```markdown
### {Platform Name}

**Purpose:** {What it is and what agents do with it.}
**Used by:** {agents or categories}
**Access:** {mcp | tasklet | api | partial | indirect | manual}

| Capability | Notes |
|---|---|
| {Operation} | {Any limits or caveats} |

**Key constraint:** {What agents must never do here — especially for financial, legal, or destructive actions.}
```

### Examples of Categories

Structure `TOOLS.md` by category. Common ones:

- **Communication** — email client, messaging apps (iMessage, Slack, WhatsApp, Signal)
- **People & CRM** — contact/company/deal systems
- **Scheduling** — calendars, scheduling assistants, travel booking
- **Documents** — cloud storage, knowledge bases
- **Finance** — accounting, expenses, banking, payroll (usually `manual` for writes)
- **Meeting Intelligence** — transcript/recording services
- **Analytics / Business Systems** — whatever's specific to your domain

Keep `manual` entries in the registry too — they tell agents "this exists and matters, but you cannot act on it." That prevents agents from inventing workflows on systems they have no access to.

### Registering Access in config.yaml

Every platform listed here should have a matching entry under `platforms:` in `config.yaml`. Example:

```yaml
platforms:
  communication:
    email:
      access: mcp
      notes: "Draft via create_draft; never send without approval."
  people:
    crm:
      access: mcp
      notes: "Entity resolution only — no record writes without explicit SKILL.md permission."
```

Agents read this at startup and know which tools they may use.

---

## Platform Access Summary Template

A quick-reference table at the end of TOOLS.md helps new agents pick the right tool fast:

| Platform | Agent Access | Integration Method |
|---|---|---|
| Todoist | Direct | API (per-agent auth) + Webhooks |
| {your email} | {access type} | {how it's wired} |
| {your CRM} | {access type} | {how it's wired} |
| {your banking} | Manual only | Human executes all transactions |
| ...
