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

Falta un proyecto de Firebase para que las notificaciones realmente lleguen
al celular. Pasos:

1. Crear un proyecto en [console.firebase.google.com](https://console.firebase.google.com)
   (o usar uno existente de Adecco).
2. Agregar una app Android con el package name `com.adecco.ssoma` y descargar
   `google-services.json`.
3. Colocar ese archivo en `mobile/android/app/google-services.json` (no se
   commitea, está en `.gitignore` por ser una credencial).
4. Para que GitHub Actions también lo tenga: `base64 -w0 google-services.json`
   y guardar el resultado como secreto del repo `GOOGLE_SERVICES_JSON_BASE64`.
5. En **Project Settings → Cuentas de servicio → Generar nueva clave privada**
   descargar el JSON de la cuenta de servicio y configurarlo como secreto de
   Supabase (usado por la función que realmente envía las notificaciones):
   ```
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)" --project-ref zlukrktpjffiycarpduc
   ```

Sin estos pasos el APK compila y funciona igual, solo que las notificaciones
push no se envían (la función `ssoma-fcm-send` responde sin error, pero no
hace nada, hasta que el secreto `FCM_SERVICE_ACCOUNT_JSON` exista).
