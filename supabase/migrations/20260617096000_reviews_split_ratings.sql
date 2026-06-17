alter table public.reviews
  add column if not exists barbershop_rating integer,
  add column if not exists barber_rating integer;

update public.reviews
set barbershop_rating = coalesce(barbershop_rating, rating),
    barber_rating = coalesce(barber_rating, rating)
where rating is not null;

update public.reviews
set barbershop_rating = coalesce(barbershop_rating, 5),
    barber_rating = coalesce(barber_rating, 5)
where barbershop_rating is null or barber_rating is null;

alter table public.reviews
  alter column barbershop_rating set not null,
  alter column barber_rating set not null;

alter table public.reviews
  drop constraint if exists reviews_rating_check;

alter table public.reviews
  add constraint reviews_barbershop_rating_check
    check (barbershop_rating between 1 and 5),
  add constraint reviews_barber_rating_check
    check (barber_rating between 1 and 5);

-- A coluna "rating" NÃO é removida: a view "barbershop_review_stats" (criada fora
-- destas migrations) depende dela. O app não lê/escreve mais "rating" — por isso
-- ela deixa de ser obrigatória, para não bloquear novos inserts.
alter table public.reviews alter column rating drop not null;

-- Mantém "rating" preenchido automaticamente (espelhando barbershop_rating) para
-- a view legada continuar funcionando mesmo sem o app gravar essa coluna.
create or replace function public.sync_legacy_review_rating()
returns trigger
language plpgsql
as $$
begin
  new.rating = new.barbershop_rating;
  return new;
end;
$$;

drop trigger if exists reviews_sync_legacy_rating on public.reviews;
create trigger reviews_sync_legacy_rating
before insert or update on public.reviews
for each row
execute function public.sync_legacy_review_rating();
