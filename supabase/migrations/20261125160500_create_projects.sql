create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  area_m2 numeric not null check (area_m2 > 0),
  created_at timestamptz not null default now()
);

create index if not exists projects_user_created_at_idx
  on public.projects (user_id, created_at desc);

grant select, insert on public.projects to authenticated;

alter table public.projects enable row level security;

create policy "Users can read their own projects"
  on public.projects for select
  using (auth.uid() = user_id);

create policy "Users can create their own projects"
  on public.projects for insert
  with check (auth.uid() = user_id);
