create table if not exists public.reviews (
  id text primary key default gen_random_uuid()::text,
  appointment_id text not null unique references public.appointments(id) on delete cascade,
  client_id uuid not null,
  client_name text not null,
  barbershop_id text not null references public.barbershops(id) on delete cascade,
  barbershop_name text not null,
  barber_id text not null references public.barbers(id) on delete cascade,
  barber_name text not null,
  service_name text not null,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists reviews_barbershop_id_idx on public.reviews(barbershop_id);
create index if not exists reviews_barber_id_idx on public.reviews(barber_id);
create index if not exists reviews_client_id_idx on public.reviews(client_id);

alter table public.reviews enable row level security;

drop policy if exists "Anyone authenticated can read reviews" on public.reviews;
create policy "Anyone authenticated can read reviews"
on public.reviews
for select
to authenticated
using (true);

drop policy if exists "Clients create their own reviews" on public.reviews;
create policy "Clients create their own reviews"
on public.reviews
for insert
to authenticated
with check (
  auth.uid() = client_id
  and exists (
    select 1
    from public.appointments appt
    where appt.id = public.reviews.appointment_id
      and appt.client_id = auth.uid()::text
      and appt.status = 'completed'
  )
);
