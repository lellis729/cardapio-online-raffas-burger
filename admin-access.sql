-- Configure políticas de administração após criar o usuário no Supabase Auth.
-- 1) Execute este arquivo no SQL Editor do Supabase.
-- 2) Cadastre o administrador em public.admin_users usando o UUID do usuário Auth:
--    insert into public.admin_users (user_id) values ('UUID_DO_USUARIO_AUTH');

create sequence if not exists public.products_id_seq;
select setval('public.products_id_seq', coalesce((select max(id) from public.products), 0) + 1, false);
alter table public.products alter column id set default nextval('public.products_id_seq');
grant usage, select on sequence public.products_id_seq to authenticated;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_store_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_store_admin() from public;
grant execute on function public.is_store_admin() to authenticated;

create policy "Admins can read own admin record" on public.admin_users
  for select to authenticated using (user_id = (select auth.uid()));

create policy "Admins manage products" on public.products
  for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());
create policy "Admins read orders" on public.orders
  for select to authenticated using (public.is_store_admin());
create policy "Admins update orders" on public.orders
  for update to authenticated using (public.is_store_admin()) with check (public.is_store_admin());
create policy "Admins read order items" on public.order_items
  for select to authenticated using (public.is_store_admin());

grant select on public.products to authenticated;
grant insert, update, delete on public.products to authenticated;
grant select, update on public.orders to authenticated;
grant select on public.order_items to authenticated;

