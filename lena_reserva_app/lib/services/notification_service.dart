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

    tz.initializeTimeZones();

    // Ecuador UTC-5.
    tz.setLocalLocation(tz.getLocation('America/Guayaquil'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    // IMPORTANTE:
    // En flutter_local_notifications 22.x
    // "settings" es un parámetro nombrado.
    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);

    _initialized = true;
  }

  // ============================================================
  // SOLICITAR PERMISO
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
  // ABRIR AJUSTES
  // ============================================================

  static Future<bool> openSettings() async {
    return openAppSettings();
  }

  // ============================================================
  // DETALLES DE NOTIFICACIÓN
  // ============================================================

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'reservas_channel',
      'Reservas',
      channelDescription: 'Notificaciones relacionadas con las reservas.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // ============================================================
  // GENERAR ID LOCAL PARA RESERVA
  //
  // Se utiliza cuando createReservation() todavía no devuelve
  // el ID de la reserva creada.
  //
  // Se genera a partir de:
  // - fecha/hora de la reserva
  // - ID de la mesa
  //
  // Así cada reserva tiene sus propios IDs locales.
  // ============================================================

  static int _reservationLocalId({
    required DateTime reservationDateTime,
    required int tableId,
  }) {
    final source = '${reservationDateTime.toIso8601String()}|$tableId';

    var hash = 2166136261;

    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    // Dejamos espacio para:
    // baseId     -> notificación de creación
    // baseId + 1 -> recordatorio
    //
    // Se evita usar los IDs 1000, 2000, 3000 y 4000
    // utilizados por las notificaciones asociadas
    // directamente al ID del backend.
    return 500000 + (hash % 100000000);
  }

  // ============================================================
  // FORMATEAR FECHA
  // ============================================================

  static String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year a las $hour:$minute';
  }

  // ============================================================
  // RESERVA CREADA
  //
  // MÉTODO ORIGINAL:
  // Se utiliza cuando ya tenemos reservationId.
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
      notificationDetails: _notificationDetails,
    );
  }

  // ============================================================
  // RESERVA CREADA SIN ID DEL BACKEND
  //
  // Se utiliza desde CreateReservationPage cuando
  // createReservation() no devuelve todavía el ID.
  // ============================================================

  static Future<void> showReservationCreatedLocal({
    required DateTime reservationDateTime,
    required int tableId,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    final id = _reservationLocalId(
      reservationDateTime: reservationDateTime,
      tableId: tableId,
    );

    await _plugin.show(
      id: id,
      title: 'Reserva creada',
      body:
          'Tu reserva para el ${_formatDateTime(reservationDateTime)} fue creada y está pendiente de confirmación.',
      notificationDetails: _notificationDetails,
      payload: 'reserva_local:$tableId',
    );
  }

  // ============================================================
  // RESERVA CONFIRMADA
  // ============================================================

  static Future<void> showReservationConfirmed({
    required int reservationId,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    await _plugin.show(
      id: 3000 + reservationId,
      title: 'Reserva confirmada',
      body: 'Tu reserva #$reservationId fue confirmada correctamente.',
      notificationDetails: _notificationDetails,
    );
  }

  // ============================================================
  // RESERVA CANCELADA
  // ============================================================

  static Future<void> showReservationCancelled({
    required int reservationId,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    await _plugin.show(
      id: 4000 + reservationId,
      title: 'Reserva cancelada',
      body: 'Tu reserva #$reservationId fue cancelada.',
      notificationDetails: _notificationDetails,
    );
  }

  // ============================================================
  // PROGRAMAR RECORDATORIO
  //
  // MÉTODO ORIGINAL CON ID DEL BACKEND.
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

    final scheduledDate = reservationDateTime.subtract(
      Duration(minutes: minutesBefore),
    );

    final now = tz.TZDateTime.now(tz.local);

    final notificationDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );

    // No programar si ya pasó.
    if (!notificationDate.isAfter(now)) {
      return;
    }

    await _plugin.cancel(id: 2000 + reservationId);

    await _plugin.zonedSchedule(
      id: 2000 + reservationId,
      title: 'Recordatorio de reserva',
      body: 'Tu reserva #$reservationId es en $minutesBefore minutos.',
      scheduledDate: notificationDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'reserva:$reservationId',
    );
  }

  // ============================================================
  // PROGRAMAR RECORDATORIO SIN ID DEL BACKEND
  //
  // Se utiliza para las reservas recién creadas.
  // ============================================================

  static Future<void> scheduleReservationReminderLocal({
    required DateTime reservationDateTime,
    required int tableId,
    int minutesBefore = 30,
  }) async {
    await initialize();

    final permission = await Permission.notification.status;

    if (!permission.isGranted) {
      return;
    }

    final scheduledDate = reservationDateTime.subtract(
      Duration(minutes: minutesBefore),
    );

    final now = tz.TZDateTime.now(tz.local);

    final notificationDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );

    // Si la hora del recordatorio ya pasó,
    // no se programa.
    if (!notificationDate.isAfter(now)) {
      return;
    }

    final baseId = _reservationLocalId(
      reservationDateTime: reservationDateTime,
      tableId: tableId,
    );

    final reminderId = baseId + 1;

    // Elimina un recordatorio anterior con el mismo ID.
    await _plugin.cancel(id: reminderId);

    await _plugin.zonedSchedule(
      id: reminderId,
      title: 'Recordatorio de reserva',
      body: 'Tu reserva es en $minutesBefore minutos.',
      scheduledDate: notificationDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'reserva_local:$tableId',
    );
  }

  // ============================================================
  // CANCELAR NOTIFICACIONES LOCALES DE UNA RESERVA
  // ============================================================

  static Future<void> cancelReservationLocal({
    required DateTime reservationDateTime,
    required int tableId,
  }) async {
    await initialize();

    final baseId = _reservationLocalId(
      reservationDateTime: reservationDateTime,
      tableId: tableId,
    );

    // Notificación de creación.
    await _plugin.cancel(id: baseId);

    // Recordatorio.
    await _plugin.cancel(id: baseId + 1);
  }

  // ============================================================
  // CANCELAR SOLAMENTE RECORDATORIO LOCAL
  // ============================================================

  static Future<void> cancelReservationReminderLocal({
    required DateTime reservationDateTime,
    required int tableId,
  }) async {
    await initialize();

    final baseId = _reservationLocalId(
      reservationDateTime: reservationDateTime,
      tableId: tableId,
    );

    await _plugin.cancel(id: baseId + 1);
  }

  // ============================================================
  // CANCELAR NOTIFICACIÓN DE CREACIÓN LOCAL
  // ============================================================

  static Future<void> cancelReservationCreatedLocal({
    required DateTime reservationDateTime,
    required int tableId,
  }) async {
    await initialize();

    final baseId = _reservationLocalId(
      reservationDateTime: reservationDateTime,
      tableId: tableId,
    );

    await _plugin.cancel(id: baseId);
  }

  // ============================================================
  // CANCELAR TODAS LAS NOTIFICACIONES
  //
  // MÉTODO ORIGINAL CON ID DEL BACKEND.
  // ============================================================

  static Future<void> cancelReservationNotification(int reservationId) async {
    await initialize();

    // Reserva creada.
    await _plugin.cancel(id: 1000 + reservationId);

    // Recordatorio.
    await _plugin.cancel(id: 2000 + reservationId);

    // Confirmación.
    await _plugin.cancel(id: 3000 + reservationId);

    // Cancelación.
    await _plugin.cancel(id: 4000 + reservationId);
  }

  // ============================================================
  // CANCELAR SOLAMENTE RECORDATORIO
  //
  // MÉTODO ORIGINAL CON ID DEL BACKEND.
  // ============================================================

  static Future<void> cancelReservationReminder(int reservationId) async {
    await initialize();

    await _plugin.cancel(id: 2000 + reservationId);
  }

  // ============================================================
  // CANCELAR NOTIFICACIÓN DE CREACIÓN
  //
  // MÉTODO ORIGINAL CON ID DEL BACKEND.
  // ============================================================

  static Future<void> cancelReservationCreated(int reservationId) async {
    await initialize();

    await _plugin.cancel(id: 1000 + reservationId);
  }

  // ============================================================
  // COMPROBAR PERMISO
  // ============================================================

  static Future<bool> areNotificationsEnabled() async {
    await initialize();

    final permission = await Permission.notification.status;

    return permission.isGranted;
  }
}

// ============================================================
// RESULTADO DEL PERMISO
// ============================================================

enum NotificationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}
