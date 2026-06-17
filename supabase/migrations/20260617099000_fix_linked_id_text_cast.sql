-- Corrige um erro de tipo nas policies criadas em 2026-06-11/12: "profile.linked_id"
-- é uuid e estava sendo comparado com um valor convertido só de um lado
-- (`profile.linked_id = x.coluna::text`), o que o Postgres rejeita com
-- "operator does not exist: text = uuid" / "uuid = text".
-- Esta migration recria as mesmas policies comparando os dois lados como text.

-- ── barbershops (configurações da própria barbearia) ─────────────────────────
drop policy if exists "Barbershop owners can update own settings" on public.barbershops;
create policy "Barbershop owners can update own settings"
on public.barbershops
for update
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
          and profile.linked_id::text = public.barbershops.id::text
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
          and profile.linked_id::text = public.barbershops.id::text
        )
      )
  )
);

-- ── services ──────────────────────────────────────────────────────────────────
drop policy if exists "Barbershop owners can insert own services" on public.services;
create policy "Barbershop owners can insert own services"
on public.services
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.services.barbershop_id::text
        )
      )
  )
);

drop policy if exists "Barbershop owners can update own services" on public.services;
create policy "Barbershop owners can update own services"
on public.services
for update
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
          and profile.linked_id::text = public.services.barbershop_id::text
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
          and profile.linked_id::text = public.services.barbershop_id::text
        )
      )
  )
);

-- ── barbers ───────────────────────────────────────────────────────────────────
drop policy if exists "Barbershop owners can insert own barbers" on public.barbers;
create policy "Barbershop owners can insert own barbers"
on public.barbers
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.barbers.barbershop_id::text
        )
      )
  )
);

drop policy if exists "Barbershop owners can update own barbers" on public.barbers;
create policy "Barbershop owners can update own barbers"
on public.barbers
for update
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
          and profile.linked_id::text = public.barbers.barbershop_id::text
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
          and profile.linked_id::text = public.barbers.barbershop_id::text
        )
      )
  )
);

-- ── products ──────────────────────────────────────────────────────────────────
drop policy if exists "Barbershop owners can insert own products" on public.products;
create policy "Barbershop owners can insert own products"
on public.products
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and (
        profile.role = 'admin'
        or (
          profile.role = 'barberShop'
          and profile.linked_id::text = public.products.barbershop_id::text
        )
      )
  )
);

drop policy if exists "Barbershop owners can update own products" on public.products;
create policy "Barbershop owners can update own products"
on public.products
for update
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
          and profile.linked_id::text = public.products.barbershop_id::text
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
          and profile.linked_id::text = public.products.barbershop_id::text
        )
      )
  )
);
