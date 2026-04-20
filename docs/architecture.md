# Architecture

How the layers fit together. Read this after `principles.md` and before creating your first agent.

## The Five Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                       CLAUDE CODE                                │
│   (meta-agent — you use this to author and edit other agents)    │
└─────────────────────────┬───────────────────────────────────────┘
                          │ edits files, commits, pushes
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    THIS REPO (GITHUB)                            │
│   Source of truth for agent behavior:                            │
│     agents/<name>/SKILL.md   — per-agent definition              │
│     agents/RULES.md          — shared rules                      │
│     agents/priority-map.md   — org priorities                    │
│     agents/auto-resolver.md  — authority modes                   │
│     agents/TOOLS.md          — tool registry                     │
│     config.yaml              — identity/config                   │
└──────────┬──────────────────────────────────┬───────────────────┘
           │ agent pulls its own              │
           │ protocol daily                    │
           ▼                                   ▼
┌───────────────────────────┐   ┌────────────────────────────────┐
│        TASKLET             │   │         TODOIST                │
│  One runtime per agent.    │   │  One account per agent.        │
│  Provisions virtual        │◀─▶│  Task queue, human approval,   │
│  computer, holds MCP       │   │  inter-agent handoffs.         │
│  connectors, fires on      │   │                                │
│  cron + webhook triggers.  │   │  Assignment IS the trigger.    │
└──────────┬────────────────┘   └────────────────────────────────┘
           │
           │ (optional)
           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SUPABASE                                  │
│   Persistent memory / shared state graph.                        │
│   entities / events / mentions / adjacencies.                    │
│   All agents read & write here if enabled.                       │
└─────────────────────────────────────────────────────────────────┘
```

## Responsibilities By Layer

### Claude Code (the builder)

- Authors `agents/<name>/SKILL.md` when you create an agent
- Edits shared rules, priority map, auto-resolver policy as your org evolves
- Drives set-up steps that are fiddly in a UI (webhook registration, OAuth flows)
- Reviews changes before you push

You run Claude Code on your laptop. It never executes agents at runtime — it's purely for building.

### This repo (the DNA)

- One folder per agent: `agents/<name>/`
- Shared framework files in `agents/` (RULES, TEMPLATE, priority-map, auto-resolver, HEARTBEAT, HANDOFFS, TOOLS)
- `config.yaml` declares your user, org, every agent, and every platform
- Platform-independent: agents read this repo from wherever they run

Change once, propagate everywhere. That's the point.

### Tasklet (the runtime)

- One Tasklet agent per agent you've defined in this repo
- Provisions a virtual computer per agent (isolated filesystem + sandboxed browser)
- Holds MCP connectors (Todoist, email, CRM, calendar, etc.)
- Runs on two trigger types: cron and webhook
- Manages credits / budget per agent

A Tasklet agent is configured to know:

1. Where this repo is (for pulling its protocol)
2. Its own agent name (so it knows which SKILL.md to read)
3. Which connectors it needs (from the SKILL.md "Tools & Connections" section)

On every run, the Tasklet agent: pulls the repo (first run of the day), reads the startup files, executes the workflow, writes results back to Todoist (and optionally Supabase).

### Todoist (the inbox)

- One Todoist account per agent (tied to a dedicated email)
- Tasks in any shared project are the unit of work
- **Assignment is the trigger.** Assigning a task to an agent = requesting that agent do the work
- Reassignment is the handshake:
  - Human → Agent = "please do this"
  - Agent → Human (with `needs-approval`) = "please review this draft"
  - Human → Agent (again) = "approved, execute it"
- Labels convey intent (source, type, status)
- Comments carry drafts, results, and clarifications
- Webhooks (on `item:completed`, `note:added`, `item:updated`) fire Tasklet runs in real time

### Supabase (optional — the memory)

- Postgres + pgvector
- Shared tables that all agents read/write:
  - `entities` — people, organizations, projects, topics
  - `events` — meetings, emails, anything time-stamped that agents process
  - `mentions` — entity references within events
  - `adjacencies` — entity-to-entity relationships
  - `todoist_sync` — bridge between Todoist tasks and entities/events
- Enables semantic search (via embeddings) and cross-agent context
- Not needed for stateless / single-shot agents

## Request Flows

### Flow A: Human assigns a task to an agent

```
Human                Todoist             Tasklet              Agent code
  │                    │                    │                    │
  ├── assigns task ───▶│                    │                    │
  │                    ├── item:updated ───▶│                    │
  │                    │   webhook fires    ├── load startup ───▶│
  │                    │                    │   files            │
  │                    │                    │                    │
  │                    │                    ├── execute SKILL ──▶│
  │                    │                    │   workflow         │
  │                    │◀── add comment ────┤                    │
  │                    │    with draft      │                    │
  │                    │    + needs-approval│                    │
  │◀── sees task ──────┤                    │                    │
  │   in their list    │                    │                    │
