-- ============================================================
-- BLOQUE 36: Control de Bolsa — el dedup fila-a-fila del import de auditoría perdía
-- líneas reales
--
-- El import de auditoría evitaba duplicados con un índice único sobre
-- (fecha, cod_producto, tipo, motivo_op, monto_reversado, ubicacion): si dos filas
-- coincidían exactamente en esos 6 campos, la segunda se descartaba asumiendo que era
-- un reimport accidental. En la práctica, el archivo real de Dif_Santa_Anita_Q3_2026
-- trae 341 grupos de filas que coinciden exactamente en esos 6 campos pero SON eventos
-- distintos (mismo SKU ajustado el mismo día, mismo tipo/motivo, mismo monto — normal
-- en un CD de este volumen) — se perdieron 651 líneas reales de auditoría en silencio.
--
-- Se quita ese índice único (la combinación de esos 6 campos no es un identificador
-- confiable) y se reemplaza por el mismo mecanismo de huella de archivo (SHA-256) que ya
-- usan Shortpick y Sin Ubicación: si intentas importar el mismo archivo dos veces, se
-- avisa ANTES de insertar, en vez de descartar filas al vuelo sin decir nada.
-- ============================================================

alter table ssoma_bolsa_auditoria_lineas drop constraint if exists ssoma_bolsa_auditoria_lineas_natural_key;

alter table ssoma_importaciones_log drop constraint ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'sin_ubicacion', 'bolsa_auditoria', 'bolsa_wms'));
