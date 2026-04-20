# Principles

The reasoning behind the architecture in this repo. Read this before building your first agent — it will save you a lot of trial and error.

These principles came out of running a real agent fleet and teaching others to do the same. They are opinionated. Where you disagree, disagree loudly, but understand the trade-off first.

---

## 1. Agents are markdown, not code

An agent here is a folder of markdown files. Its `SKILL.md` is the agent. The runtime (Tasklet) is a generic executor; your authoring work is writing and editing text.

Why: Markdown is diff-able, reviewable, and editable by anyone on your team without a deploy. You version agents in git the same way you version anything else. And because each agent is readable in ~5 minutes, you can onboard a new person (or a new agent) to "what does this agent do?" faster than any UI would let you.

**Consequence:** Keep SKILL.md short and structured. If it gets long, the structure is wrong — split into focused sub-files or move examples to a `style_samples/` folder.

## 2. The four layers, separated on purpose

| Layer | Role |
|---|---|
| **GitHub (this repo)** | The DNA. Source of truth for behavior. |
| **Tasklet** | The body. Provides a virtual computer, MCP connectors, cron, and webhook plumbing. |
| **Todoist** | The inbox. Task queue, human approval, inter-agent handoffs. |
| **Claude Code** | The builder. Meta-agent you use to author and edit the other agents. |

Plus an optional fifth:

- **Supabase** — institutional memory / shared state graph.

Each layer does one thing. If you find yourself mixing — e.g., writing execution logic in a GitHub file, or storing long-term memory in Todoist comments — you're fighting the architecture. Push the concern back to the layer that owns it.

## 3. Todoist assignment IS the trigger

There is no "approve this" API between humans and agents. There is just Todoist. You assign a task to an agent and it picks up. You reassign it back and it executes. You comment, it reads.

Why: Every agent action ends up in a place a human sees and can override. Tasks, comments, and labels form an audit log that's legible without you writing any logging code.

**Consequence:** Get your labels and assignment conventions right early. They are your UI.

## 4. Draft-and-ask by default

The default authority mode for any new agent is "draft a proposal, create a Todoist task, wait for approval." Auto-resolve is an opt-in earned over time.

Why: The cost of an agent sending the wrong email to the wrong person is almost always higher than the 30 seconds it took you to approve it. Agents should run on your behalf, not in your place.

**Consequence:** Early-stage agents feel slow. That's correct. Widen autonomy only after a narrow scope has been reliable for weeks.

## 5. Incremental trust

> "It's about incremental trust more than anything. You scope it for a very small thing. When it gets good at that, do a little more."

When you create a new agent, pick the narrowest useful version of its job. Run it. Watch it. Fix the SKILL.md where it gets things wrong. Then — and only then — widen.

**Anti-pattern:** dumping the full desired job description into SKILL.md on day one. You get an agent that is mediocre at ten things instead of great at one.

## 6. Start with the smartest model, ratchet down

> "Get it working with the smartest thing. Once it works well, try to make it a little less smart. Keep making it less smart until it breaks."

The cost difference between intelligence tiers is small relative to the cost of a wrong action. Prove the agent works with the strongest model. Then experiment with smaller tiers on a copy. When output quality degrades, you've found the floor.

## 7. One tool registry; each agent declares its subset

Every platform the org uses gets one entry in `agents/TOOLS.md` and `config.yaml > platforms`. That entry declares access type (MCP / API / manual / indirect) and any org-wide constraints.

Each agent's SKILL.md declares which subset of that registry it uses. The registry is never duplicated inside individual SKILL.md files.

Why: When access to a platform changes — new API, revoked integration, changed account — you update one place. Agents pick it up on the next daily sync.

## 8. Agents coordinate through Todoist + shared state

There is no agent-to-agent message bus. When Agent A needs Agent B to do something, it creates a Todoist task and assigns it to B. When Agent A writes a fact to the shared memory store, Agent B reads it.

Why: Everything goes through interfaces a human can see. You never end up debugging an agent-to-agent deadlock without logs.

## 9. GitHub is the source of truth; agents pull themselves

Every agent, on its first run of the day, pulls the latest version of its own SKILL.md (and the shared files) from GitHub. You edit a behavior, push, and the next day all agents pick it up.

When a user expresses a preference to an agent in real time, that agent is expected to **edit the appropriate file and push**. Preferences expressed to the live agent propagate back to the source of truth automatically.

> "Every preference you express to it here will automatically lead to it updating its GitHub source of truth."

**Consequence:** Every agent needs git push access. Every agent needs to understand that its own source of truth lives in GitHub — not in its runtime's local filesystem.

## 10. The "recursive context" gotcha

When you ask Claude Code to set up an agent, the agent you create also needs to know that this repo defines it. This is often missed.

A correct setup prompt to Tasklet looks like:

> "Create an agent called X. Read this GitHub repo, find `agents/X/SKILL.md` and `agents/RULES.md`, and follow them. On every run, pull the latest first."

A broken prompt is: "Create an agent called X. It should do Y." — because then the Tasklet agent never reads its own source of truth.

## 11. Be careful with giant context dumps

> "You take this big document, make a bunch of changes, and all of a sudden the agent is doing something you didn't ask for."

If you paste a long document into a SKILL.md (or into a conversation with the agent), specific rules elsewhere can get overridden silently. The agent will average out the conflicting signals.

Rules of thumb:

- Keep SKILL.md lean and structured. Move examples to `style_samples/`.
- When you add a new rule, reread the file for conflicts.
- Prefer one clear constraint over a paragraph describing nuance.

## 12. Breaking changes are hard to predict

> "There's no way to predict how changes you make will affect all aspects of the repository."

When you change a rule in `RULES.md`, every agent is affected. When you change the priority map, routing shifts across the fleet. Test after every change. Have Claude Code summarize what it changed and ask it to list the agents likely affected.

**Practical rule:** branch for bigger changes, solo-main for small ones. If a teammate is actively testing, don't edit main under them.

## 13. When stuck, tell the agent to do it itself

If a step is fiddly (click this, paste that), have the agent do it. Tasklet agents have a virtual computer. Claude Code can drive Chrome. You should not be pasting webhook URLs by hand when the agent you're building can do it.

## 14. Re-read the agent's output carefully

Agents are good at looking confident while omitting the critical step. Re-read what they give you, especially handoff instructions ("paste this webhook URL here"). A missed step is the most common reason a setup silently doesn't work.

## 15. Naming is forever

Pick short, memorable, role-hinting names. You will eventually have dozens. Standard pattern: `<name>-<what-it-does-at-high-level>` in the repo folder, a short nickname for the Todoist account.

## 16. Team agents are still unsolved

If multiple humans need one agent's output, your two options are:

- **Duplicate per person** — each human has their own instance with their own config
- **Shared agent** — one runtime, routed by team membership in `config.yaml`

Both work. Neither is clean. Watch the space; this is where the architecture will evolve fastest.

---

## Summary

Build narrow. Earn trust. Put everything in Todoist. Push everything to GitHub. Let Claude Code do the work.
