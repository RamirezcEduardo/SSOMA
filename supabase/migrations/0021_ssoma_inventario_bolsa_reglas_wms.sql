-- ============================================================
-- BLOQUE 21: Inventario — Control de Bolsa: reglas de clasificación
-- del WMS + maestro de producto.
--
-- Por qué existe este bloque (decisión confirmada con el usuario):
-- el import semanal de Control de Bolsa NO va a traer el archivo
-- "Plantilla CD 9053" completo — solo el export BRUTO del WMS (el
-- log crudo de ajustes, columnas tipo Historial de actividad, Nro
-- LPN, Cod Alternat, Ubicacion, Un Ajust... sin las columnas
-- calculadas Motivo/Área/Origen/Valorizado). Esas columnas se
-- calculaban en el Excel con BUSCARV contra las hojas VALOR,
-- Proveedor y Motivos de la Plantilla — aquí se guardan esas
-- mismas hojas como tablas, para que la app pueda calcular lo
-- mismo sobre el bruto sin que el usuario las suba cada semana.
--
-- Fuente: hojas "Proveedor" y "Motivos" de Plantilla CD 9053.xlsx
-- (compartida por el usuario). El maestro de producto real
-- (ssoma_bolsa_productos, ~45,385 SKU) se carga aparte en la
-- migración 0022 por su tamaño.
--
-- Alcance recortado a propósito: de las varias tablas de la hoja
-- Motivos, se replican las 3 que alimentan el cálculo real:
--   1) Consolidado -> Motivo (la regla principal — cubre la
--      mayoría de las transacciones, las que NO caen en una
--      ubicación especial "XX-...").
--   2) Ubicación -> Motivo (solo para las 9 ubicaciones "XX-...":
--      override que gana cuando aplica, según la fórmula original
--      IFERROR(BUSCARV(Ubicacion,...), Motivo por Consolidado)).
--   3) Motivo -> Origen.
-- Se deja fuera el mapeo Usuario -> Área (solo 3 usuarios, muy
-- específico del WMS actual) y columnas auxiliares que no entran
-- en la cascada (COPIAR, Revisar) — si luego hacen falta, se agregan.
-- ============================================================

create table if not exists ssoma_bolsa_productos (
  cod_producto  text primary key,
  producto      text,
  costo         numeric,
  familia       text,
  proveedor     text,
  updated_at    timestamptz not null default now()
);

comment on table ssoma_bolsa_productos is 'Maestro de producto (costo, familia, proveedor) tomado de la hoja Proveedor de Plantilla CD 9053 — se usa para valorizar el bruto del WMS (costo x Un Ajust) sin depender de que lo suban cada semana.';

create table if not exists ssoma_bolsa_wms_consolidado_motivo (
  historial_actividad  text not null,
  nombre_pantalla      text not null,
  cod_razon            text not null,
  motivo               text not null,

  primary key (historial_actividad, nombre_pantalla, cod_razon)
);

comment on table ssoma_bolsa_wms_consolidado_motivo is 'Regla principal de clasificación (hoja Motivos!D:E de Plantilla CD 9053): la combinación Historial de actividad + Nombre pantalla + Cod Razon del bruto WMS -> Motivo de negocio. Cubre la mayoría de las transacciones (68 combinaciones observadas).';

