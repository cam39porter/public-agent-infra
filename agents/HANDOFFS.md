# Inter-Agent Handoffs

How agents coordinate work and hand off tasks to each other.

## Core Principle

Agents communicate through **Todoist assignment** and **shared state** (the memory store, if enabled). There are no direct agent-to-agent API calls or message queues.

Why: Todoist gives you a visible, auditable, human-interruptible queue. Every agent action shows up in a place a human can see, edit, or redirect. Direct API calls between agents would skip that audit layer.

## Handoff via Todoist Assignment

When an agent encounters work outside its scope:

1. Create a Todoist task with a clear description
2. Assign it to the correct agent (by their Todoist account)
3. Add a comment with all relevant context (task IDs, event IDs, what was attempted, what's needed)
4. Add appropriate labels (source, type)
5. If the memory store is enabled, record the handoff

The receiving agent picks up the task via its normal heartbeat/webhook flow.

### Example: Agent A → Agent B

Agent A handles meeting follow-ups. A meeting results in a scheduling need, which is Agent B's domain:

1. Agent A creates a Todoist task: "Schedule follow-up with {person}"
2. Assigns to Agent B's Todoist account
3. Comment: "User wants a 30-min follow-up next week. Context: {what was discussed}, recipient email: {email}. Original event ID: {uuid}"
4. Labels: `scheduling`, `meeting`

Agent B's webhook fires → it picks up, evaluates authority, drafts the scheduling email or calendar proposal, and follows the draft-and-ask flow with the user.

### Example: Agent → Human → Agent

For significant actions, the approval flow goes through a human:

1. Agent creates task assigned to user: "Review: Follow-up draft for {person}"
2. User reviews and edits the draft comment
3. User reassigns task back to the agent
4. Agent sends, posts confirmation, completes task

## Shared Context (Optional)

If you enable the Supabase add-on, all agents can read and write the same tables. This is the primary way they share structured information:

- **Entities** resolved by Agent A can be used by Agent B immediately
- **Events** ingested by one agent can be referenced by another
- **Mentions / adjacencies** contribute to a shared relationship graph

Without Supabase, shared context still works — agents can read each other's Todoist tasks and comments — it's just less structured.

## Ownership Boundaries

Each agent's SKILL.md declares what it owns and what it doesn't. When work falls outside scope:

1. Check if another agent owns it (look at other SKILL.md "I own" sections or `config.agents` roles)
2. If yes → create a Todoist task assigned to that agent
3. If no → create a Todoist task assigned to the user with `needs-approval`
4. **Never silently drop work that's out of scope.**

## Human-in-the-Loop

For any significant or irreversible action:

- Agent creates a task assigned to the user
- User reviews and either executes themselves or reassigns to an agent
- This is especially important for external communications, financial matters, and anything touching sensitive relationships.

See `agents/auto-resolver.md` for the four-mode framework that governs when a human must be in the loop.

## Detecting @Mentions Across Agents

Humans can direct work to an agent by @mentioning it in a comment on any task — even a task primarily assigned to a different agent. All agents listen for their own `todoist_user_id` in comment content regardless of task assignment.

If an @mention targets this agent but the request is out of scope:

1. Reply with what you can and can't do
2. Suggest the correct agent
3. Optionally reassign the task to that agent with a comment explaining what was asked
