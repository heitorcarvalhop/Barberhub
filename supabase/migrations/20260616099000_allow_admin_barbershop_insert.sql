drop policy if exists "Admin can create barbershops" on public.barbershops;
create policy "Admin can create barbershops"
on public.barbershops
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and profile.role = 'admin'
  )
);
