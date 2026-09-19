-- Pallets sobrantes: apartado privado (solo PRIVADO_USUARIO_ID, ver esUsuarioPrivado()
-- en index.html) para cruzar el stock físico sobrante en pallets (no contado en el
-- WMS) contra los productos en faltante neto de Bolsa LATAM — si un SKU coincide,
-- ese stock físico podría usarse para amortizar/disputar el faltante que cobra el
-- auditor. LPN es único por línea del reporte de pallets, se usa para no duplicar.
create table if not exists public.ssoma_pallets_sobrantes (
  id bigint generated always as identity primary key,
  lpn text not null unique,
  sku text not null,
  barra text,
  descripcion text,
  lote text,
  cantidad numeric not null,
  pallet text,
  valor_total numeric,
  status text,
  estado text,
  valor_unitario numeric,
  archivo_origen text,
  creado_por_id bigint,
  created_at timestamptz not null default now()
);

create index if not exists ssoma_pallets_sobrantes_sku_idx on public.ssoma_pallets_sobrantes (sku);

alter table public.ssoma_pallets_sobrantes enable row level security;
drop policy if exists ssoma_pallets_sobrantes_select on public.ssoma_pallets_sobrantes;
create policy ssoma_pallets_sobrantes_select on public.ssoma_pallets_sobrantes for select using (true);
drop policy if exists ssoma_pallets_sobrantes_insert on public.ssoma_pallets_sobrantes;
create policy ssoma_pallets_sobrantes_insert on public.ssoma_pallets_sobrantes for insert with check (true);
drop policy if exists ssoma_pallets_sobrantes_update on public.ssoma_pallets_sobrantes;
create policy ssoma_pallets_sobrantes_update on public.ssoma_pallets_sobrantes for update using (true);
drop policy if exists ssoma_pallets_sobrantes_delete on public.ssoma_pallets_sobrantes;
create policy ssoma_pallets_sobrantes_delete on public.ssoma_pallets_sobrantes for delete using (true);

grant select, insert, update, delete on public.ssoma_pallets_sobrantes to anon, authenticated;
grant usage on sequence ssoma_pallets_sobrantes_id_seq to anon, authenticated;
