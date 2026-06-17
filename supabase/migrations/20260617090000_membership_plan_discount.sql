alter table public.membership_plans
  add column if not exists product_discount_percent integer not null default 0;

update public.membership_plans
set product_discount_percent = 10
where tier = 'basic' and product_discount_percent = 0;

update public.membership_plans
set product_discount_percent = 20
where tier = 'premium' and product_discount_percent = 0;

update public.membership_plans
set product_discount_percent = 30
where tier = 'vip' and product_discount_percent = 0;
