# Adding Supabase (Optional)

Persistent memory for your agent fleet. Enable this when you want agents to share structured knowledge across runs — an entity graph, event history, relationships.

**Start without it.** Agents work well without shared memory. Add Supabase when:

- You have ≥ 2 agents that would benefit from reading each other's outputs
- You're processing events (meetings, emails) where cross-event context matters ("this is the third time Jane has mentioned X")
- You want semantic search across your agent-visible history

You can add Supabase later without redoing any of the core setup. Agents read from it when it's configured; they skip it cleanly when it's not.

## What the add-on gives you

A Postgres database (via Supabase) with these tables:

| Table | Purpose |
|---|---|
| `entities` | People, organizations, projects, topics, places — anything agents refer to by name |
| `events` | Time-stamped things agents process: meetings, emails, calendar invites |
| `mentions` | Entity references inside events (who got talked about, in what context) |
| `adjacencies` | Entity-to-entity relationships inferred from events |
| `mention_embeddings` | Vector embeddings for semantic search over mentions |
| `todoist_sync` | Bridge between Todoist tasks and the entities/events that spawned them |

Agents share all of these. Agent A resolving an entity makes it available to Agent B on the next run.

## Step 1 — Create a Supabase project

1. Sign up at [supabase.com](https://supabase.com).
2. Create a new project. Note:
   - **Project URL** (looks like `https://xxx.supabase.co`)
   - **Service role key** (Dashboard → Project Settings → API → Secret keys)

The service role key bypasses row-level security. Treat it like a password.

## Step 2 — Configure

Add to `.env` (never commit):

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Add to `config.yaml`:

```yaml
supabase:
  url: "https://your-project.supabase.co"
  # key comes from .env — never put it here
```

## Step 3 — Run the schema migration

Open the Supabase SQL editor. Paste and run `supabase/migrations/001_initial_schema.sql`.

This creates all tables, indexes, and triggers.

Verify the tables exist in the Supabase Table Editor: `entities`, `events`, `mentions`, `adjacencies`, `mention_embeddings`, `todoist_sync`.

## Step 4 — Tell agents about Supabase

In each agent's Tasklet runtime, connect Supabase as a custom HTTP API:

- **Base URL**: `{SUPABASE_URL}/rest/v1/`
- **Auth header**: `apikey: {SUPABASE_SERVICE_ROLE_KEY}` and `Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}`
- For upserts, include `Prefer: resolution=merge-duplicates`

Each agent's `SKILL.md > Tools & Connections` section should list Supabase and the specific tables it reads/writes.

## Step 5 — Update agent behavior

A few rules in `agents/RULES.md` become more useful once Supabase is enabled:

- Entity resolution (check `entities` first, then fall back to your CRM)
- Priority-map lookups (query entities by metadata instead of hand-listing them)
- Event deduplication (check the unique constraint on `events(source_system, source_id)`)

You may also want to add a shared adjacency-writer pattern: every time an agent sees two entities in the same event, write an `adjacencies` row. Over time, the fleet builds a shared graph of "who's connected to whom and why."

## Patterns

### Entity resolution (canonical)

```
1. Got a name mentioned in an event.
2. Query entities: exact match on name, then alias match via aliases array.
3. Hit? Use that entity.
4. Miss? Fall back to your CRM's search. Create entity if found.
5. Still nothing? Create a new entity with type guessed from context
   and flag for human confirmation (Todoist task with `needs-approval`).
```

### Event ingestion

```
1. Pull events from source (email, meeting platform, etc.).
2. For each, check if (source_system, source_id) already exists.
3. If yes, skip (idempotency).
4. If no, insert and set processed_at = NULL.
5. Process each unprocessed event in order.
6. Set processed_at = now() when done.
```

### Semantic search (optional)

With `mention_embeddings`, you can ask "what have we said about X lately" via vector search. Useful for agents that need context beyond what's already structured.

## What NOT to put in Supabase

- Credentials, tokens, or any secrets (they belong in Tasklet connectors or `.env`)
- Full email/meeting bodies if they contain sensitive content — store a summary and reference to the source, or use a dedicated encrypted field
- Per-agent scratch state (that belongs in Tasklet's per-agent SQL store)

## Scaling considerations

- **pgvector index**: the default `ivfflat` with `lists = 100` is fine up to ~100k embeddings. Retune as you grow.
- **Row-level security**: off by default since the agents use the service role key. Turn it on if multiple humans or third parties need direct DB access.
- **Backups**: Supabase handles daily backups. For higher-stakes data, add your own dump-to-storage cron.

## Disabling the add-on

If you want to turn it off:

- Remove the `supabase:` block from `config.yaml`
- Remove the `SUPABASE_*` entries from `.env`
- Drop the connector from each Tasklet agent

Agents will see Supabase as "not configured" and skip the memory-store steps. No code changes required as long as agent SKILL.md files handle the missing connector gracefully.
