-- Auditoría Shortpick: registros reales importados del WMS y verificaciones
-- físicas de conciliación. Reemplaza la maqueta con datos de ejemplo (spData
-- y verificaciones en memoria en index.html) por persistencia real.

create table if not exists public.ssoma_sp_registros (
  id bigint generated always as identity primary key,
  fecha timestamptz not null,
  cod_alternat text not null,
  codigo_barras text,
  producto text,
  descripcion text not null,
  ubicacion text not null,
  subarea text,
  turno text,
  responsable text,
  supervisor text,
  orden text,
  un_ajust integer not null,
  semana text,
  estado text,
  valorizado numeric,
  creado_por_id bigint,
  created_at timestamptz not null default now()
);

create index if not exists ssoma_sp_registros_fecha_idx on public.ssoma_sp_registros (fecha);

alter table public.ssoma_sp_registros enable row level security;
drop policy if exists ssoma_sp_registros_select on public.ssoma_sp_registros;
create policy ssoma_sp_registros_select on public.ssoma_sp_registros for select using (true);
drop policy if exists ssoma_sp_registros_insert on public.ssoma_sp_registros;
create policy ssoma_sp_registros_insert on public.ssoma_sp_registros for insert with check (true);
drop policy if exists ssoma_sp_registros_update on public.ssoma_sp_registros;
create policy ssoma_sp_registros_update on public.ssoma_sp_registros for update using (true);
drop policy if exists ssoma_sp_registros_delete on public.ssoma_sp_registros;
create policy ssoma_sp_registros_delete on public.ssoma_sp_registros for delete using (true);

grant select, insert, update, delete on public.ssoma_sp_registros to anon, authenticated;
grant usage on sequence ssoma_sp_registros_id_seq to anon, authenticated;

create table if not exists public.ssoma_sp_verificaciones (
  id bigint generated always as identity primary key,
  registro_id bigint not null references public.ssoma_sp_registros(id) on delete cascade,
  estado text not null check (estado in ('completo','parcial')),
  cantidad_encontrada integer not null,
  otra_ubicacion boolean not null default false,
  foto jsonb,
  verificado_por_id bigint,
  fecha timestamptz not null default now(),
  unique(registro_id)
);

alter table public.ssoma_sp_verificaciones enable row level security;
drop policy if exists ssoma_sp_verificaciones_select on public.ssoma_sp_verificaciones;
create policy ssoma_sp_verificaciones_select on public.ssoma_sp_verificaciones for select using (true);
drop policy if exists ssoma_sp_verificaciones_insert on public.ssoma_sp_verificaciones;
create policy ssoma_sp_verificaciones_insert on public.ssoma_sp_verificaciones for insert with check (true);
drop policy if exists ssoma_sp_verificaciones_update on public.ssoma_sp_verificaciones;
create policy ssoma_sp_verificaciones_update on public.ssoma_sp_verificaciones for update using (true);
drop policy if exists ssoma_sp_verificaciones_delete on public.ssoma_sp_verificaciones;
create policy ssoma_sp_verificaciones_delete on public.ssoma_sp_verificaciones for delete using (true);

grant select, insert, update, delete on public.ssoma_sp_verificaciones to anon, authenticated;
grant usage on sequence ssoma_sp_verificaciones_id_seq to anon, authenticated;
