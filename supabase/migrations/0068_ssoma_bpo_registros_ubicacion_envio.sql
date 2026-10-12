-- Sin Ubicación: ubicación de origen desde donde se envió el bulto a Sin
-- Ubicación. Se vincula por Nro Grupo (ya guardado en nro_grupo desde
-- "Vincular Nro Grupo") contra el export "Historial de actividad" filtrado a
-- "4 - Inventory Adjusted pre verification", que trae Nro Grupo + Ubicacion
-- pero NO Nro LPN — por eso el cruce es en dos pasos: LPN -> Nro Grupo (ya
-- resuelto) -> Ubicación de envío (este archivo).
alter table public.ssoma_bpo_registros add column if not exists ubicacion_envio text;
