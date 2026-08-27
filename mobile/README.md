# App móvil (SSOMA Adecco)

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

## Notificaciones push (Firebase)

Proyecto Firebase: `ssoma-adecco`. `mobile/android/app/google-services.json`
ya está en el repo (identifica la app ante Firebase; no es un secreto — Google
la protege por Security Rules y restricción de package/firma, no por
ocultarla — así que se commitea como cualquier otro archivo de configuración).

Falta un solo paso para que las notificaciones realmente se envíen:

- En Firebase, **Project Settings → Cuentas de servicio → Generar nueva clave
  privada**, descargar el JSON de la cuenta de servicio y configurarlo como
  secreto de Supabase (usado por la función que envía las notificaciones):
  ```
  supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)" --project-ref zlukrktpjffiycarpduc
  ```

Sin ese paso el APK compila y funciona igual, solo que las notificaciones
push no se envían (la función `ssoma-fcm-send` responde sin error, pero no
hace nada, hasta que el secreto `FCM_SERVICE_ACCOUNT_JSON` exista).
