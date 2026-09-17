-- ============================================================
-- BLOQUE 57: Inbound Solicitudes/OT — vincular Nro LPN del WMS
--
-- Primer paso real hacia el cruce con el WMS (bloques 55/56 lo dejaron
-- pendiente de definir): el usuario copia los N° de O/C pendientes
-- (cuadro agregado en el bloque anterior), los busca en el WMS y baja
-- un reporte con columnas "Nro LPN", "Nro OC" y "Cod Alternat". Ese
-- reporte se sube acá y se cruza por O/C + Cod Alternat JUNTOS (nunca
-- solo por O/C) para guardar qué LPN(s) le tocaron a cada producto —
-- una misma O/C puede traer varios Cod Alternat distintos, y cruzar
-- solo por O/C traería LPN de un producto que no es.
--
-- El WMS le agrega siempre un prefijo de 3 letras al N° de O/C (ej.
-- "IMP1000413918" o "UVF1000413918" para nuestra O/C "1000413918") —
-- se le quita el prefijo antes de comparar, en el JS de importación.
-- Una misma O/C + Cod Alternat puede traer más de un LPN (varios
-- bultos/pallets), así que se guardan todos separados por coma.
-- ============================================================

alter table ssoma_inbound_solicitudes_ot add column if not exists lpn_vinculados text;
alter table ssoma_inbound_solicitudes_ot add column if not exists lpn_vinculado_en timestamptz;
alter table ssoma_inbound_solicitudes_ot add column if not exists lpn_vinculado_por_id bigint;

comment on column ssoma_inbound_solicitudes_ot.lpn_vinculados is 'Nro(s) de LPN del WMS vinculados a esta fila (separados por coma) — cruce estricto por Nro OC (quitando el prefijo de 3 letras que le agrega el WMS: IMP/UVF/etc) MAS Cod Alternat/Cod Producto juntos, nunca solo por O/C, para no traer LPN de otro producto de la misma O/C. Todavía no determina el estado (pendiente/finalizado), solo asocia el dato.';
