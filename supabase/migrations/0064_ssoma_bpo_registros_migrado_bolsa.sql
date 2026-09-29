-- Bultos Perdidos/Sin Ubicación: permite marcar un pendiente como "migrado a
-- bolsa" (se da por perdido y pasa a Control de Bolsa, solo como dato
-- informativo del checklist) además de "pendiente"/"parcial"/"recuperado".
-- No crea ni vincula ningún registro en las tablas de Bolsa LATAM.
alter table public.ssoma_bpo_registros drop constraint ssoma_bpo_registros_estado_check;
alter table public.ssoma_bpo_registros add constraint ssoma_bpo_registros_estado_check
  check (estado in ('pendiente','parcial','recuperado','migrado_bolsa'));
