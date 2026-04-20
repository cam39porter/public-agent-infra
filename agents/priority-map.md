# Priority Map

Defines who and what matters in your org. Agents read this at startup so they route and prioritize work correctly.

**This file is a template.** The tiers below are a reasonable default for an individual or small team. Replace the rows with whoever/whatever matters to you. The column structure is what's important — keep it.

## People Tiers

| Tier | Who | Default Priority | Notes |
|---|---|---|---|
| **P0 — Principal** | `config.user` | Highest | Anything directly from or about the primary user is top priority |
| **P1 — Inner Circle** | Key collaborators, partners, team members from `config.organization.team` | High | People you work with daily |
| **P1 — Key External** | {e.g., top customers, top investors, critical partners} | High | Relationships that move the business |
| **P2 — Active Relationships** | Warm, recent contacts | Medium | 48-hour response expectation |
| **P3 — Network** | Known but not active | Low | Relationship maintenance, not urgent |
| **P4 — Cold Inbound** | Unsolicited outreach | Lowest | Process during idle time only |

## Program Tiers

| Tier | Program | Examples |
|---|---|---|
| **P0** | Time-sensitive / urgent | Active negotiations, closing logistics, fire drills |
| **P1** | Core business operations | Customer/partner follow-ups, recurring ops work |
| **P2** | Pipeline / normal flow | New inbound, routine processing, documentation |
| **P3** | Networking & maintenance | Conference follow-ups, catch-up emails |

## Routing Rules

When a task involves multiple tiers, use the highest applicable:

1. **Principal (P0) + any program** = at least P1
2. **Explicit urgency signal** in content ("urgent", "asap", "today") = bump one tier
3. **Calendar proximity** (related event in next 24 hours) = bump one tier
4. **Stale follow-up** (> 3 days without response on something we committed to) = bump one tier
5. **Cold inbound + no referral** = P4 regardless of other signals

## How Agents Use This

- When creating Todoist tasks, set Todoist priority based on this map.
  - Note: Todoist's priority numbers are inverted — Todoist P1 = lowest, P4 = highest. Our tier P1 maps to Todoist P4, P2→P3, P3→P2, P4→P1.
- When multiple tasks are pending, process in priority order.
- When deciding between auto-resolve and draft-and-ask, higher-priority people/programs lean toward draft-and-ask.
- When idle, look for stale items in P1–P2 tiers first.

## Dynamic vs. Static

Priorities should be **derived from data** where possible, not hardcoded names. If you use the Supabase add-on, store role/stage metadata on entities and query at runtime. If not, prefer CRM/inbox lookups over a hand-maintained list in this file.

A name in this file is a sign the system needs a better data source.
