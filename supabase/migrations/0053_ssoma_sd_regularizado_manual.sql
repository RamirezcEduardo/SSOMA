-- ============================================================
-- BLOQUE 53: Seguimiento Diario — agregar/quitar LPN a mano
--
-- Además de lo que trae el import y la auto-regularización por
-- comparación de archivo, el equipo necesita poder:
--   1) Agregar un LPN suelto que notan que falta (con su valorizado),
--      sin esperar al próximo import.
--   2) Quitar (dar de baja) uno o varios LPN a mano cuando saben que
--      ya no están pendientes, sin depender de que el archivo del día
--      los excluya (evita marcar de más si suben solo un avance parcial).
--
-- "regularizado_manual" se distingue de "regularizado_auto" (detectado
-- comparando archivos) para que quede claro en los reportes que fue una
-- decisión humana, no del import.
-- ============================================================

alter table ssoma_seguimiento_diario_registros drop constraint if exists ssoma_seguimiento_diario_registros_estado_check;
alter table ssoma_seguimiento_diario_registros add constraint ssoma_seguimiento_diario_registros_estado_check
  check (estado in ('pendiente', 'finalizado', 'regularizado_auto', 'regularizado_manual'));

alter table ssoma_seguimiento_diario_registros add column if not exists regularizado_por_id bigint;

comment on column ssoma_seguimiento_diario_registros.estado is 'pendiente hasta que: se finaliza a mano (finalizado), un import detecta que el LPN ya no aparece en su Proceso+Ubicación (regularizado_auto), o el equipo lo quita a mano desde "Quitar LPNs" (regularizado_manual).';
comment on column ssoma_seguimiento_diario_registros.regularizado_por_id is 'Quién quitó el LPN a mano con "Quitar LPNs" (b2c_users.id) — null si fue automático (regularizado_auto) o si nunca se regularizó.';
