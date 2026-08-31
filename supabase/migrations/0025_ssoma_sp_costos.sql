-- Catálogo de costos de Auditoría Shortpick (hoja VALOR de la plantilla SP_DIARIO):
-- permite calcular el "Valorizado" real (costo * unidades ajustadas) al importar,
-- en vez de depender de una tabla de ejemplo hardcodeada en el cliente.
create table if not exists public.ssoma_sp_costos (
  cod_alternat text primary key,
  producto text,
  costo numeric,
  familia text,
  updated_at timestamptz not null default now()
);

alter table public.ssoma_sp_costos enable row level security;
drop policy if exists ssoma_sp_costos_select on public.ssoma_sp_costos;
create policy ssoma_sp_costos_select on public.ssoma_sp_costos for select using (true);
drop policy if exists ssoma_sp_costos_insert on public.ssoma_sp_costos;
create policy ssoma_sp_costos_insert on public.ssoma_sp_costos for insert with check (true);
drop policy if exists ssoma_sp_costos_update on public.ssoma_sp_costos;
create policy ssoma_sp_costos_update on public.ssoma_sp_costos for update using (true);
drop policy if exists ssoma_sp_costos_delete on public.ssoma_sp_costos;
create policy ssoma_sp_costos_delete on public.ssoma_sp_costos for delete using (true);

grant select, insert, update, delete on public.ssoma_sp_costos to anon, authenticated;

-- Nota: la carga inicial (~45k SKUs, tomada de la hoja VALOR de la plantilla real que
-- compartió el usuario) se hizo aparte con inserts en lote, no como parte de esta
-- migración, para no commitear varios MB de datos al repo. Se actualiza luego desde
-- la app con "Actualizar catálogo de costos" (solo administradores).
