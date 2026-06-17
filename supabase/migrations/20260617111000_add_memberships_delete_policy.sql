-- A tabela memberships tinha policies para select/insert/update, mas nenhuma
-- para delete. Com RLS habilitado, isso faz qualquer DELETE afetar 0 linhas
-- silenciosamente (sem erro), o que o app reporta como
-- "Nenhuma assinatura foi excluída" ao cancelar uma assinatura.

drop policy if exists "Clients and shop owners delete memberships" on public.memberships;
create policy "Clients and shop owners delete memberships"
on public.memberships
for delete
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
