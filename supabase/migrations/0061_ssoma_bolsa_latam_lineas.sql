-- Bolsa LATAM: cada fila es una transacción real del reporte del auditor LATAM
-- (Cant Reversada = -CANTIDAD, monto reversado = Cant Reversada * costo). Negativo
-- neto acumulado por Código Alterno = faltante (te lo cobran); positivo = sobrante
-- a revisar. Se acumula import tras import — fila_hash evita duplicar la misma
-- transacción si el mismo periodo se vuelve a subir en un archivo posterior.
create table if not exists public.ssoma_bolsa_latam_lineas (
  id bigint generated always as identity primary key,
  fecha date not null,
  cod_alternat text not null,
  producto text,
  cantidad numeric,
  costo_unit numeric,
  trans_ref text,
  trans_user text,
  familia text,
  ubicacion text,
  area text,
  origen text,
  tipo text,
  motivo_op text,
  mes text,
  semana text,
  observacion text,
  gestion text,
  cant_reversada numeric not null,
  monto_reversado numeric not null,
  fila_hash text not null unique,
  archivo_origen text,
  creado_por_id bigint,
  created_at timestamptz not null default now()
);

create index if not exists ssoma_bolsa_latam_lineas_cod_idx on public.ssoma_bolsa_latam_lineas (cod_alternat);
create index if not exists ssoma_bolsa_latam_lineas_fecha_idx on public.ssoma_bolsa_latam_lineas (fecha);
create index if not exists ssoma_bolsa_latam_lineas_semana_idx on public.ssoma_bolsa_latam_lineas (semana);

alter table public.ssoma_bolsa_latam_lineas enable row level security;
drop policy if exists ssoma_bolsa_latam_lineas_select on public.ssoma_bolsa_latam_lineas;
create policy ssoma_bolsa_latam_lineas_select on public.ssoma_bolsa_latam_lineas for select using (true);
drop policy if exists ssoma_bolsa_latam_lineas_insert on public.ssoma_bolsa_latam_lineas;
create policy ssoma_bolsa_latam_lineas_insert on public.ssoma_bolsa_latam_lineas for insert with check (true);
drop policy if exists ssoma_bolsa_latam_lineas_update on public.ssoma_bolsa_latam_lineas;
create policy ssoma_bolsa_latam_lineas_update on public.ssoma_bolsa_latam_lineas for update using (true);
drop policy if exists ssoma_bolsa_latam_lineas_delete on public.ssoma_bolsa_latam_lineas;
create policy ssoma_bolsa_latam_lineas_delete on public.ssoma_bolsa_latam_lineas for delete using (true);

grant select, insert, update, delete on public.ssoma_bolsa_latam_lineas to anon, authenticated;
grant usage on sequence ssoma_bolsa_latam_lineas_id_seq to anon, authenticated;
