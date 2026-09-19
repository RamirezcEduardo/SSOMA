-- Shortpick Conciliación: permite marcar un pendiente como "regularizado manual"
-- (se resolvió administrativamente, sin encontrar físicamente el faltante) además
-- de "completo"/"parcial" — mismo concepto que ya existe en Seguimiento Diario
-- (ssoma_seguimiento_diario_registros.estado = 'regularizado_manual').
alter table public.ssoma_sp_verificaciones drop constraint ssoma_sp_verificaciones_estado_check;
alter table public.ssoma_sp_verificaciones add constraint ssoma_sp_verificaciones_estado_check
  check (estado in ('completo','parcial','regularizado_manual'));
