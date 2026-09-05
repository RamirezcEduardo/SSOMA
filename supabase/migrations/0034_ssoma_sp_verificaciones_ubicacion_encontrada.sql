-- ============================================================
-- BLOQUE 34: describir dónde se encontró (Shortpick) — la foto deja de ser obligatoria
--
-- Al marcar "En otra ubicación" en Conciliación Shortpick, antes era obligatorio subir
-- una foto y no había forma de simplemente escribir dónde apareció (igual que ya se
-- podía hacer en Sin Ubicación, con ubicacion_encontrada). Se agrega la misma columna
-- acá — ahora la foto es evidencia opcional, pero describir la ubicación real es
-- obligatorio cuando no fue en la ubicación indicada por el WMS.
-- ============================================================

alter table ssoma_sp_verificaciones add column if not exists ubicacion_encontrada text;
