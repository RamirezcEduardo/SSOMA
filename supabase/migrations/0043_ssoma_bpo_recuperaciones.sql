-- ============================================================
-- BLOQUE 43: Bultos Pendientes de Operación — checklist de recuperación
--
-- Los "Perdidos" y "Sin Ubicación" cargados en Bultos Pendientes de
-- Operación ahora se resuelven como checklist dentro de "Auditoría de
-- Inventario" (pestañas Bultos Perdidos / Sin Ubicación): el operador
-- reporta UNIDADES encontradas (no montos) — puede ser el total o una
-- parte (menos o más de lo pendiente) — y el valor se calcula solo con
-- el valor unitario (Val tot ÷ Cantidad actual).
--
-- unidades_recuperadas es el acumulado en ssoma_bpo_registros (cache
-- rápido para listar/filtrar); ssoma_bpo_recuperaciones es la bitácora
-- de cada reporte individual (unidades, valor, área opcional, foto
-- opcional) — igual patrón que registros/verificaciones de Shortpick.
-- ============================================================

alter table ssoma_bpo_registros add column if not exists unidades_recuperadas numeric not null default 0;

alter table ssoma_bpo_registros drop constraint if exists ssoma_bpo_registros_estado_check;
alter table ssoma_bpo_registros add constraint ssoma_bpo_registros_estado_check
  check (estado in ('pendiente', 'parcial', 'recuperado'));

comment on column ssoma_bpo_registros.unidades_recuperadas is 'Acumulado de unidades reportadas como encontradas (ver ssoma_bpo_recuperaciones para el detalle de cada reporte). estado pasa a "parcial" mientras 0 < unidades_recuperadas < cantidad_actual, y a "recuperado" cuando llega o supera cantidad_actual.';

create table if not exists ssoma_bpo_recuperaciones (
  id                bigint generated always as identity primary key,
  registro_id       bigint not null references ssoma_bpo_registros (id) on delete cascade,

  unidades          numeric not null,
  valor             numeric not null,
  area_encontrado   text,
  foto              jsonb,

  reportado_por_id  bigint,
  creado_en         timestamptz not null default now()
);

comment on table ssoma_bpo_recuperaciones is 'Bitácora de cada reporte de recuperación (total o parcial) sobre un bulto de ssoma_bpo_registros — unidades y valor de ESE reporte puntual, no el acumulado.';

alter table ssoma_bpo_recuperaciones enable row level security;

create policy ssoma_bpo_recuperaciones_select on ssoma_bpo_recuperaciones
  for select to anon, authenticated using (true);
create policy ssoma_bpo_recuperaciones_insert on ssoma_bpo_recuperaciones
  for insert to anon, authenticated with check (true);
create policy ssoma_bpo_recuperaciones_update on ssoma_bpo_recuperaciones
  for update to anon, authenticated using (true);
create policy ssoma_bpo_recuperaciones_delete on ssoma_bpo_recuperaciones
  for delete to anon, authenticated using (true);
