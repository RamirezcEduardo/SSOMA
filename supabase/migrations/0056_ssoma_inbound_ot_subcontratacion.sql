-- ============================================================
-- BLOQUE 56: Inbound Solicitudes/OT — segundo PDF, la Orden de
-- Trabajo de Subcontratación (distinta de la "Solicitud" del bloque 55)
--
-- El equipo sube DOS PDF por cada pedido: la "Solicitud" (Orden de
-- trabajo reacondicionado de productos QA, código IRP-AAR-QA-FR020 —
-- ya cubierta en el bloque 55, trae el detalle por N° Protocolo) y la
-- "OT" (Orden de Trabajo Subcontratación de INRetail, con OT Nro.,
-- Proveedor, fechas de entrega y el detalle de costos). Van juntos:
-- una fila por N° Protocolo, con los datos de la OT duplicados igual
-- que la cabecera de la Solicitud (mismo patrón denormalizado).
--
-- El PDF de la OT no trae texto real (es texto convertido a gráficos,
-- no hay capa de texto) — se lee con OCR en el navegador, así que estos
-- campos pueden venir con errores de lectura en números finos
-- (subtotal/IGV/total) y se revisan en la vista previa antes de guardar.
-- ============================================================

alter table ssoma_inbound_solicitudes_ot add column if not exists ot_nro text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_fecha text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_proveedor text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_direccion text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_vendedor text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_fecha_entrega text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_lugar_entrega text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_moneda text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_cond_pago text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_observacion text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_total_items text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_total_cantidad text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_subtotal text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_dsctos text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_neto text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_igv text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_total text;
alter table ssoma_inbound_solicitudes_ot add column if not exists ot_items jsonb;
alter table ssoma_inbound_solicitudes_ot add column if not exists archivo_origen_ot text;

comment on column ssoma_inbound_solicitudes_ot.ot_nro is 'N° de la Orden de Trabajo Subcontratación (PDF aparte de la Solicitud) — leído con OCR, no texto digital real.';
comment on column ssoma_inbound_solicitudes_ot.ot_items is 'Líneas de costo de la OT (Cod Prov, Descripción, Cantidad, UMP, Total) tal como las leyó el OCR — array de objetos.';
