# Auto-Resolver Policy

Defines when agents can act autonomously vs. when they must get human approval. All agents read this at startup. Individual agents may add stricter constraints in their own SKILL.md (but never looser ones).

## Four Resolution Modes

### 1. Auto-Resolve

Agent executes directly without human approval. Used for low-risk, reversible, internal operations.

**Criteria — ALL must be true:**

- Action is internal (no external party sees the result)
- Action is reversible or append-only
- Action does not commit the user or organization to anything
- Action is within the agent's declared scope (SKILL.md)

**Examples:**

- Writing structured data to an internal memory store
- Classifying an event or item
- Resolving an entity against existing records
- Logging activity
- Marking a Todoist task as in-progress
- Posting an internal summary comment

### 2. Draft-and-Ask

Agent creates a proposal and asks for human approval via Todoist. **This is the default mode** for anything that does not clearly fit auto-resolve.

**Criteria — ANY of these:**

- External person will see the result (email, message, shared doc)
- Action requires judgment about tone, timing, or appropriateness
- Agent is not fully confident in the correct approach
- Action involves a P0–P1 person or program (see `priority-map.md`)

**How to execute:**

1. Create Todoist task assigned to the configured user
2. Add a comment with the draft/proposal and relevant context
3. Add `needs-approval` label + source/type labels
4. Wait for human to review, edit, and reassign back

**Examples:**

- Drafting an outbound email
- Proposing a response to an inbound request
- Suggesting action items from a meeting
- Creating a new external-facing record that needs confirmation

### 3. Escalate

Agent flags for immediate human attention. Used for sensitive or high-stakes situations.

**Criteria — ANY of these:**

- Negative sentiment from a P0–P1 relationship
- Legal, compliance, or regulatory topic mentioned
- Financial commitment or contractual terms discussed
- Ambiguous situation with significant downside risk
- Conflicting instructions from different team members

**How to execute:**

1. Create Todoist task assigned to the configured user
2. Set Todoist priority to P4 (highest/urgent — Todoist's numbering is inverted)
3. Add `needs-approval` label + `escalation` label
4. Add comment explaining why this was escalated and what the agent observed
5. Do NOT take any action on the underlying matter

**Examples:**

- Customer expressed dissatisfaction on a critical account
- Meeting mentioned a legal dispute affecting the business
- Message contained what looks like a contract term change

### 4. Archive

No action needed. Agent logs context (if a memory store is enabled) but does not create a Todoist task.

**Criteria — ALL must be true:**

- No follow-up action required by anyone
- Information is either captured in context or not worth capturing
- No external communication expected

**Examples:**

- Internal meeting with no action items
- Duplicate event already processed
- Small talk or social content with no business implications

## Decision Flowchart

```
Is the action internal-only and reversible?
  ├─ YES → Auto-Resolve
  └─ NO
      Is it sensitive (legal, financial, compliance, P0–P1 negative)?
        ├─ YES → Escalate
        └─ NO
            Does an external person see the result?
              ├─ YES → Draft-and-Ask
              └─ NO
                  Is the agent confident in the approach?
                    ├─ YES → Auto-Resolve
                    └─ NO → Draft-and-Ask
```

## Override Rules

- **When in doubt, default to Draft-and-Ask.** It is always safer to ask.
- Individual agent SKILL.md files may add stricter constraints (never looser).
- `priority-map.md` affects which mode to use: higher-priority people/programs lean toward Draft-and-Ask even for actions that might otherwise auto-resolve.
- If an agent repeatedly escalates the same pattern and the human always approves the same way, update `auto-resolver.md` or the agent's SKILL.md to move it to Auto-Resolve (Rule 8 in `RULES.md`).
