# Todoist Setup

How to configure Todoist as the task queue and approval layer for your agent fleet.

## Core Concept

Every agent has its own Todoist account, with its own email. Tasks are assigned to agents using native Todoist assignment. Agents can act on tasks assigned to them in **any** shared project — no special "agents" project needed.

**Assignment IS the trigger.** Assigning a task to an agent = requesting work. Reassigning between human and agent = the approval ping-pong.

## Step 1 — Create the agent's Todoist account

1. Sign up for Todoist using the agent's dedicated email (e.g. `myagent@yourdomain.com`).
2. From your primary Todoist account, go to **Settings → Members** in your shared workspace and invite the agent's email.
3. From the agent's account, accept the invite.
4. Capture the agent's Todoist **user ID** — you'll need it in `config.yaml` as `agents.<name>.todoist_user_id`. Easiest way: assign the agent a task, then inspect the webhook payload (see below) — `event_data.responsible_uid` is the user ID.

## Step 2 — Set up shared labels

Create these labels in your shared workspace so they're available in every project:

**Source labels** (where a task originated)

- `meeting`
- `email`
- `manual`

**Type labels** (what kind of work it is)

- `follow-up`
- `pass`
- `scheduling`
- `research`

Add more as your domain demands.

**Status labels** (agent-managed)

- `needs-approval` — agent created this, human should review
- `in-progress` — agent is currently executing
- `awaiting-info` — agent asked a question, waiting for a human answer
- `blocked` — agent cannot proceed

These are the status states you'll see most. Add others only when a real pattern emerges.

## Step 3 — Register a Todoist OAuth app (for webhooks)

Webhooks only fire through an OAuth-registered app. Each agent needs its own app and its own OAuth authorization.

1. Go to [Todoist App Management Console](https://app.todoist.com/app/settings/integrations/app-management).
2. Click **Add new integration**.
3. Fill in:
   - **App name**: `<AgentName> Webhook Bridge`
   - **App URL**: any URL (your org site, or a placeholder)
   - **OAuth redirect URL**: `https://httpbin.org/get` (explained in Step 4)
4. In the **Webhooks** section:
   - **Callback URL**: the webhook URL from your Tasklet agent's webhook trigger
   - **Webhook version**: `Todoist API v1`
   - Enable at minimum: `item:completed`, `note:added`, `item:updated`
5. Save. Note the **Client ID** and **Client Secret**.

## Step 4 — Complete the OAuth authorization flow (CRITICAL)

**This is the step that silently breaks most setups.** Todoist webhooks only fire for users who have **OAuth-authorized the app**. Registering the app and ticking events is not enough.

Why the common alternatives don't work:

- **Personal API tokens** — authenticate API requests but don't register an OAuth user
- **"Install for me" in the console** — unreliable; often the User count stays at 0
- **Test tokens** — same issue — not a real OAuth registration

### The httpbin.org OAuth flow

`httpbin.org/get` echoes back query parameters, so you can use it as a redirect URL without standing up a callback server.

1. **Set the OAuth redirect URL** to `https://httpbin.org/get` (done in Step 3).

2. **In a browser logged in as the agent's Todoist account**, open:
   ```
   https://todoist.com/oauth/authorize?client_id=<CLIENT_ID>&scope=data:read_write,data:delete&state=<RANDOM_STRING>&redirect_uri=https://httpbin.org/get
   ```

3. **Click "Allow access"** on the Todoist consent screen.

4. Todoist redirects to httpbin.org, which shows JSON with the authorization code:
   ```json
   {
     "args": {
       "code": "<AUTHORIZATION_CODE>",
       "state": "<RANDOM_STRING>"
     }
   }
   ```

5. **Exchange the code for a token** within a few minutes (codes expire quickly):
   ```bash
   curl -s -X POST "https://todoist.com/oauth/access_token" \
     -d "client_id=<CLIENT_ID>" \
     -d "client_secret=<CLIENT_SECRET>" \
     -d "code=<AUTHORIZATION_CODE>" \
     -d "redirect_uri=https://httpbin.org/get"
   ```

   Response:
   ```json
   {
     "access_token": "<TOKEN>",
     "token_type": "Bearer",
     "expires_in": 315360000
   }
   ```

6. **Verify in the App Management Console** that the User count ≥ 1 (may take a moment).

You now have webhook delivery enabled for that agent. Repeat this step for every agent.

## Step 5 — Verify webhook delivery

1. In Todoist (as your primary account), create a task in a shared project and assign it to the agent.
2. Confirm the Tasklet webhook trigger receives an `item:updated` event.
3. Add a comment on the task. Confirm `note:added`.
4. Complete the task. Confirm `item:completed`.
5. Clean up the test task.

## Approval flows

### Agent-initiated (after processing a domain event)

1. Agent creates task assigned to the human: "Review: Follow-up draft for Acme Corp"
2. Agent adds a comment with the draft
3. Agent adds `needs-approval` + source/type labels
4. Human reviews. Edits the comment if needed. Reassigns the task back to the agent (or completes it if the agent's SKILL.md treats completion as approval).
5. Webhook fires → agent picks up, removes `needs-approval`, adds `in-progress`
6. Agent executes, posts result as a comment, completes the task

### Human-initiated

1. Human creates a task and assigns it to the agent
2. Webhook fires → agent picks up
3. Agent evaluates per `auto-resolver.md`
4. If auto-resolvable → execute, comment, complete
5. If needs approval → draft, add `needs-approval`, reassign to human

### Clarification

1. Agent encounters ambiguity mid-task
2. Agent adds a comment with a question
3. Agent adds `awaiting-info` label, reassigns to human
4. Human answers via a comment. Webhook fires.
5. Agent re-reads comments and resumes (or asks a follow-up)

## Todoist API quick reference

- **Task assignment**: `responsible_uid` field — set on create/update
- **Priority**: `1` (lowest) through `4` (highest). Todoist's numbering is inverted from most conventions; `priority-map.md` maps your tiers accordingly.
- **Labels**: use label names (strings), not IDs
- **Completed tasks**: `GET /tasks/completed` — active `GET /tasks` does not include them
- **No "in-progress" state**: use labels (`in-progress`, `blocked`, etc.)
- **Comments**: `POST /comments` — payload is the draft, result, or question
- **Filtering on webhook delivery**: Todoist delivers all events for the app's scope. Filter in the agent, not in Todoist.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Webhook never fires | User count = 0 (no OAuth authorization) | Complete Step 4 exactly |
| "Install for me" shows success but User count stays 0 | Known Todoist issue | Use the httpbin.org OAuth flow |
| Token exchange returns `invalid_grant` | Auth code expired (minutes) | Redo Step 4 and exchange immediately |
| Token exchange returns `invalid_client` | Wrong Client ID/Secret | Double-check in App Management Console |
| Webhook fires but payload is empty | Wrong webhook version | Set to `Todoist API v1` |
| Events fire for wrong tasks | Missing label filter in agent logic | Filter on `needs-approval` / agent labels in code |
| Webhook delivers for one user but not another | That user hasn't OAuth-authorized | Run Step 4 for that user |
