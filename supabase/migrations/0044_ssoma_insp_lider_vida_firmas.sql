-- ============================================================
-- BLOQUE 44: Firmas dibujadas en las inspecciones "Líder de Vida"
--
-- "Inspeccionado por" ya no se escribe a mano: sale del usuario
-- logueado al crear el registro, y firma en el momento (obligatorio).
-- "Revisado por" NO se llena junto con el registro: un supervisor
-- SSOMA lo revisa después, desde el detalle del registro ya
-- guardado, y ese "revisado_por" también sale de quien esté logueado
-- en ese momento (un update, no parte del insert original). Ambos
-- firman dibujando con el dedo o el mouse sobre un canvas — la firma
-- se guarda como PNG en base64 (igual patrón que la evidencia
-- fotográfica de RACS, ver 0005), no como trazo vectorial.
-- ============================================================

alter table ssoma_insp_equipo_cabecera
  add column if not exists inspeccionado_firma text,
  add column if not exists revisado_firma text;

alter table ssoma_insp_epp_cabecera
  add column if not exists inspeccionado_firma text,
  add column if not exists revisado_firma text;

comment on column ssoma_insp_equipo_cabecera.inspeccionado_firma is 'Firma dibujada, PNG en base64 (data URL). Obligatoria al guardar.';
comment on column ssoma_insp_equipo_cabecera.revisado_firma is 'Firma dibujada, PNG en base64 (data URL). Opcional (solo si ya se revisó).';
comment on column ssoma_insp_epp_cabecera.inspeccionado_firma is 'Firma dibujada, PNG en base64 (data URL). Obligatoria al guardar.';
comment on column ssoma_insp_epp_cabecera.revisado_firma is 'Firma dibujada, PNG en base64 (data URL). Opcional (solo si ya se revisó).';
