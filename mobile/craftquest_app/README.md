# craftquest_app

## Android edge-to-edge (API 35+)

Checklist de prueba manual:

1. Emulador o dispositivo Android 15 (API 35)
2. Pantalla inicial: titulo y tarjeta de estado API visibles bajo status bar
3. Boton "Reintentar" no queda bajo la barra de gestos
4. Modo claro y oscuro del sistema

Configuracion:

- `android/app/build.gradle.kts`: compileSdk 36, targetSdk 36
- `MainActivity.kt`: `enableEdgeToEdge()` antes de `super.onCreate()`
- `lib/core/widgets/edge_aware_scaffold.dart`
- `main.dart`: `SystemUiMode.edgeToEdge`

## Media y pagos

- Imágenes en opciones de pregunta: `add_question_page.dart` + `option_image_picker.dart`
- Mejorar plan (IAP / PayPal mock): `lib/features/billing/presentation/upgrade_plan_page.dart`
- Configuración API y tiendas: [Documentacion/CraftQuest_Configuracion_Media_Pagos_v4.md](../../Documentacion/CraftQuest_Configuracion_Media_Pagos_v4.md)

```powershell
flutter run --dart-define=API_BASE_URL=https://10.0.2.2:7080 --dart-define=GOOGLE_SERVER_CLIENT_ID=<tu-web-client-id>.apps.googleusercontent.com
```

Por defecto (Chrome/desktop) usa `https://localhost:7080` si no pasas `API_BASE_URL`.

### Producción (cuando despliegues)

Dominio previsto de la API: `https://api.craftquestai.com`

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://api.craftquestai.com
flutter build web --dart-define=API_BASE_URL=https://api.craftquestai.com
flutter build apk --dart-define=API_BASE_URL=https://api.craftquestai.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.craftquestai.com
```

Salida del AAB para Play Store:

`build/app/outputs/bundle/release/app-release.aab`

La app web debería publicarse en `https://app.craftquestai.com` (o el dominio raíz). Ver también `README.md` en la raíz del repo.

## Android: Built-in Kotlin y dependencias

La app ya está migrada a **Built-in Kotlin** (Flutter 3.44+ / AGP 9+). Configuración:

- `android/gradle.properties`: `android.builtInKotlin=true`
- `android/app/build.gradle.kts`: bloque `kotlin { compilerOptions { jvmTarget = JVM_11 } }` (sin plugin `kotlin-android`)

### Versiones fijadas en `pubspec.yaml`

| Paquete | Versión | Motivo |
|---------|---------|--------|
| `share_plus` | `^10.1.4` | `13.3.0` falla al compilar con AGP 8.x + `builtInKotlin=true` (`ShareSuccessManager` no resuelto). Requiere AGP 9+ para usar built-in Kotlin del plugin. |
| `file_picker` | `^8.1.7` | `share_plus >=13.1.0` exige `win32 ^6.x`; `file_picker 8.x` usa `win32 ^5.x`. No subir `share_plus` sin subir también `file_picker` (p. ej. `^11.0.0`). |

### Warnings de KGP en plugins (no bloquean el build)

Al compilar release pueden aparecer avisos de plugins que aún aplican Kotlin Gradle Plugin:

- `desktop_drop`
- `share_plus` (10.1.4)
- `sign_in_with_apple`

Son advertencias para futuras versiones de Flutter. El AAB se genera correctamente. Cuando los autores publiquen versiones compatibles con built-in Kotlin, actualizar con `flutter pub upgrade`.

### Cuándo volver a subir `share_plus`

1. Flutter/AGP del proyecto en **AGP 9+** (para que `share_plus 13.x` use built-in Kotlin sin KGP).
2. Subir en conjunto `file_picker` a `^11.0.0` o superior.
3. Probar build release y flujo de compartir antes de publicar.

### Build release (Windows)

Si `flutter` no está en PATH:

```powershell
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat build appbundle --release --dart-define=API_BASE_URL=https://api.craftquestai.com
```

## Pruebas tras upgrade de plugins

Versiones actuales relevantes (`pubspec.lock`):

