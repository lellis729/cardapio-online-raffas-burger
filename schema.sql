create extension if not exists pgcrypto;

create sequence if not exists public.products_id_seq;

create table if not exists public.products (
  id bigint primary key default nextval('public.products_id_seq'),
  name text not null,
  category text not null,
  description text not null default '',
  price numeric(10,2) not null check (price >= 0),
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  fulfillment_type text not null check (fulfillment_type in ('Entrega', 'Retirada')),
  address text,
  payment_method text not null,
  notes text,
  status text not null default 'novo' check (status in ('novo', 'confirmado', 'preparando', 'saiu_entrega', 'concluido', 'cancelado')),
  total numeric(10,2) not null check (total >= 0),
  created_at timestamptz not null default now(),
  check (fulfillment_type <> 'Entrega' or nullif(trim(address), '') is not null)
);

create table if not exists public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id bigint references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(10,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  line_total numeric(10,2) not null check (line_total >= 0)
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists order_items_order_id_idx on public.order_items (order_id);

select setval('public.products_id_seq', coalesce((select max(id) from public.products), 0) + 1, false);
grant usage, select on sequence public.products_id_seq to anon, authenticated;

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Cardápio público: leitura dos produtos ativos.
create policy "Public can read active products" on public.products
  for select to anon using (active = true);

-- O checkout do site envia pedidos anonimamente. Limite as colunas/dados coletados
-- e use uma Edge Function com validação e rate limit antes de produção.
create policy "Public can create orders" on public.orders
  for insert to anon with check (status = 'novo');
create policy "Public can create order items" on public.order_items
  for insert to anon with check (true);

-- Os pedidos não ficam disponíveis para leitura pública. Consulte-os no painel
-- autenticado do Supabase até ser criado um painel administrativo com autenticação.