insert into ssoma_bolsa_wms_consolidado_motivo (historial_actividad, nombre_pantalla, cod_razon, motivo)
select split_part(clave, '||', 1), split_part(clave, '||', 2), split_part(clave, '||', 3), motivo
from (values
  ('17 - Inventory Adjusted post verifcation||RF_Modifica caja LPN||AJUSTE / CRUCE 0001', 'AJUSTE / CRUCE 0001'),
  ('17 - Inventory Adjusted post verifcation||RF_Modificar LPN||AJUSTE / CRUCE 0001', 'AJUSTE / CRUCE 0001'),
  ('29 - Create Allocatable Container||AUT Crea LPN||CONTEO CICLICO', 'CREACION LPN AUT'),
  ('29 - Create Allocatable Container||RF_Crea LPN MultiSku||CONTEO CICLICO', 'CREACION MULTISKU'),
  ('19 - Inventory Adjustment - Cycle Count Active||RF CC x Detalle LPNs CD14||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('39 - Caja Perdida x CC||RF_Conteo Ciclico de LPN||CONTEO CICLICO', 'REGULARIZACION'),
  ('19 - Inventory Adjustment - Cycle Count Active||Invent Activo||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('40 - Caja perdida||RF_Conteo Ciclico de LPN||CONTEO CICLICO', 'REGULARIZACION'),
  ('29 - Create Allocatable Container||RF_Crea LPN||CONTEO CICLICO', 'CREACION LPN'),
  ('19 - Inventory Adjustment - Cycle Count Active||RF_Conteo Ciclico de Unidades||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('17 - Inventory Adjusted post verifcation||Cajas||CONTEO CICLICO', 'AJUSTE LPN'),
  ('29 - Create Allocatable Container||MRM Crea LPN||CONTEO CICLICO', 'CREACION LPN MRM'),
  ('17 - Inventory Adjusted post verifcation||RF_Modifica caja LPN||CONTEO CICLICO', 'AJUSTE LPN'),
  ('29 - Create Allocatable Container||VAS Crea LPN||CONTEO CICLICO', 'CREACION LPN VAS'),
  ('40 - Caja perdida||RF_Conteo Ciclico de Unidades||CONTEO CICLICO', 'REGULARIZACION'),
  ('17 - Inventory Adjusted post verifcation||RF_Modificar LPN||CONTEO CICLICO', 'AJUSTE LPN'),
  ('19 - Inventory Adjustment - Cycle Count Active||RF_Conteo Ciclico de LPN||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('40 - Caja perdida||RF_Conteo Ciclico Num LPN''s||CONTEO CICLICO', 'REGULARIZACION'),
  ('53 - Cycle Count - Reserve SKU Counted||RF_Conteo Ciclico de Unidades||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('53 - Cycle Count - Reserve SKU Counted||RF CC x Detalle LPNs CD14||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('19 - Inventory Adjustment - Cycle Count Active||RF CC Activo CD14||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('39 - Caja Perdida x CC||RF_Conteo Ciclico de Unidades||CONTEO CICLICO', 'REGULARIZACION'),
  ('19 - Inventory Adjustment - Cycle Count Active||Inventario Activo||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('40 - Caja perdida||RF CC x Detalle LPNs CD14||CONTEO CICLICO', 'REGULARIZACION'),
  ('39 - Caja Perdida x CC||RF CC x Detalle LPNs CD14||CONTEO CICLICO', 'REGULARIZACION'),
  ('40 - Caja perdida||Cycle Cnt {locn}||CONTEO CICLICO', 'REGULARIZACION'),
  ('19 - Inventory Adjustment - Cycle Count Active||RF CC por detalle||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('40 - Caja perdida||RF CC por detalle||CONTEO CICLICO', 'REGULARIZACION'),
  ('4 - Inventory Adjusted pre verification||RF_Crea LPN MultiSku||CONTEO CICLICO', 'REVISAR CREACION'),
  ('40 - Caja perdida||RF_CC_UNDS_CD12||CONTEO CICLICO', 'REGULARIZACION'),
  ('53 - Cycle Count - Reserve SKU Counted||RF_CC_UNDS_CD12||CONTEO CICLICO', 'AJUSTE ACTIVO'),
  ('39 - Caja Perdida x CC||RF_CC_UNDS_CD12||CONTEO CICLICO', 'REGULARIZACION'),
  ('4 - Inventory Adjusted pre verification||Cajas||CONTEO CICLICO', 'AJUSTE PTA'),
  ('52 - Audit Adjustment||RF_Auditar Carton||CONTEO CICLICO', 'VAS'),
  ('4 - Inventory Adjusted pre verification||calc_nbr_containers||CONTEO CICLICO', 'AJUSTE PTA'),
  ('39 - Caja Perdida x CC||RF_CC Ubic y LPN_RFC||CONTEO CICLICO', 'REGULARIZACION'),
  ('4 - Inventory Adjusted pre verification||AUT Crea LPN||CONTEO CICLICO', 'REVISAR CREACION'),
  ('4 - Inventory Adjusted pre verification||VAS Crea LPN||CONTEO CICLICO', 'REVISAR CREACION'),
  ('39 - Caja Perdida x CC||RF CC por detalle||CONTEO CICLICO', 'REGULARIZACION'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||CONTEO CICLICO', 'REVISAR UBICACIÓN'),
  ('17 - Inventory Adjusted post verifcation||entity.iblpn.modify_item_qty||CONTEO CICLICO', 'AJUSTE LPN'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||FALTA_VAS', 'VAS'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||PP_CERO', 'PP_CERO'),
  ('4 - Inventory Adjusted pre verification||RF_Picking_Case_PN||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('4 - Inventory Adjusted pre verification||RF_Picking_Case_AAA-LAC_PN||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('40 - Caja perdida||Move LPN||SHORT PICK ACTIVO', 'REGULARIZACION'),
  ('40 - Caja perdida||RF_Move LPN AMR PLT||SHORT PICK ACTIVO', 'REGULARIZACION'),
  ('4 - Inventory Adjusted pre verification||RF_Picking_Case_Pañales_PN||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('40 - Caja perdida||RF_Move LPN AAA||SHORT PICK ACTIVO', 'REGULARIZACION'),
  ('17 - Inventory Adjusted post verifcation||RF_Pick_Cart_AAA_LAC||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('17 - Inventory Adjusted post verifcation||RF_Pick_Cart_Pañales PN||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||SOBRANTE', 'REVISAR UBICACIÓN'),
  ('17 - Inventory Adjusted post verifcation||RF_Modifica caja LPN||SOBRANTE', 'REVISAR AJUSTE LPN IP6'),
  ('17 - Inventory Adjusted post verifcation||RF_Modificar LPN||SOBRANTE', 'REVISAR AJUSTE LPN IP6'),
  ('19 - Inventory Adjustment - Cycle Count Active||Invent Activo||SOBRANTE', 'REVISAR AJUSTE IP6'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||FALTANTE', 'REVISAR UBICACIÓN'),
  ('17 - Inventory Adjusted post verifcation||RF_Modificar LPN||FALTANTE', 'REVISAR AJUSTE LPN IP6'),
  ('17 - Inventory Adjusted post verifcation||RF_Modifica caja LPN||FALTANTE', 'REVISAR AJUSTE LPN IP6'),
  ('19 - Inventory Adjustment - Cycle Count Active||Invent Activo||FALTANTE', 'REVISAR AJUSTE IP6'),
  ('19 - Inventory Adjustment - Cycle Count Active||Inventario Activo||FALTANTE', 'REVISAR AJUSTE IP6'),
  ('17 - Inventory Adjusted post verifcation||Cajas||FALTANTE', 'REVISAR AJUSTE LPN IP6'),
  ('17 - Inventory Adjusted post verifcation||Cajas||SOBRANTE', 'REVISAR AJUSTE LPN IP6'),
  ('40 - Caja perdida||RF_Picking_Case_PN||SHORT PICK ACTIVO', 'REGULARIZACION'),
  ('29 - Create Allocatable Container||CRT ENVIADO CREA LPN||CONTEO CICLICO', 'CREACION DE LPN CTR'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||CC_IP6', 'CC_IP6'),
  ('4 - Inventory Adjusted pre verification||entity.location.update_active_inventory||SHORT PICK IP6', 'SHORT PICK IP6'),
  ('4 - Inventory Adjusted pre verification||RF_Picking_Case_QS||SHORT PICK ACTIVO', 'SHORT PICK'),
  ('4 - Inventory Adjusted pre verification||Cajas||FALTANTE', 'REVISAR AJUSTE LPN IP6')
) as t(clave, motivo)
on conflict (historial_actividad, nombre_pantalla, cod_razon) do update set motivo = excluded.motivo;

create table if not exists ssoma_bolsa_wms_ubicacion_motivo (
  ubicacion   text primary key,
  motivo      text not null
);

comment on table ssoma_bolsa_wms_ubicacion_motivo is 'Override de Ubicación -> Motivo (hoja Motivos!V:W de Plantilla CD 9053) — solo las 9 ubicaciones especiales "XX-...". Gana sobre ssoma_bolsa_wms_consolidado_motivo cuando la Ubicación del bruto WMS calza aquí (misma prioridad que IFERROR(BUSCARV(Ubicacion,...), Motivo por Consolidado) en el Excel original).';

insert into ssoma_bolsa_wms_ubicacion_motivo (ubicacion, motivo) values
  ('XX-SIN-UBIC-00',                    'AJUSTES SIN UBICACIÓN'),
  ('XX-PERDIDO-00-00',                  'AJUSTE PERDIDO'),
  ('XX-MERMA-OP-00',                    'AJUSTE MERMA'),
  ('XX-REABAS-00-00',                   'AJUSTE REABASTO'),
  ('XX-CART-EMPAC-NOUBICADO-IP6',       'AJUSTES CARTONES IP6'),
  ('XX-CART-EMPAC-NOUBICADO-WMS',       'AJUSTES CARTONES WMS'),
  ('XX-CART-EMPAC-NOUBICADO-WMS-MZ',    'AJUSTES CARTONES LAVORO'),
  ('XX-CART-EMPAC-LOCAL',               'CARTONES EN LOCAL'),
  ('XX-REG-DIF-00',                     'POR REVISAR')
on conflict (ubicacion) do update set motivo = excluded.motivo;

create table if not exists ssoma_bolsa_wms_motivo_origen (
  motivo    text primary key,
  origen    text not null
);

comment on table ssoma_bolsa_wms_motivo_origen is 'Regla Motivo -> Origen (hoja Motivos!L:M / Tabla3 de Plantilla CD 9053) — de dónde viene el ajuste: WMS o AJUSTE IP6.';

insert into ssoma_bolsa_wms_motivo_origen (motivo, origen) values
  ('CREACION LPN',             'WMS'),
  ('CREACION LPN AUT',         'AJUSTE IP6'),
  ('CREACION LPN VAS',         'WMS'),
  ('REGULARIZACION',           'WMS'),
  ('AJUSTE CICLICO',           'WMS'),
  ('AJUSTE LPN',               'WMS'),
  ('CREACION LPN MRM',         'WMS'),
  ('CREACION MULTISKU',        'WMS'),
  ('AJUSTE PERDIDO',           'WMS'),
  ('VAS',                      'AJUSTE IP6'),
  ('AFRAME',                   'AJUSTE IP6'),
  ('PTB',                      'AJUSTE IP6'),
  ('PP_CERO',                  'AJUSTE IP6'),
  ('AJUSTE REABASTO',          'WMS'),
  ('AJUSTES CARTONES WMS',     'WMS'),
  ('AJUSTES CARTONES LAVORO',  'WMS'),
  ('REVISAR AJUSTE IP6',       'AJUSTE IP6'),
  ('AJUSTES SIN UBICACIÓN',    'WMS'),
  ('CREACION DE LPN CTR',      'WMS'),
  ('CC_IP6',                   'AJUSTE IP6'),
  ('SHORT PICK IP6',           'AJUSTE IP6'),
  ('CARTONES EN LOCAL',        'WMS'),
  ('SHORT PICK',                'WMS'),
  ('SOBRANTE',                  'AJUSTE IP6'),
  ('AJUSTE MERMA',              'WMS'),
  ('AJUSTE ACTIVO',             'WMS'),
  ('AJUSTES CARTONES IP6',      'WMS')
on conflict (motivo) do update set origen = excluded.origen;

alter table ssoma_bolsa_productos enable row level security;
alter table ssoma_bolsa_wms_consolidado_motivo enable row level security;
alter table ssoma_bolsa_wms_ubicacion_motivo enable row level security;
alter table ssoma_bolsa_wms_motivo_origen enable row level security;

-- Solo lectura pública: son catálogos/reglas que se actualizan a mano
-- (o re-generando el seed) cuando cambie el maestro o el criterio del WMS,
-- igual que ssoma_bolsa_reglas_considerar y ssoma_bolsa_motivo_equivalencias.
create policy ssoma_bolsa_productos_select on ssoma_bolsa_productos
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_consolidado_motivo_select on ssoma_bolsa_wms_consolidado_motivo
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_ubicacion_motivo_select on ssoma_bolsa_wms_ubicacion_motivo
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_motivo_origen_select on ssoma_bolsa_wms_motivo_origen
  for select to anon, authenticated using (true);