| Plugin | Versión | Uso en la app |
|--------|---------|---------------|
| `share_plus` | 10.1.4 | Compartir enlace/PDF (`create_share_code_sheet`, `quiz_detail_page`, import Excel) |
| `sign_in_with_apple` | 8.1.0 | Login OAuth (`oauth_sign_in_service`, `oauth_sign_in_buttons`) |
| `image_picker` | 1.2.3 | Imagen en opciones de pregunta (`option_image_picker.dart`) |
| `desktop_drop` | 0.7.1 | Arrastrar archivos en desktop/web (`study_material_upload_zone`, `excel_import_page`) |
| `shared_preferences` | 2.5.3 | Preferencias locales (sonidos, locale, credenciales, límites guest, etc.) |

### Automatizadas (ejecutar en CI o local)

```powershell
C:\flutter\bin\flutter.bat test
C:\flutter\bin\flutter.bat analyze
```

Cobertura añadida:

| Área | Archivo de test |
|------|-----------------|
| `shared_preferences` / sonidos | `test/features/practice/practice_sound_preference_store_test.dart` |
| APIs de plugins upgradeados | `test/core/plugins/upgraded_plugins_compatibility_test.dart` |
| `desktop_drop` UI | `test/features/ai_generation/study_material_upload_zone_test.dart` |
| `shared_preferences` (guest) | `test/core/guest/anonymous_practice_limit_store_test.dart` |

**Última ejecución:** `flutter test` — 18 tests OK.

**Build release Android:** `flutter build appbundle --release` — OK (AAB generado).

**Build Windows:** requiere Visual Studio toolchain (`flutter doctor`); no ejecutado en este entorno.

### Checklist manual en dispositivo

Completar en **Android** (prioritario) y, si aplica, **iOS / desktop / web**:

#### share_plus — compartir cuestionario / enlace

1. Abrir un cuestionario → menú compartir → generar código.
2. Pulsar **Compartir enlace** → debe abrir el sheet nativo de compartir con texto + URL.
3. (Opcional) Exportar PDF del cuestionario → **Compartir** debe ofrecer el archivo `.pdf`.

Pantallas: `create_share_code_sheet.dart`, `quiz_detail_page.dart`.

#### sign_in_with_apple — login

1. Pantalla login → botón **Iniciar sesión con Apple** visible en iOS/macOS (y web si está configurado).
2. Completar flujo → sesión iniciada en la app.
3. Cancelar el popup de Apple → no debe mostrar error genérico (solo ignorar cancelación).

Pantallas: `oauth_sign_in_buttons.dart`, `oauth_sign_in_service.dart`.

#### image_picker — elegir imagen

1. Crear/editar pregunta → **Adjuntar imagen** en una opción.
2. Elegir foto de galería → preview local → subida OK → imagen visible al guardar.
3. Denegar permiso de galería → mensaje `imagePickPermissionDenied`.

Pantalla: `option_image_picker.dart` (usado en `add_question_page.dart`).

#### desktop_drop — arrastrar archivos (desktop / web)

1. **Import Excel** o **Generación IA** en Windows/macOS/Linux o web.
2. Arrastrar `.xlsx` o PDF a la zona → nombre y tamaño aparecen.
3. Sin soporte de drop (Android/iOS) → solo botón **Elegir archivo**, sin crash.

Pantallas: `excel_import_page.dart`, `study_material_upload_zone.dart`.

#### shared_preferences — preferencias / sonidos

1. Iniciar práctica → activar/desactivar efectos de sonido en ajustes de sesión.
2. Cerrar y reabrir la app → la preferencia se mantiene.
3. (Opcional) Cambiar idioma → persiste tras reinicio.

Store: `practice_sound_preference_store.dart` (clave `pref_practice_sfx`).

## Sesión offline (practicar cuestionarios descargados)

Si ya iniciaste sesión antes y tienes tokens + perfil cacheado, la app **no te expulsa al login** cuando no hay red al abrirla. Entrarás con el último perfil conocido y podrás practicar lo ya descargado.

- Perfil cacheado: `CachedProfileStore` (secure storage).
- Lógica de arranque: `AuthBloc._onSessionChecked` + `AuthRepository.restoreProfileAfterSessionFailure`.
- Flag de UI: `AuthAuthenticated.isOfflineSession` (banner + refresh al reconectar).
- Límite de seguridad: refresh token JWT expirado (7 días) → login obligatorio.
- Tests: `test/features/auth/auth_bloc_offline_session_test.dart`.

