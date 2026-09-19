-- BLOQUE 44: agrega comentario opcional a cada reporte de recuperación
-- (checklist Bultos Perdidos / Sin Ubicación en Auditoría de Inventario).
alter table ssoma_bpo_recuperaciones add column if not exists comentario text;
comment on column ssoma_bpo_recuperaciones.comentario is 'Comentario libre y opcional del operador al reportar la recuperación (ej. dónde/cómo apareció el bulto).';
