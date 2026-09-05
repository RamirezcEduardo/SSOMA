-- ============================================================
-- BLOQUE 35: metadatos livianos para la evidencia de Tareas — separados
-- del contenido pesado (fotos/documentos en base64)
--
-- trLoadTareas() recargaba archivo_cierre/fotos_cierre (y archivo/fotos de
-- avances) completos — con las fotos en base64 adentro — en CADA carga de
-- la lista, incluyendo cada vez que la app vuelve a primer plano
-- (visibilitychange). Eso multiplicaba el tráfico real muchísimas veces
-- por sesión y fue lo que agotó la cuota de egress del plan gratuito.
--
-- Se agregan columnas livianas (nombre del archivo, cantidad de fotos) que
-- la lista puede usar para mostrar los chips de evidencia sin traer el
-- contenido en sí. El contenido completo (archivo_cierre/fotos_cierre) se
-- sigue guardando igual, pero ahora solo se trae bajo demanda al abrir
-- "Ver informe" de una tarea puntual.
-- ============================================================

alter table ssoma_tareas add column if not exists archivo_cierre_nombre text;
alter table ssoma_tareas add column if not exists fotos_cierre_count integer not null default 0;

alter table ssoma_tareas_avances add column if not exists archivo_nombre text;
alter table ssoma_tareas_avances add column if not exists fotos_count integer not null default 0;

update ssoma_tareas
  set archivo_cierre_nombre = archivo_cierre->>'nombre'
  where archivo_cierre is not null and archivo_cierre_nombre is null;

update ssoma_tareas
  set fotos_cierre_count = jsonb_array_length(fotos_cierre)
  where fotos_cierre is not null and fotos_cierre_count = 0;

update ssoma_tareas_avances
  set archivo_nombre = archivo->>'nombre'
  where archivo is not null and archivo_nombre is null;

update ssoma_tareas_avances
  set fotos_count = jsonb_array_length(fotos)
  where fotos is not null and fotos_count = 0;
