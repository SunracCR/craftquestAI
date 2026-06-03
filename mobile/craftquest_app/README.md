# craftquest_app

## Android edge-to-edge (API 35+)

Checklist de prueba manual:

1. Emulador o dispositivo Android 15 (API 35)
2. Pantalla inicial: titulo y tarjeta de estado API visibles bajo status bar
3. Boton "Reintentar" no queda bajo la barra de gestos
4. Modo claro y oscuro del sistema

Configuracion:

- `android/app/build.gradle.kts`: compileSdk 35, targetSdk 35
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
```

La app web debería publicarse en `https://app.craftquestai.com` (o el dominio raíz). Ver también `README.md` en la raíz del repo.