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

## Autor

Aurora Vargas

Universidad Estatal Amazónica — Aplicaciones Móviles
