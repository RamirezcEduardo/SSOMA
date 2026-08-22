# Bloques SQL — SSOMA Centro de Reportes

Nada de esto se ha ejecutado en Supabase todavía. Son los 4 bloques listos para revisar.

## Orden de aplicación
1. `0001_ssoma_catalogos.sql` — catálogos (observadores, supervisores, ubicaciones, ocurrencias, condiciones) + datos semilla copiados tal cual del HTML actual.
2. `0002_ssoma_racs.sql` — tabla de reportes RACS + historial de levantamientos. Corrige el bug de IDs duplicados (`RACS-0001` se recalculaba con `reports.length + 1`, así que borrar un reporte podía generar un ID repetido). Ahora el ID es `identity` (nunca se reutiliza) y el código visible (`RACS-0001`) es una columna generada a partir de ese ID.
3. `0003_ssoma_comportamental.sql` — evaluaciones comportamentales, mismo arreglo de ID + validación de que las respuestas del checklist solo tengan las 11 claves esperadas con valores `SI`/`NO`.
4. `0004_ssoma_rls.sql` — Row Level Security. **Lea el comentario del archivo antes de aplicarlo**: replica el mismo nivel de seguridad que tiene hoy el HTML (cero login, cualquiera con la key puede leer/escribir), no es un candado real de acceso.

## Directorio de personal (`ssoma_personal`)
Verificado contra los PDF originales de los dos Google Forms (RACS y Evaluación Comportamental): las listas de "observador" y "supervisor" tenían 15 personas escritas de forma distinta entre un form y otro (mismo individuo). El usuario confirmó que son la misma persona en cada caso y se fusionaron en un solo directorio (`ssoma_personal`, 31 personas únicas) con columnas `puede_observar`/`puede_supervisar`. El detalle de qué nombre se descartó y cuál quedó como canónico está documentado en el comentario de cabecera de `0001_ssoma_catalogos.sql`. Dos de esas fusiones (`SAAVEDRA OMAR`/`OMAR SAAVEDRA` y `CARLOS TELLEZ`/`TELLEZ CARLOS`) fueron un empate sin forma objetiva de saber cuál escritura es la correcta — revisar si hace falta corregir.

`ssoma_racs_reports.observador_id` y `ssoma_racs_reports.ubicacion_id`, igual que `ssoma_comportamental_evaluaciones.supervisor_id`, ahora son foreign keys a `ssoma_personal`/`ssoma_ubicaciones` en vez de texto libre — evita que un typo futuro en el nombre cree una "persona nueva" fantasma.

## Pendiente de decidir con el usuario (no asumido en el SQL)
- **"Opción 2" como sede**: el Form real de Evaluación Comportamental tiene la sede `FAPE - SANTA ANITA` y una segunda opción llamada literalmente `Opción 2` — parece un placeholder nunca completado en el Google Form de origen. `sede` se dejó como texto libre en `0003` a la espera de saber el nombre real.
- **Proyecto Supabase destino**: todavía no se eligió si esto va al proyecto existente (`marlon220901's Project`, el mismo de PRUEBAS/Adecco-KPI) o a uno nuevo dedicado a SSOMA. Ese proyecto además tiene una `SUPABASE_SERVICE_KEY` filtrada en GitHub que debe rotarse independientemente de esta decisión.
- **Autenticación real**: el HTML no tiene login (cualquiera elige su nombre de un `<select>`). El RLS de `0004` asume eso. Si se quiere trazabilidad real de auditoría, hay que sumar Supabase Auth después.

## Qué falta después de aplicar estos bloques
- Reescribir la sección `<script>` del HTML para usar `@supabase/supabase-js` (vía CDN, sin build step) en lugar de `window.storage.get/set`.
- Obtener `SUPABASE_URL` y la clave pública (`anon`/`publishable`) del proyecto elegido e incrustarlas en el HTML (la clave pública es segura de exponer en el cliente; la `service_key` nunca debe ir aquí).
