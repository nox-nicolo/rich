-- RICH device sync.
--
-- Enable anonymous sign-ins in Supabase Auth if you want the app to create a
-- per-install user automatically. For a real account system later, keep this
-- same table and sign users in with email/password instead.

create table if not exists public.rich_sync_records (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  inserted_at timestamptz not null default now(),
  primary key (user_id, entity_type, entity_id)
);

create index if not exists rich_sync_records_user_updated_idx
  on public.rich_sync_records (user_id, updated_at);

alter table public.rich_sync_records enable row level security;

create policy "Users can read their own sync records"
  on public.rich_sync_records
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own sync records"
  on public.rich_sync_records
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own sync records"
  on public.rich_sync_records
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