```

### Flow B: Human approves a drafted action

```
Human                Todoist             Tasklet              Agent code
  │                    │                    │                    │
  ├── reviews draft ──▶│                    │                    │
  ├── edits comment ──▶│                    │                    │
  ├── completes or ───▶│                    │                    │
  │   reassigns back   │                    │                    │
  │                    ├── item:completed ─▶│                    │
  │                    │   OR item:updated  ├── load context ───▶│
  │                    │                    │                    │
  │                    │                    ├── execute ───────▶│
  │                    │                    │   approved work   │
  │                    │                    │                    │
  │                    │◀── post result ────┤                    │
  │                    │◀── complete task ──┤                    │
  │◀── sees done ──────┤                    │                    │
```

### Flow C: Agent encounters work outside its scope

```
Agent A              Todoist             Agent B
  │                    │                    │
  ├── detects scope ──▶│                    │
  │   mismatch         │                    │
  ├── creates task ───▶│                    │
  │   assigned to B    │                    │
  │                    ├── item:updated ───▶│
  │                    │   webhook          │
  │                    │                    ├── picks up task
  │                    │                    │   (normal flow)
```

### Flow D: Scheduled heartbeat (no webhook)

```
Tasklet cron         Agent code
  │                    │
  ├── fires ──────────▶├── load startup files
  │                    ├── check domain for new work
  │                    │   (new emails, meetings, etc.)
  │                    ├── safety-net scan of Todoist
  │                    ├── proactive maintenance if idle
  │                    └── log heartbeat
```

## Identity: Who Is Each Agent?

Each agent has:

- **A name** (e.g. `meetings`, `scheduler`, `triage`) — used in folder names and Tasklet
- **An email** — used to sign up for Todoist and any other per-agent accounts
- **A Todoist user ID** — after the account exists; lives in `config.yaml`
- **A SKILL.md** — its behavior
- **A Tasklet agent** — its runtime

The email is the linchpin. It gives each agent a stable identity across every tool it touches.

## Where State Lives

| State | Where | Why |
|---|---|---|
| Agent behavior | This repo | Version-controlled, reviewable, pullable |
| Active tasks | Todoist | Human-visible inbox |
| Per-agent filesystem | Tasklet | Scratch space for a run |
| Cross-run memory (optional) | Supabase | Shared structured state |
| Credentials / tokens | Tasklet connectors | Scoped per-agent |
| User identity | `config.yaml` | One place |

## When to Reach For Each Layer

Building something?

- **New agent** → create `agents/<name>/SKILL.md`, add to `config.yaml`, deploy in Tasklet
- **New tool the agents will share** → add to `TOOLS.md` and `config.yaml > platforms`
- **New behavior rule for all agents** → edit `agents/RULES.md`
- **New way to prioritize work** → edit `agents/priority-map.md`
- **Something an agent learned that should be permanent** → edit the relevant file, push (Rule 8 in RULES.md)
- **Persistent memory or cross-agent graph** → add Supabase

Debugging something?

- **Agent didn't react to an action** → Todoist webhooks. Check the OAuth user count.
- **Agent ran but did the wrong thing** → re-read its SKILL.md. Look for a conflicting rule in a file it reads on startup.
- **Two agents did the same thing** → scope overlap. Check "I do NOT own" on both.
- **Agent forgot context across runs** → add Supabase, or scope the job tighter so it doesn't need cross-run memory.
