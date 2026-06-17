create table if not exists public.ai_settings (
  id boolean primary key default true,
  api_key text not null default '',
  model text not null default 'llama-3.1-8b-instant',
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  constraint ai_settings_singleton check (id)
);

insert into public.ai_settings (id) values (true)
on conflict (id) do nothing;

drop trigger if exists ai_settings_set_updated_at on public.ai_settings;
create trigger ai_settings_set_updated_at
before update on public.ai_settings
for each row
execute function public.set_updated_at();

alter table public.ai_settings enable row level security;

drop policy if exists "Anyone authenticated can read AI settings" on public.ai_settings;
create policy "Anyone authenticated can read AI settings"
on public.ai_settings
for select
to authenticated
using (true);

drop policy if exists "Only admin can update AI settings" on public.ai_settings;
create policy "Only admin can update AI settings"
on public.ai_settings
for update
to authenticated
using (
  exists (
    select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.role = 'admin'
  )
);
