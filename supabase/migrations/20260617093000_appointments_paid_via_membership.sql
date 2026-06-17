alter table public.appointments
  add column if not exists paid_via_membership boolean not null default false;
