-- Charla de 5 Minutos: agrega el turno al que corresponde la charla (mismo
-- enum ssoma_turno ya usado en Comportamental). Nullable porque las charlas
-- ya cargadas no lo tienen — queda vacío para esas, obligatorio solo para
-- las nuevas (se valida en el formulario, no acá).
alter table ssoma_charlas_5min add column if not exists turno ssoma_turno;
