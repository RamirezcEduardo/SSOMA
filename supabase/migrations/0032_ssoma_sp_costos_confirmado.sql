-- ============================================================
-- BLOQUE 32: "Es S/0.00 real" en el catálogo de costos
--
-- costo=0 y "sin precio cargado" eran indistinguibles: spTienePrecio()
-- solo miraba si costo era truthy, así que un producto realmente gratis
-- (ej. promocional) quedaba para siempre en "Productos sin valor unitario",
-- aunque alguien ya hubiera confirmado que S/0.00 es su precio real —
-- typear "0.00" en el input no lo sacaba de la lista, seguía viéndose
-- como pendiente.
--
-- costo_confirmado = true marca que ese precio (así sea 0) ya fue revisado
-- y es el correcto — se pone en true automáticamente al subir el tarifario
-- o al cargar un costo a mano, y también con el nuevo botón "Es S/0 real".
-- Default false para no dar por buenos los ceros ambiguos que ya existían
-- en el catálogo antes de este cambio.
-- ============================================================

alter table ssoma_sp_costos add column if not exists costo_confirmado boolean not null default false;
