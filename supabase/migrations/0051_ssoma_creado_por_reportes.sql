-- ============================================================
-- BLOQUE 51: Trazabilidad de carga en los reportes exportados
--
-- ssoma_sp_registros ya tenía creado_por_id/created_at (Shortpick). Los
-- demás módulos que se cargan por Excel (Bultos Perdidos/Sin Ubicación,
-- Seguimiento Diario, Control de Bolsa) no guardaban quién subió cada
-- fila — solo el nombre del archivo. Se agrega creado_por_id para poder
-- mostrar "Cargado por" y "Fecha y hora de carga" (created_at, ya
-- existente) en los reportes CSV de cada módulo.
-- ============================================================

alter table ssoma_bpo_registros add column if not exists creado_por_id bigint;
alter table ssoma_seguimiento_diario_registros add column if not exists creado_por_id bigint;
alter table ssoma_bolsa_auditoria_lineas add column if not exists creado_por_id bigint;
alter table ssoma_bolsa_wms_lineas add column if not exists creado_por_id bigint;

comment on column ssoma_bpo_registros.creado_por_id is 'Quién subió el archivo que trajo esta fila (b2c_users.id) — null en filas cargadas antes de este cambio.';
comment on column ssoma_seguimiento_diario_registros.creado_por_id is 'Quién subió el archivo que trajo esta fila (b2c_users.id) — null en filas cargadas antes de este cambio.';
comment on column ssoma_bolsa_auditoria_lineas.creado_por_id is 'Quién subió el archivo que trajo esta fila (b2c_users.id) — null en filas cargadas antes de este cambio.';
comment on column ssoma_bolsa_wms_lineas.creado_por_id is 'Quién subió el archivo que trajo esta fila (b2c_users.id) — null en filas cargadas antes de este cambio.';
