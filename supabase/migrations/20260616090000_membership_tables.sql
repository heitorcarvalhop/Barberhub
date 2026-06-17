create table if not exists public.membership_plans (
  id text primary key default gen_random_uuid()::text,
  barbershop_id text not null references public.barbershops(id) on delete cascade,
  tier text not null check (tier in ('basic', 'premium', 'vip')),
  name text not null,
  price_monthly numeric(10, 2) not null default 0,
  cuts_per_month integer,
  includes_beard boolean not null default false,
  priority_booking boolean not null default false,
  benefits text[] not null default '{}'::text[],
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.memberships (
  id text primary key default gen_random_uuid()::text,
  client_id uuid not null,
  client_name text not null,
  barbershop_id text not null references public.barbershops(id) on delete cascade,
  plan_id text not null references public.membership_plans(id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'paused', 'cancelled', 'expired')),
  start_date timestamptz not null default now(),
  next_billing_date timestamptz not null,
  cuts_used_this_month integer not null default 0,
  renewal_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists memberships_client_id_idx on public.memberships(client_id);
create index if not exists memberships_barbershop_id_idx on public.memberships(barbershop_id);
create index if not exists membership_plans_barbershop_id_idx on public.membership_plans(barbershop_id);

drop trigger if exists membership_plans_set_updated_at on public.membership_plans;
create trigger membership_plans_set_updated_at
before update on public.membership_plans
for each row
execute function public.set_updated_at();

drop trigger if exists memberships_set_updated_at on public.memberships;
create trigger memberships_set_updated_at
before update on public.memberships
for each row
execute function public.set_updated_at();

alter table public.membership_plans enable row level security;
alter table public.memberships enable row level security;

-- ── membership_plans ─────────────────────────────────────────────────────────

drop policy if exists "Anyone authenticated can read membership plans" on public.membership_plans;
create policy "Anyone authenticated can read membership plans"
on public.membership_plans
for select
to authenticated
using (true);

drop policy if exists "Barbershop owners manage own membership plans" on public.membership_plans;
create policy "Barbershop owners manage own membership plans"
on public.membership_plans
for all
to authenticated
using (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.membership_plans.barbershop_id::text
        )
      )
  )
)
with check (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.membership_plans.barbershop_id::text
        )
      )
  )
);

-- ── memberships ──────────────────────────────────────────────────────────────

drop policy if exists "Clients read own memberships" on public.memberships;
create policy "Clients read own memberships"
on public.memberships
for select
to authenticated
using (
  auth.uid() = client_id
  or exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.memberships.barbershop_id::text
        )
      )
  )
);

drop policy if exists "Clients create own memberships" on public.memberships;
create policy "Clients create own memberships"
on public.memberships
for insert
to authenticated
with check (auth.uid() = client_id);

drop policy if exists "Clients and shop owners update memberships" on public.memberships;
create policy "Clients and shop owners update memberships"
on public.memberships
for update
to authenticated
using (
  auth.uid() = client_id
  or exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.memberships.barbershop_id::text
        )
      )
  )
)
with check (
  auth.uid() = client_id
  or exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.memberships.barbershop_id::text
        )
      )
  )
);

-- ── Seed: cada barbearia existente recebe os 3 planos padrão (Basic/Premium/VIP) ──

insert into public.membership_plans
  (barbershop_id, tier, name, price_monthly, cuts_per_month, includes_beard, priority_booking, benefits)
select
  b.id, 'basic', 'Basic', 49.90, 2, false, false,
  array['2 cortes por mês incluídos', '10% de desconto em produtos', 'Agendamento facilitado pelo app', 'Histórico completo de visitas']
from public.barbershops b
where not exists (
  select 1 from public.membership_plans mp
  where mp.barbershop_id = b.id and mp.tier = 'basic'
);

insert into public.membership_plans
  (barbershop_id, tier, name, price_monthly, cuts_per_month, includes_beard, priority_booking, benefits)
select
  b.id, 'premium', 'Premium', 89.90, null, true, false,
  array['Cortes ilimitados no mês', 'Barba incluída sem custo extra', '20% de desconto em produtos', 'Agendamento facilitado pelo app', 'Notificação antecipada de horários']
from public.barbershops b
where not exists (
  select 1 from public.membership_plans mp
  where mp.barbershop_id = b.id and mp.tier = 'premium'
);

insert into public.membership_plans
  (barbershop_id, tier, name, price_monthly, cuts_per_month, includes_beard, priority_booking, benefits)
select
  b.id, 'vip', 'VIP', 129.90, null, true, true,
  array['Cortes + Barba ilimitados', 'Prioridade no agendamento', '30% de desconto em produtos', 'Atendimento exclusivo sem fila', 'Brinde mensal surpresa', 'Acesso antecipado a novidades']
from public.barbershops b
where not exists (
  select 1 from public.membership_plans mp
  where mp.barbershop_id = b.id and mp.tier = 'vip'
);
