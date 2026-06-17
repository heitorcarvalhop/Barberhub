-- A tabela membership_plans aparentemente já existia antes da migration
-- 20260616090000 (criada manualmente ou em script anterior), então o
-- "create table if not exists" daquela migration não adicionou created_at/
-- updated_at. O PostgREST reporta "Could not find the 'updated_at' column"
-- ao tentar atualizar planos. Este ALTER é idempotente e corrige isso
-- independentemente do estado atual da tabela.

alter table public.membership_plans
  add column if not exists created_at timestamptz not null default now();

alter table public.membership_plans
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists membership_plans_set_updated_at on public.membership_plans;
create trigger membership_plans_set_updated_at
before update on public.membership_plans
for each row
execute function public.set_updated_at();

notify pgrst, 'reload schema';
