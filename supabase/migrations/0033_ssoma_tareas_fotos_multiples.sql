-- ============================================================
-- BLOQUE 33: hasta 5 fotos de evidencia en Designación de Tareas
--
-- archivo_cierre (tareas) y archivo (avances) solo guardaban UN archivo — la
-- evidencia de "Marcar como finalizada" y "Registrar avance de hoy" quedaba
-- limitada a una sola foto (o el documento). Se agrega una columna aparte
-- para el array de fotos (hasta 5), sin tocar archivo_cierre/archivo que
-- siguen siendo el documento único (Excel/Word/PDF) adjunto opcional.
-- ============================================================

alter table ssoma_tareas add column if not exists fotos_cierre jsonb not null default '[]'::jsonb;
alter table ssoma_tareas_avances add column if not exists fotos jsonb not null default '[]'::jsonb;
