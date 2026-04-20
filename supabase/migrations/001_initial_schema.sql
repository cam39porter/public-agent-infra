-- Public Agent Infra — optional Supabase add-on
-- Generic schema for shared agent memory: entities, events, mentions,
-- adjacencies, embeddings, and a Todoist bridge.
--
-- Run this once in a fresh Supabase project. Safe to re-run with no data.

create extension if not exists pgcrypto;
create extension if not exists vector;

-- Helper trigger for keeping updated_at current
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ---------------------------------------------------------------------------
-- entities — anything agents refer to by name
-- ---------------------------------------------------------------------------
create table if not exists entities (
  id              uuid primary key default gen_random_uuid(),
  type            text not null check (type in ('individual', 'organization', 'place', 'project', 'topic')),
  name            text not null,
  aliases         text[] not null default '{}',
  external_id     text,                                  -- optional ID in your CRM or other system of record
  metadata        jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_entities_type on entities(type);
create index if not exists idx_entities_name on entities using gin (to_tsvector('english', name));
create index if not exists idx_entities_aliases on entities using gin (aliases);
create unique index if not exists idx_entities_external on entities(external_id) where external_id is not null;

drop trigger if exists trg_entities_updated_at on entities;
create trigger trg_entities_updated_at
  before update on entities
  for each row execute function update_updated_at();

-- ---------------------------------------------------------------------------
-- events — time-stamped things agents process (meetings, emails, etc.)
-- ---------------------------------------------------------------------------
create table if not exists events (
  id              uuid primary key default gen_random_uuid(),
  type            text not null check (type in ('meeting', 'email', 'calendar_invite', 'other')),
  source_system   text not null,                         -- e.g. 'gmail', 'calendar', 'transcript-service'
  source_id       text not null,                         -- external unique ID
  title           text,
  occurred_at     timestamptz not null,
  participants    text[] not null default '{}',
  raw_content     text,
  metadata        jsonb not null default '{}',
  processed_at    timestamptz,
  created_at      timestamptz not null default now(),

  unique(source_system, source_id)
);

create index if not exists idx_events_type on events(type);
create index if not exists idx_events_occurred on events(occurred_at desc);
create index if not exists idx_events_source on events(source_system, source_id);
create index if not exists idx_events_unprocessed on events(processed_at) where processed_at is null;

-- ---------------------------------------------------------------------------
-- mentions — entity references inside events
-- ---------------------------------------------------------------------------
create table if not exists mentions (
  id              uuid primary key default gen_random_uuid(),
  entity_id       uuid not null references entities(id) on delete cascade,
  event_id        uuid not null references events(id) on delete cascade,
  context         text not null,                         -- the surrounding snippet
  disposition     text,                                  -- agent-inferred disposition (e.g. 'positive', 'neutral', 'concern')
  sentiment       text,
  mentioned_by    uuid references entities(id) on delete set null,
  tags            text[] not null default '{}',
  created_at      timestamptz not null default now(),
  created_by      text not null                          -- which agent wrote this
);

create index if not exists idx_mentions_entity on mentions(entity_id);
create index if not exists idx_mentions_event on mentions(event_id);
create index if not exists idx_mentions_disposition on mentions(disposition) where disposition is not null;
create index if not exists idx_mentions_created on mentions(created_at desc);

-- ---------------------------------------------------------------------------
-- adjacencies — entity-to-entity relationships observed in events
-- ---------------------------------------------------------------------------
create table if not exists adjacencies (
  id              uuid primary key default gen_random_uuid(),
  entity_a_id     uuid not null references entities(id) on delete cascade,
  entity_b_id     uuid not null references entities(id) on delete cascade,
  event_id        uuid not null references events(id) on delete cascade,
  relationship    text,                                  -- free-form e.g. 'colleagues', 'introduced-by', 'portfolio'
  context         text,
  created_at      timestamptz not null default now(),
  created_by      text not null,

  check (entity_a_id < entity_b_id),                     -- canonical ordering to avoid duplicates
  unique(entity_a_id, entity_b_id, event_id)
);

create index if not exists idx_adjacencies_a on adjacencies(entity_a_id);
create index if not exists idx_adjacencies_b on adjacencies(entity_b_id);
create index if not exists idx_adjacencies_event on adjacencies(event_id);

-- ---------------------------------------------------------------------------
-- mention_embeddings — vector search over mentions
-- ---------------------------------------------------------------------------
create table if not exists mention_embeddings (
  mention_id      uuid primary key references mentions(id) on delete cascade,
  embedding       vector(1536),
  content         text
);

create index if not exists idx_mention_embeddings
  on mention_embeddings
  using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

-- ---------------------------------------------------------------------------
-- todoist_sync — bridge between Todoist tasks and the context that spawned them
-- ---------------------------------------------------------------------------
create table if not exists todoist_sync (
  todoist_task_id text primary key,
  event_id        uuid references events(id) on delete set null,
  entity_ids      uuid[] not null default '{}',
  agent_name      text,
  task_type       text,                                  -- e.g. 'follow-up', 'pass', 'scheduling'
  status          text,                                  -- mirror of Todoist's current state, for quick lookup
  metadata        jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_todoist_sync_event on todoist_sync(event_id);
create index if not exists idx_todoist_sync_agent on todoist_sync(agent_name);
create index if not exists idx_todoist_sync_status on todoist_sync(status);

drop trigger if exists trg_todoist_sync_updated_at on todoist_sync;
create trigger trg_todoist_sync_updated_at
  before update on todoist_sync
  for each row execute function update_updated_at();
