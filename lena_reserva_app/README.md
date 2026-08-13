Leña Reserva App

Aplicación móvil para gestionar reservas del restaurante Leña Steak House.

Información del proyecto
Framework: Flutter
Lenguaje: Dart
Flutter: 3.44.9
Dart: 3.12.2
Sistema: Windows 11 25H2
Android Studio: instalado
Android SDK: 37.0.0
Build Tools: 37.0.0
Java: OpenJDK 25.0.2
Android Emulator: 37.1.11.0
Dispositivo: sdk gphone16k x86 64
Android: 17 (API 37)
ID: emulator-5554
Backend
Tecnologías: Node.js, Express, TypeScript, Prisma y MySQL
URL: http://localhost:3000
Swagger: http://localhost:3000/api/docs/
Instalación
git clone https://github.com/Aurora194/Aplicaciones-M-viles.git
cd lena_reserva_app
flutter pub get
Diagnóstico
flutter doctor -v

Resultado:

No issues found!
Ejecutar aplicación
flutter run -d emulator-5554

La aplicación fue compilada, instalada y ejecutada correctamente en el emulador Android.

Herramientas Android

Las siguientes herramientas ya están disponibles desde PowerShell:

adb --version
emulator -version
emulator -list-avds

AVD configurado:

Medium_Phone

ANDROID_HOME:

C:\Users\USUARIO\AppData\Local\Android\sdk
HTTP local

Para Android Emulator:

http://10.0.2.2:3000

Para Windows:

http://localhost:3000
Endpoints probados
POST /api/auth/register
GET /api/mesas
POST /api/reservas
Backend con Docker

Iniciar:

docker compose up -d
docker ps

Detener:

docker compose down
Limitaciones
sdkmanager requiere que JAVA_HOME esté configurado correctamente.
adb y emulator ya están disponibles desde PowerShell.
Flutter detecta correctamente el Android SDK y el emulador.
Durante la ejecución aparecen algunas advertencias de Java/Gradle y Skipped frames, pero no impiden la compilación ni la ejecución.
Estado
✅ Flutter configurado
✅ Dart configurado
✅ Android SDK 37.0.0 configurado
✅ Build Tools 37.0.0 configurado
✅ ANDROID_HOME configurado
✅ adb funcionando
✅ Android Emulator funcionando
✅ AVD Medium_Phone disponible
✅ Android 17 / API 37 detectado
✅ APK compilado
✅ Aplicación instalada
✅ Aplicación ejecutada correctamente
✅ flutter doctor -v sin problemas

Autor

Aurora Vargas
Universidad Estatal Amazónica — Aplicaciones Móviles