# Public Agent Infra

A generic, teachable framework for building, managing, and running a fleet of AI agents using **Todoist + Tasklet + Claude Code**. Bring-your-own agents, bring-your-own tools. Persistent memory (Supabase) is an optional add-on you can wire in later.

This repo is deliberately **empty of agents**. It gives you the scaffolding, conventions, and docs so you can stand up your own agents without inventing the plumbing from scratch.

## What You Get

- A repeatable file structure for agent definitions (each agent = a folder of markdown).
- Shared rules, priority map, authority-resolution policy, and heartbeat pattern that every agent inherits.
- A tool registry pattern: declare once, reference per-agent.
- Step-by-step guides for wiring Todoist (webhooks + OAuth), Tasklet (runtime), and Claude Code (the meta-agent you use to build the others).
- A minimal example agent in `examples/` to learn from without polluting `agents/`.
- Optional Supabase add-on for when you want persistent cross-session memory.

## Architecture At A Glance

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│     Todoist      │────▶│     Tasklet      │────▶│  (optional)      │
│  tasks, queue,   │     │  runtime —       │     │    Supabase      │
│  human approval  │◀────│  runs agents on  │     │  persistent      │
│                  │     │  cron & webhooks │     │  memory/graph    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
         ▲                       ▲                          ▲
         │                       │                          │
         │               reads definitions from             │
         │                       │                          │
         │                       ▼                          │
         │               ┌──────────────────┐               │
         │               │   This Repo      │───────────────┘
         │               │   (source of     │
         │               │    truth — the   │
         │               │    agent "DNA")  │
         │               └──────────────────┘
         │                       ▲
         │                       │
         │                edits made via
         │                       │
         │                       ▼
         │               ┌──────────────────┐
         └───────────────│   Claude Code    │
                         │   (meta-agent)   │
                         └──────────────────┘
```

Four layers, each with one job:

| Layer | Job |
|---|---|
| **This repo (GitHub)** | Source of truth for agent behavior. Every agent is a folder of markdown. |
| **Tasklet** | The runtime. Provisions a virtual computer per agent, handles MCP connections, runs on cron and webhook triggers. |
| **Todoist** | The task queue and human-approval interface. Each agent has its own Todoist account; assigning a task to an agent triggers it. |
| **Claude Code** | The meta-agent. You use Claude Code (in this repo) to author, edit, and review agents. |
| **Supabase** *(optional)* | Persistent institutional memory — a structured graph of entities, events, and relationships that agents share. |

## Core Principles (quick version)

Full write-up in [`docs/principles.md`](docs/principles.md).

1. **Agents are markdown, not code.** A `SKILL.md` per agent. The runtime is Tasklet; your job is to define behavior.
2. **GitHub is the DNA.** Agents pull their protocol from this repo each day. Edit the file, push, and every agent on the next sync picks up the change.
3. **Todoist assignment IS the trigger.** No custom API between humans and agents — just reassign a task.
4. **Draft-and-ask by default.** Agents never send external communications, make commitments, or take irreversible actions without a human approving in Todoist.
5. **Incremental trust.** Start with a narrow scope and human-in-the-loop. Widen autonomy only after the narrow version works reliably.
6. **One registry of tools; each agent declares its subset.** Centralize how each platform is accessed (MCP / manual / indirect); per-agent configs pick from the registry.
7. **Agents coordinate through Todoist and shared state.** No agent-to-agent APIs. If work is out of scope, create a task and assign it to the right agent.
8. **Self-updating protocol.** When a user expresses a preference to an agent, the agent updates its own source of truth in this repo and pushes.

## Repo Layout

```
public-agent-infra/
├── README.md                      # this file
├── SETUP.md                       # end-to-end onboarding
├── config.example.yaml            # template — copy to config.yaml and personalize
├── .env.example                   # env template (only needed if using Supabase)
│
├── agents/
│   ├── RULES.md                   # shared rules every agent follows
│   ├── AGENT_TEMPLATE.md          # scaffold for a new agent
│   ├── priority-map.md            # who/what matters — customize for your org
│   ├── auto-resolver.md           # authority modes (auto / draft / escalate / archive)
│   ├── HEARTBEAT.md               # webhook + scheduled run patterns
│   ├── HANDOFFS.md                # inter-agent coordination
│   └── TOOLS.md                   # registry of platforms, how agents access them
│
├── examples/
│   └── example-agent/             # annotated walkthrough of a minimal agent
│
├── docs/
│   ├── principles.md              # the teaching principles (read this first)
│   ├── architecture.md            # how the layers fit together
│   ├── creating-an-agent.md       # step-by-step: adding an agent
│   ├── claude-code-setup.md       # how to use Claude Code as the meta-agent
│   ├── todoist-setup.md           # Todoist projects, labels, OAuth, webhooks
│   ├── tasklet-setup.md           # Tasklet agent configuration
│   └── adding-supabase.md         # optional: wiring up persistent memory
│
└── supabase/                      # optional add-on — empty until you enable it
    ├── README.md
    └── migrations/
        └── 001_initial_schema.sql
```

## Quickstart

1. **Read** [`docs/principles.md`](docs/principles.md) and [`docs/architecture.md`](docs/architecture.md). 10 minutes — this is how the rest of the repo makes sense.
2. **Fork** this repo into your own GitHub org. Your fork is your org's source of truth.
3. **Clone and configure**:
   ```bash
   git clone <your-fork-url>
   cd <your-fork>
   cp config.example.yaml config.yaml
   ```
   Edit `config.yaml` — personalize the `user` and `organization` blocks. Leave the framework sections alone.
4. **Open the repo in Claude Code** and follow [`docs/claude-code-setup.md`](docs/claude-code-setup.md) to prime it as your meta-agent.
5. **Wire Todoist** — follow [`docs/todoist-setup.md`](docs/todoist-setup.md) to create the agent's Todoist account, register an OAuth app, and complete the webhook authorization.
6. **Create your first Tasklet agent** — use Claude Code to generate a `SKILL.md` in `agents/<name>/`, then follow [`docs/tasklet-setup.md`](docs/tasklet-setup.md) to deploy it.
7. **Test with a small scope.** "Pull X from last week, draft a response, ask me to approve." Approve → send → confirm. Earn trust before widening scope.
8. **Optional**: when you need cross-session memory, enable Supabase via [`docs/adding-supabase.md`](docs/adding-supabase.md).

Full walkthrough in [`SETUP.md`](SETUP.md).

## Who This Is For

- Individuals or small teams who want a fleet of narrow agents doing knowledge work on their behalf.
- Anyone teaching this pattern and wanting a clean starting point instead of a bespoke codebase.
- Ops/founder/assistant contexts where human approval matters for most outward-facing actions.

It is **not** a hosted product, a managed framework, or a library of pre-built agents. It is a pattern + scaffolding.

## License

MIT. See [`LICENSE`](LICENSE).
