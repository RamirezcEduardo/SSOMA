# App móvil (ADECCO RP)

Empaqueta la misma app web (`../index.html`) como app Android nativa usando
[Capacitor](https://capacitorjs.com), para poder recibir notificaciones push
reales (asignación de tarea, 20 min antes del vencimiento, tarea finalizada)
incluso con el celular bloqueado.

## Compilar el APK

GitHub Actions lo compila solo en cada push a `main` que toque `mobile/**` o
`index.html` (ver `.github/workflows/build-apk.yml`). El `.apk` queda como
artefacto descargable en la pestaña **Actions** del run correspondiente.

También se puede compilar localmente (requiere Android Studio / Android SDK):

```
cd mobile
npm install
cp ../index.html www/index.html   # sincroniza la app web más reciente
npx cap sync android
npx cap open android              # abre en Android Studio, o:
cd android && ./gradlew assembleDebug
```

## Notificaciones push (Firebase) — ya configurado

Proyecto Firebase: `ssoma-adecco`.

- `mobile/android/app/google-services.json` ya está en el repo (identifica la
  app ante Firebase; no es un secreto — Google la protege por Security Rules
  y restricción de package/firma, no por ocultarla — así que se commitea como
  cualquier otro archivo de configuración).
- La cuenta de servicio de Firebase (clave privada para enviar notificaciones)
  está guardada cifrada en **Supabase Vault** como el secreto
  `fcm_service_account_json`, no como variable de entorno de la función. La
  función `ssoma-fcm-send` la lee en cada invocación vía
  `public.ssoma_get_fcm_service_account()`, una función SQL restringida al rol
  `service_role` (ver `supabase/migrations/0016_ssoma_fcm_service_account_accessor.sql`).

Para rotar la clave en el futuro (ej. si se generó una nueva desde Firebase):
```sql
select vault.update_secret(
  (select id from vault.secrets where name = 'fcm_service_account_json'),
  '<contenido completo del nuevo JSON>'
);
```

## Firma de debug fija

`mobile/android/keystores/debug.keystore` está commiteado a propósito, con la
firma de debug estándar de Android (usuario/contraseña "android" — no es un
secreto real, nunca sirve para publicar en Play Store). Sin esto, cada build
de GitHub Actions corre en una máquina nueva y Gradle generaría una firma
distinta cada vez, así que instalar la versión nueva encima de la anterior
fallaría y habría que desinstalar la app en cada actualización. Con la firma
fija, actualizar es simplemente instalar el `.apk` nuevo encima.
