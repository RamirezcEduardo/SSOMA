-- ============================================================
-- BLOQUE 7: Agrega supervisor a la encuesta de clima laboral
--
-- Pedido explícito del usuario: poder sacar métricas por
-- supervisor/área para detectar si un problema de clima viene
-- del liderazgo directo, no solo del área en general.
--
-- Nota de anonimato (ya conversada): esto reduce el anonimato
-- real en equipos chicos (supervisor + turno + un comentario
-- pueden acotar bastante quién respondió). La tabla sigue sin
-- policy de SELECT para anon/authenticated, así que nadie puede
-- consultarla desde el navegador — solo por SQL Editor/dashboard
-- con acceso al proyecto. Si más adelante se construye un reporte
-- agregado, se recomienda no mostrar resultados por supervisor
-- con menos de ~5 respuestas, para no exponer casos aislados.
-- ============================================================

alter table ssoma_encuesta_clima
  add column if not exists supervisor_id bigint references ssoma_personal (id);

alter table ssoma_encuesta_clima
  alter column supervisor_id set not null;

comment on column ssoma_encuesta_clima.supervisor_id is 'Supervisor evaluado (de ssoma_personal, puede_supervisar=true). Requerido para poder sacar métricas por supervisor/área.';
