# Leña Reserva App

Aplicación móvil para gestionar reservas del restaurante **Leña Steak House**.

## Información del proyecto

* **Framework:** Flutter
* **Lenguaje:** Dart
* **Flutter:** 3.44.9
* **Dart:** 3.12.2
* **Sistema:** Windows 11 25H2
* **Android Studio:** `android-studio-quail3-windows`
* **Android SDK:** 37.0.0
* **Java:** OpenJDK 25.0.2
* **Dispositivo:** Android Emulator
* **Android:** 17 (API 37)
* **ID:** `emulator-5554`
* **Build Tools:** 37.0.0
* **Android Emulator:** 37.1.11.0
* **Dispositivo:** sdk gphone16k x86 64



## Backend

* **Tecnologías:** Node.js, Express, TypeScript, Prisma y MySQL
* **URL:** `http://localhost:3000`
* **Swagger:** `http://localhost:3000/api/docs/`

## Instalación

```bash
git clone https://github.com/Aurora194/Aplicaciones-M-viles.git
cd lena_reserva_app
flutter pub get
```

## Diagnóstico

```bash
flutter doctor -v
```

**Resultado:** `No issues found!`

## Ejecutar aplicación

```bash
flutter run -d emulator-5554
```

La aplicación fue compilada, instalada y ejecutada correctamente en el emulador Android.

## HTTP local

Para Android Emulator:

```text
http://10.0.2.2:3000
```

Para Windows:

```text
http://localhost:3000
```

## Endpoint probado

```text
POST /api/auth/register
GET /api/mesas
POST /api/reservas
```

## Backend con Docker

```bash
docker compose up -d
docker ps
```

Detener:

```bash
docker compose down
```

## Limitaciones

* `sdkmanager` y `emulator` no están agregados al `PATH`.
* Flutter detecta correctamente el SDK y el emulador.
* Durante la ejecución aparecen algunas advertencias de Java/Gradle y `Skipped frames`, pero no impiden la ejecución.

## Estado

✅ Flutter configurado
✅ Android SDK configurado
✅ Emulador detectado
✅ APK compilado
✅ Aplicación ejecutada correctamente

## Sistema de diseño y componentes

Se implementó un sistema de diseño reutilizable con tokens y un conjunto de widgets base para la app:

- `lib/theme/app_colors.dart`: colores semánticos y brand tokens.
- `lib/theme/app_spacing.dart`: espaciado base del sistema.
- `lib/theme/app_radius.dart`: radios y forma visual consistente.
- `lib/theme/app_theme.dart`: tema global de la aplicación.
- `lib/widgets/app_button.dart`: boton reutilizable con loading y accesibilidad.
- `lib/widgets/app_text_field.dart`: campo de texto con validación y semántica.
- `lib/widgets/reservation_card.dart`: tarjeta de reserva accesible y visualmente consistente.
- `lib/widgets/reservation_list.dart`: estados `LOADING`, `EMPTY`, `ERROR` y `SUCCESS`.

### Integración en una pantalla real
La pantalla de login y la pantalla de dashboard incorporan el sistema de diseño y los nuevos componentes. La dashboard muestra un listado realista con reservas, una cabecera resumen y respuestas adaptables a diferentes tamaños de pantalla.

### Accesibilidad
Se agregaron `Semantics` y `tooltip` para que los controles sean más comprensibles para usuarios con asistencia técnica. Los campos y acciones tienen etiqueta semántica y el botón de inicio de sesión cuenta con estado de carga.

### Pruebas en diferentes tamaños
La interfaz se adapta con `LayoutBuilder` y `MediaQuery.sizeOf(context)` para que la dashboard funcione bien en pantallas pequeñas y medianas. En tamaños compactos, los bloques se reorganizan sin romper el diseño.

## Evidencias

### Comandos ejecutados
```bash
flutter clean
flutter pub get
yarn android
```

### Resultado esperado
- App compilando en el emulador Android.
- Pantalla de login con diseño modular y consistente.
- Redirección hacia una dashboard con listado de reservas.

## Autor

Aurora Vargas

Universidad Estatal Amazónica — Aplicaciones Móviles
