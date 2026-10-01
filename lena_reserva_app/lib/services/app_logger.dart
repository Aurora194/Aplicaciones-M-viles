import 'dart:convert';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static void debug(String event, [Map<String, Object?> data = const {}]) {
    _write(LogLevel.debug, event, data);
  }

  static void info(String event, [Map<String, Object?> data = const {}]) {
    _write(LogLevel.info, event, data);
  }

  static void warning(String event, [Map<String, Object?> data = const {}]) {
    _write(LogLevel.warning, event, data);
  }

  static void error(String event, [Map<String, Object?> data = const {}]) {
    _write(LogLevel.error, event, data);
  }

  static void _write(
    LogLevel level,
    String event,
    Map<String, Object?> data,
  ) {
    final record = <String, Object?>{
      'level': level.name.toUpperCase(),
      'event': event,
      'data': data,
    };

    developer.log(
      jsonEncode(record),
      name: 'LenaReserva',
    );
  }
}
