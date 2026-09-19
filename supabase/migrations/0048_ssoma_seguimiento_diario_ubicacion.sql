-- ============================================================
-- BLOQUE 48: Seguimiento Diario — agrupar por Proceso + Ubicación
--
-- Con miles de LPN pendientes (ej. 9,266), renderizar una tarjeta por
-- cada uno hacía el apartado muy lento. El reporte "Pendientes de
-- Operación" sí trae una columna Ubicacion para estos procesos (a
-- diferencia de Perdido ERU/Por Ubicar, que no la traen — por eso no
-- se había importado antes). Agrupando por Proceso + Ubicación, miles
-- de LPN se reducen a un puñado de tarjetas (ej. 23 en vez de 8,554),
-- cada una con el total valorizado y los productos involucrados, y el
-- supervisor puede finalizar todo el grupo de una vez, con un
-- comentario, en vez de LPN por LPN.
-- ============================================================

alter table ssoma_seguimiento_diario_registros add column if not exists ubicacion text;
alter table ssoma_seguimiento_diario_registros add column if not exists comentario text;

comment on column ssoma_seguimiento_diario_registros.ubicacion is 'Columna Ubicacion del reporte "Pendientes de Operación" — junto con proceso, define el grupo que se finaliza de una sola vez en la app.';
comment on column ssoma_seguimiento_diario_registros.comentario is 'Comentario opcional que el supervisor deja al finalizar el grupo (Proceso + Ubicación) al que pertenece este LPN.';
