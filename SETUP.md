# Setup Guide

End-to-end walkthrough to go from an empty fork of this repo to a running agent that can receive tasks in Todoist, process them, and hand results back for approval.

You do not need to finish every section before running your first agent. Sections 1–6 get you to a working agent. Sections 7–8 are optional (persistent memory, more agents).

## Prerequisites

Before starting, make sure you have:

- A GitHub account with a fork of this repo (or a clone you own)
- A [Todoist](https://todoist.com) account that will serve as your primary / human-facing account
- A [Tasklet](https://tasklet.ai) account (this is the runtime that runs your agents)
- [Claude Code](https://claude.com/product/claude-code) installed locally (this is the meta-agent you'll use to build agents)
- A dedicated email address for each agent you plan to run. (Agents need their own accounts in Todoist and optionally elsewhere — easiest way is to give them their own email.)

Optional for later:

- A [Supabase](https://supabase.com) project (only if you want persistent cross-session memory; see `docs/adding-supabase.md`)

## Step 1 — Fork, clone, configure

```bash
# Clone your fork
git clone <your-fork-url>
cd <your-fork>

# Create your personal config (gitignored)
cp config.example.yaml config.yaml
```

Edit `config.yaml`:

- Fill in the `user` block (name, email, role, timezone, aliases)
- Fill in the `organization` block (name, domain, team if relevant)
- Leave `agents: {}` empty for now — you'll add entries as you create agents
- Leave `platforms` with just Todoist for now — add more as you wire tools

## Step 2 — Set up Claude Code as your meta-agent

This is the most underrated step. You'll use Claude Code to **author, edit, and review your agents**, not to run them.

Follow [`docs/claude-code-setup.md`](docs/claude-code-setup.md). In short:

1. Open this repo in Claude Code.
2. Enable bypass mode in Claude Code settings so you're not approving every command.
3. Authenticate GitHub: `gh auth login --web`.
4. Prime Claude Code by pointing it at this repo: "This is a generic agent infrastructure. Read the README, the docs folder, and the agents folder. You'll help me create agents that live as markdown files in this repo."

From this point, **most of the work below can be done through Claude Code instead of by hand**. It can generate SKILL.md files, update config, and walk you through platform setup.

## Step 3 — Create your first agent's Todoist account

Every agent runs under its own Todoist account so assignment is a clean signal.

1. Sign up for Todoist with the agent's dedicated email (e.g. `myagent@yourdomain.com`).
2. Go to your primary Todoist workspace → **Settings → Members** → invite the agent's email as a collaborator.
3. Accept the invitation from the agent's account so it appears in shared projects.
4. Note the agent's Todoist **user ID** — you'll put it in `config.yaml` shortly. (Easiest way: have the agent's account complete one task in a shared project — the assignee ID is the user ID.)

See [`docs/todoist-setup.md`](docs/todoist-setup.md) for the labels, projects, and OAuth app setup that agents depend on.

## Step 4 — Wire Todoist webhooks

This step catches people out. Without OAuth authorization, webhooks silently fail even though everything looks correct.

Follow [`docs/todoist-setup.md`](docs/todoist-setup.md) precisely. The stages are:

1. Create a webhook trigger in Tasklet → note the URL.
2. Register a Todoist OAuth app → set the callback URL to the Tasklet webhook URL, enable `item:completed`, `note:added`, and `item:updated`.
3. **Complete the OAuth authorization flow** as the agent's Todoist user. This is the step most people miss.
4. Verify by creating a test task and confirming the Tasklet trigger fires.

## Step 5 — Author your first agent

Decide the scope. Start narrow. "Triage inbound emails" is too broad. "Draft one-line acknowledgments for cold inbound emails where the sender's domain is not in my contacts" is a good starter scope.

Options to author the SKILL.md:

**Option A (recommended):** Ask Claude Code to do it.

```
I want to create an agent called <name>. Its job is <one-line scope>. It does NOT own <explicit exclusions>.
Ask me questions to fill in the AGENT_TEMPLATE.md, then write agents/<name>/SKILL.md.
At the end, produce the exact prompt I should paste into Tasklet to create the runtime agent.
```

**Option B:** Copy the template manually.

```bash
mkdir -p agents/my-agent
cp agents/AGENT_TEMPLATE.md agents/my-agent/SKILL.md
# edit agents/my-agent/SKILL.md
```

Add the agent to `config.yaml`:

```yaml
agents:
  my-agent:
    email: "myagent@yourdomain.com"
    role: "One-line description"
    skill: "agents/my-agent/SKILL.md"
    tasklet_intelligence: "advanced"
    todoist_user_id: "123456789"   # from Step 3
```

Commit and push:

```bash
git add agents/my-agent config.yaml
git commit -m "Add my-agent"
git push
```

Guide: [`docs/creating-an-agent.md`](docs/creating-an-agent.md).

## Step 6 — Deploy to Tasklet

Follow [`docs/tasklet-setup.md`](docs/tasklet-setup.md). In short:

1. Create a new Tasklet agent named after your agent (e.g. "MyAgent").
2. Connect Todoist with the agent's account. Connect any other tools the agent's SKILL.md declares.
3. Give the agent access to this GitHub repo (so it can pull its own protocol).
4. Paste the prompt generated in Step 5, or manually say: "Read `agents/my-agent/SKILL.md` at the start of every run. Follow the startup reads. Today's first run should include a full GitHub pull."
5. Set up triggers:
   - **Webhook trigger** — pointed at Todoist (Step 4).
   - **Scheduled trigger** — pick a cadence that matches the agent's domain.
6. Set a daily credit limit.

## Step 7 — Test with incremental trust

Start with a low-stakes test:

1. In Todoist, create a task in a shared project and assign it to the agent: "Test: confirm you received this."
2. Verify the agent picks it up (via webhook) and adds a comment acknowledging.
3. Expand — run a real case in the agent's narrow scope. Watch it draft, approve the draft, confirm execution.
4. Once the narrow case is reliable, widen scope.

See `agents/HEARTBEAT.md` for what a normal run looks like.

## Step 8 — Optional: enable persistent memory

If your agent would benefit from remembering things across runs (entity graph, event history, cross-agent context), add Supabase:

- Follow [`docs/adding-supabase.md`](docs/adding-supabase.md).

If you don't need that yet, skip. You can add it later without redoing any of the work above.

## Adding more agents

Repeat Steps 3–6 for each new agent. Each one:

- Gets its own email + Todoist account
- Gets its own SKILL.md in `agents/<name>/`
- Gets its own Tasklet runtime
- Gets added to `config.yaml`
- Must declare its scope, including what it does **not** own — so it doesn't collide with existing agents

See [`agents/HANDOFFS.md`](agents/HANDOFFS.md) for how agents hand off work to each other.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Agent doesn't react to Todoist task | Webhook never fired | Check Todoist OAuth User Count ≥ 1. Redo Step 4 Step 3 (OAuth) exactly. |
| Agent runs but says "no protocol found" | Tasklet agent doesn't have GitHub access | Connect GitHub in Tasklet and grant read on your fork. |
| Agent keeps sending outbound emails without asking | SKILL.md "Safety Constraints" missing or auto-resolver scope too wide | Tighten the agent's authority in its SKILL.md. See `agents/auto-resolver.md`. |
| Two agents fight over the same task | Scope overlap | Make the "I do NOT own" section explicit in both SKILL.md files. |
| Agent changes behavior unexpectedly after a repo edit | Giant context dumped into a file silently overrode a specific rule | Keep SKILL.md short and structured. Move style content to `style_samples/`. |
