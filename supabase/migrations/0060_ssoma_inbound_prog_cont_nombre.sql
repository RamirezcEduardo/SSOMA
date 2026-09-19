-- ============================================================
-- BLOQUE 60: Programación de Contenedores — nombre de quien registra
--
-- Para personalizar el correo de confirmación (bloque 61: función
-- enviar-programacion-comex) hace falta un nombre, no solo
-- DNI/correo/área.
-- ============================================================

alter table ssoma_inbound_programacion_contenedores add column if not exists registrado_por_nombre text;

comment on column ssoma_inbound_programacion_contenedores.registrado_por_nombre is 'Nombre de quien llenó el formulario (para personalizar el correo de confirmación) — no es una cuenta de SSOMA, solo texto libre.';
