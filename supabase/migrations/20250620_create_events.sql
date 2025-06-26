-- Create events table
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  location text,
  description text,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.events enable row level security;

-- Policy: users can manage their events
create policy "Users can manage their events"
  on public.events
  for all
  using (auth.uid() = user_id);
