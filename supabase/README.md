# Supabase Add-On

**Optional.** Skip this folder entirely if you don't need persistent cross-agent memory.

When you're ready to enable it, follow [`../docs/adding-supabase.md`](../docs/adding-supabase.md).

## What's here

```
supabase/
├── README.md                              # this file
└── migrations/
    └── 001_initial_schema.sql             # core schema — entities, events, mentions, adjacencies, embeddings, todoist_sync
```

## When to enable

Add Supabase when you have one or more of:

- Multiple agents that benefit from sharing structured knowledge
- Events (meetings, emails) where cross-event context matters
- A desire for semantic search across your agent-visible history

Without it, agents still work — they're just stateless across runs.

## Quick start (once decided)

1. Create a Supabase project → copy the URL + service role key.
2. Copy `.env.example` to `.env` and fill the `SUPABASE_*` vars.
3. Uncomment the `supabase:` block in `config.yaml` and set the URL.
4. In the Supabase SQL editor, paste and run `migrations/001_initial_schema.sql`.
5. In each Tasklet agent, connect Supabase as a custom HTTP API connector.
6. Update your agent SKILL.md files to read/write the relevant tables.

Full walkthrough: [`../docs/adding-supabase.md`](../docs/adding-supabase.md).
