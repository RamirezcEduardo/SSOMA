-- Se cargó un archivo incorrecto con "Vincular otras ubicaciones" y quedaron
-- guardadas ubicaciones equivocadas (zonas tipo SIN-UBICACION-/MERMA-, no
-- ubicaciones reales de almacén) en varias tarjetas de Sin Ubicación. Limpia
-- esos datos para volver a subir el archivo correcto — no borra ni toca
-- ninguna otra columna del registro.
update public.ssoma_bpo_registros set otras_ubicaciones = null where otras_ubicaciones is not null;
