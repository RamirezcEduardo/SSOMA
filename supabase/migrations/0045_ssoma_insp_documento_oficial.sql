-- ============================================================
-- BLOQUE 45: Documento oficial guardado (Líder de Vida)
--
-- Antes, "Generar documento" armaba el HTML al vuelo cada vez que se
-- pulsaba el botón — nunca quedaba nada fijo. Ahora, cuando un supervisor
-- SSOMA firma la revisión (ieGuardarRevision/ieppGuardarRevision), se arma
-- ese mismo HTML UNA VEZ, con ambas firmas ya puestas, y se guarda en esta
-- columna: esa queda como la versión "oficial" del documento, y
-- "Generar documento" la reabre tal cual en vez de reconstruirla, para que
-- no cambie después aunque cambien otros datos del registro.
--
-- Si el registro todavía no tiene revisión SSOMA, esta columna queda en
-- null y "Generar documento" sigue armando una vista previa al vuelo, igual
-- que antes.
-- ============================================================

alter table ssoma_insp_equipo_cabecera
  add column if not exists documento_html text;

alter table ssoma_insp_epp_cabecera
  add column if not exists documento_html text;

comment on column ssoma_insp_equipo_cabecera.documento_html is 'Documento final (HTML) guardado al firmar la revisión SSOMA. Null = todavía no revisado, "Generar documento" arma una vista previa al vuelo.';
comment on column ssoma_insp_epp_cabecera.documento_html is 'Documento final (HTML) guardado al firmar la revisión SSOMA. Null = todavía no revisado, "Generar documento" arma una vista previa al vuelo.';
