import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'reservas_channel',
    'Reservas',
    description: 'Notificaciones relacionadas con las reservas.',
    importance: Importance.high,
  );

  // ============================================================
  // INICIALIZAR NOTIFICACIONES
  // ============================================================

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Inicializar zonas horarias.
    tz.initializeTimeZones();

    // Ecuador UTC-5.
    tz.setLocalLocation(tz.getLocation('America/Guayaquil'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Crear canal de notificaciones.
    await androidPlugin?.createNotificationChannel(_channel);

    _initialized = true;
  }

  // ============================================================
  // SOLICITAR PERMISO DE NOTIFICACIONES
  // ============================================================

  static Future<NotificationPermissionResult> requestPermission() async {
    await initialize();

    final current = await Permission.notification.status;

    if (current.isGranted) {
      return NotificationPermissionResult.granted;
    }

    if (current.isPermanentlyDenied) {
      return NotificationPermissionResult.permanentlyDenied;
    }

    final result = await Permission.notification.request();

    if (result.isGranted) {
      return NotificationPermissionResult.granted;
    }

    if (result.isPermanentlyDenied) {
      return NotificationPermissionResult.permanentlyDenied;
    }

    if (result.isRestricted) {
      return NotificationPermissionResult.restricted;
    }

    if (result.isDenied) {
      return NotificationPermissionResult.denied;
    }

    return NotificationPermissionResult.unavailable;
  }

  // ============================================================
  // ABRIR AJUSTES DE LA APLICACIÓN
  // ============================================================

  static Future<bool> openSettings() async {
    return openAppSettings();
  }

  // ============================================================
  // MOSTRAR NOTIFICACIÓN DE RESERVA CREADA
  // ============================================================

  static Future<void> showReservationCreated({
    required int reservationId,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    await _plugin.show(
      id: 1000 + reservationId,
      title: 'Reserva creada',
      body:
          'Tu reserva #$reservationId fue creada y está pendiente de confirmación.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reservas_channel',
          'Reservas',
          channelDescription: 'Notificaciones relacionadas con las reservas.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ============================================================
  // PROGRAMAR RECORDATORIO
  // ============================================================

  static Future<void> scheduleReservationReminder({
    required int reservationId,
    required DateTime reservationDateTime,
    int minutesBefore = 30,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    // La fecha recibida representa la hora local de Ecuador.
    final scheduledDate = reservationDateTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Hora actual de Ecuador.
    final now = tz.TZDateTime.now(tz.local);

    // Convertir la fecha local de Ecuador a TZDateTime.
    final notificationDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );

    // No programar notificaciones para fechas que ya pasaron.
    if (!notificationDate.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      id: 2000 + reservationId,
      title: 'Recordatorio de reserva',
      body: 'Tu reserva #$reservationId es en $minutesBefore minutos.',
      scheduledDate: notificationDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reservas_channel',
          'Reservas',
          channelDescription: 'Notificaciones relacionadas con las reservas.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),

      // IMPORTANTE:
      // Se utiliza inexactAllowWhileIdle para evitar
      // exact_alarms_not_permitted.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      payload: 'reserva:$reservationId',
    );
  }

  // ============================================================
  // CANCELAR NOTIFICACIONES DE UNA RESERVA
  // ============================================================

  static Future<void> cancelReservationNotification(int reservationId) async {
    await initialize();

    // Cancelar notificación de reserva creada.
    await _plugin.cancel(id: 1000 + reservationId);

    // Cancelar recordatorio.
    await _plugin.cancel(id: 2000 + reservationId);
  }

  // ============================================================
  // CANCELAR SOLAMENTE EL RECORDATORIO
  // ============================================================

  static Future<void> cancelReservationReminder(int reservationId) async {
    await initialize();

    await _plugin.cancel(id: 2000 + reservationId);
  }

  // ============================================================
  // CANCELAR SOLAMENTE LA NOTIFICACIÓN DE CREACIÓN
  // ============================================================

  static Future<void> cancelReservationCreated(int reservationId) async {
    await initialize();

    await _plugin.cancel(id: 1000 + reservationId);
  }

  // ============================================================
  // COMPROBAR SI LAS NOTIFICACIONES ESTÁN PERMITIDAS
  // ============================================================

  static Future<bool> areNotificationsEnabled() async {
    await initialize();

    final permission = await Permission.notification.status;

    return permission.isGranted;
  }
}

// ================================================================
// RESULTADO DEL PERMISO DE NOTIFICACIONES
// ================================================================

enum NotificationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}
