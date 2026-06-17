-- Mesma causa da migration anterior (fix_membership_plans_columns): a tabela
-- memberships também já existia antes de 20260616090000, então o
-- "create table if not exists" não adicionou created_at/updated_at. O
-- trigger memberships_set_updated_at (que já existe) tenta gravar
-- NEW.updated_at em toda atualização e falha com
-- "record 'new' has no field 'updated_at'" (42703) — é isso que trava
-- pausar/cancelar/reativar assinatura. ALTER idempotente corrige.

alter table public.memberships
  add column if not exists created_at timestamptz not null default now();

alter table public.memberships
  add column if not exists updated_at timestamptz not null default now();

notify pgrst, 'reload schema';
