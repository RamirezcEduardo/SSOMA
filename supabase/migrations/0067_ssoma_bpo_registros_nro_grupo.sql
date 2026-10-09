-- Sin Ubicación: Nro Grupo del WMS (de la fila "29 - Create Allocatable
-- Container" del export "Historial de actividad"), vinculado por Nro LPN desde
-- el botón "Vincular Nro Grupo" — se guarda para que se vea en la tarjeta del
-- checklist, no solo en el cuadro de copiar/pegar.
alter table public.ssoma_bpo_registros add column if not exists nro_grupo text;
