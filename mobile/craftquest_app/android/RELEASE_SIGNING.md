# Firma de release para Android (.aab)

## 1. Generar el keystore (una sola vez, guardalo para siempre)

En Windows, `keytool` suele no estar en el PATH. Usa el que trae Android Studio:

```powershell
cd mobile\craftquest_app\android

& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore craftquestai-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias craftquestai
```

En macOS/Linux (si `keytool` está en el PATH):

```bash
keytool -genkey -v -keystore craftquestai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias craftquestai
```

Ejecuta ese comando **desde la carpeta `mobile/craftquest_app/android/`** para que el `.jks` quede junto a `key.properties`
(o ajusta la ruta en `storeFile` si lo guardas en otro lugar). Te pedirá una contraseña de store, una de key, y tus datos
(nombre, organización, etc.). Guarda el archivo `.jks` y ambas contraseñas en un gestor de contraseñas seguro:
**si los pierdes, no podrás publicar actualizaciones de la app con el mismo `applicationId`.**

## 2. Crear key.properties

Copia `key.properties.example` como `key.properties` (misma carpeta) y completa los valores reales:

```properties
storePassword=...
keyPassword=...
keyAlias=craftquestai
storeFile=../craftquestai-release.jks
```

`build.gradle.kts` ya detecta este archivo automaticamente: si existe, firma el build `release` con esta key;
si no existe, sigue usando la firma debug (para no romper `flutter run --release` en desarrollo).

## 3. Obtener las huellas SHA-1 / SHA-256

Windows:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore craftquestai-release.jks -alias craftquestai
```

macOS/Linux:

```bash
keytool -list -v -keystore craftquestai-release.jks -alias craftquestai
```

- **SHA-1**: registrar en Firebase Console (Configuracion del proyecto > tu app Android) para que Google Sign-In nativo
  funcione en release (sin esto falla con `DEVELOPER_ERROR` / codigo 10).
- **SHA-256**: agregar a `JoinLinks:AndroidSha256Fingerprints` en `appsettings.Production.json` del backend, para que
  `/.well-known/assetlinks.json` verifique los App Links (`/join`, `/prep`, etc.).

Si activas **Play App Signing** en Play Console (recomendado), Google genera una key de firma final distinta a tu
upload key. En ese caso usa el SHA-256 que muestra Play Console ("App signing key certificate"), no el de tu keystore local,
para el paso de `AndroidSha256Fingerprints`.

## 4. Compilar el .aab

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.craftquestai.com
```

El archivo queda en `build/app/outputs/bundle/release/app-release.aab`.
