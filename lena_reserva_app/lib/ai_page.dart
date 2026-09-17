import 'dart:io';

import 'package:flutter/material.dart';

import 'reservation_pages.dart';
import 'services/api_service.dart';
import 'auth/auth_scope.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.time,
    this.mesas,
    this.people,
    this.date,
    this.timeOfDay,
  });

  final String text;
  final bool isUser;
  final DateTime? time;

  /// Mesas disponibles asociadas al mensaje.
  final List<dynamic>? mesas;

  /// Datos de una posible reserva detectada por la IA.
  final int? people;
  final DateTime? date;
  final TimeOfDay? timeOfDay;
}

class AIPage extends StatefulWidget {
  const AIPage({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  static const Color _primaryColor = Color(0xFF94152A);
  static const Color _backgroundColor = Color(0xFFF7F7F5);
  static const Color _textColor = Color(0xFF172033);
  static const Color _secondaryTextColor = Color(0xFF68778D);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _sending = false;
  bool _initialized = false;

  String _role = 'CLIENTE';

  List<String> _quickQuestions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;

    final auth = AuthScope.of(context);

    _role = (auth.userRole ?? 'CLIENTE').trim().toUpperCase();

    _quickQuestions = _questionsForRole(_role);

    _addWelcomeMessage();

    final initialQuestion = widget.initialQuestion?.trim();

    if (initialQuestion != null && initialQuestion.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _sendQuestion(initialQuestion);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // PREGUNTAS SEGÚN EL ROL
  // ============================================================

  List<String> _questionsForRole(String role) {
    if (role == 'ADMIN') {
      return const [
        '¿Qué reservas están pendientes?',
        '¿Qué reservas están confirmadas?',
        '¿Cómo gestionar las mesas?',
        '¿Qué funciones administrativas tengo?',
      ];
    }

    return const [
      '¿Cómo puedo hacer una reserva?',
      '¿Cuáles son mis reservas?',
      '¿Hay mesas disponibles?',
      '¿Qué puedo hacer en Leña Reserva?',
    ];
  }

  // ============================================================
  // MENSAJE DE BIENVENIDA
  // ============================================================

  void _addWelcomeMessage() {
    final String text;

    if (_role == 'ADMIN') {
      text =
          'Hola, soy Asistente Leña. Puedo ayudarte a consultar '
          'reservas, gestionar mesas y conocer las funciones '
          'administrativas de la aplicación.';
    } else {
      text =
          'Hola, soy Asistente Leña. Puedo ayudarte con tus '
          'reservas, consultar mesas disponibles y conocer las '
          'funciones de Leña Reserva.';
    }

    _messages.add(
      _ChatMessage(text: text, isUser: false, time: DateTime.now()),
    );
  }

  // ============================================================
  // ECUADOR - UTC-5
  // ============================================================

  DateTime _utcToEcuador(DateTime value) {
    final utc = value.toUtc();

    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour - 5,
      utc.minute,
      utc.second,
      utc.millisecond,
      utc.microsecond,
    );
  }

  DateTime _ecuadorToUtc(DateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour + 5,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  // ============================================================
  // FECHAS Y HORAS
  // ============================================================

  DateTime _toEcuadorDateTime(DateTime date) {
    if (date.isUtc) {
      return _utcToEcuador(date);
    }

    return date;
  }

  String _formatTime(DateTime date) {
    final ecuadorDate = _toEcuadorDateTime(date);

    final hour = ecuadorDate.hour.toString().padLeft(2, '0');
    final minute = ecuadorDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatChatTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    return _formatTime(date);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // LIMPIAR MARKDOWN
  // ============================================================

  String _cleanMarkdown(String text) {
    var result = text;

    result = result.replaceAll('```markdown', '');
    result = result.replaceAll('```text', '');
    result = result.replaceAll('```', '');

    result = result.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*', dotAll: true),
      (match) => match.group(1) ?? '',
    );

    result = result.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)', dotAll: true),
      (match) => match.group(1) ?? '',
    );

    result = result.replaceAllMapped(
      RegExp(r'__(.*?)__', dotAll: true),
      (match) => match.group(1) ?? '',
    );

    result = result.replaceAll('`', '');

    result = result.replaceAllMapped(
      RegExp(r'^\s*[-*]\s+', multiLine: true),
      (match) => '• ',
    );

    result = result.replaceAllMapped(
      RegExp(r'^\s*#+\s*', multiLine: true),
      (match) => '',
    );

    result = result.replaceAllMapped(
      RegExp(r'^[ \t]+', multiLine: true),
      (match) => '',
    );

    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    result = result.replaceAll('*', '');
    result = result.replaceAll('_', '');

    return result.trim();
  }

  // ============================================================
  // MAP SEGURO
  // ============================================================

  dynamic _mapValue(dynamic source, String key) {
    if (source is Map) {
      return source[key];
    }

    return null;
  }

  // ============================================================
  // PREGUNTA RÁPIDA
  // ============================================================

  Future<void> _sendQuestion(String question) async {
    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty || _sending) {
      return;
    }

    _messageController.text = cleanQuestion;

    await _sendMessage();
  }

  // ============================================================
  // ENVIAR MENSAJE
  // ============================================================

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _sending) {
      return;
    }

    final auth = AuthScope.of(context);
    final token = auth.accessToken;

    if (!auth.isAuthenticated || token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, '/login', arguments: '/app/ai');

      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: message, isUser: true, time: DateTime.now()),
      );

      _messageController.clear();
      _sending = true;
    });

    _scrollToBottom();

    try {
      debugPrint('========================================');
      debugPrint('AI - MENSAJE');
      debugPrint(message);
      debugPrint('AI - API BASE URL: ${ApiService.baseUrl}');
      debugPrint('========================================');

      final result = await ApiService.askAI(token: token, message: message);

      debugPrint('AI - RESPUESTA RECIBIDA');
      debugPrint('AI - ANSWER: ${result.answer}');
      debugPrint('AI - ROLE: ${result.role}');
      debugPrint('AI - AVAILABILITY: ${result.availability}');
      debugPrint('AI - DRAFT: ${result.reservationDraft}');

      final answer = _cleanMarkdown(result.answer);

      // ========================================================
      // MESAS DISPONIBLES
      // ========================================================

      final availability = result.availability;

      final List<dynamic> mesas =
          availability?.mesas
              .map((mesa) => Map<String, dynamic>.from(mesa))
              .toList() ??
          <dynamic>[];

      debugPrint('AI - MESAS DISPONIBLES: $mesas');

      if (!mounted) {
        return;
      }

      // ========================================================
      // BORRADOR DE RESERVA
      // ========================================================

      final draft = result.reservationDraft;

      debugPrint('========================================');
      debugPrint('AI - RESERVATION DRAFT');
      debugPrint('AI - draft: $draft');

      debugPrint('AI - people: ${_mapValue(draft, 'people')}');

      debugPrint('AI - date: ${_mapValue(draft, 'date')}');

      debugPrint('AI - time: ${_mapValue(draft, 'time')}');

      debugPrint('========================================');

      final peopleValue = _mapValue(draft, 'people');
      final dateValue = _mapValue(draft, 'date');
      final timeValue = _mapValue(draft, 'time');

      final people = _parsePeople(peopleValue);
      final date = _parseDate(dateValue);
      final time = _parseTime(timeValue);

      debugPrint('AI - PERSONAS PARSEADAS: $people');
      debugPrint('AI - FECHA PARSEADA ECUADOR: $date');

      if (time != null) {
        debugPrint(
          'AI - HORA PARSEADA ECUADOR: '
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}',
        );
      }

      // ========================================================
      // AGREGAR RESPUESTA DEL ASISTENTE
      // ========================================================

      setState(() {
        _messages.add(
          _ChatMessage(
            text: answer.isEmpty ? 'He recibido tu solicitud.' : answer,
            isUser: false,
            time: DateTime.now(),
            mesas: mesas.isEmpty ? null : mesas,
            people: people,
            date: date,
            timeOfDay: time,
          ),
        );
      });

      _scrollToBottom();

      // ========================================================
      // RESERVA DETECTADA
      // ========================================================

      if (people != null && date != null && time != null) {
        await _showReservationOptions(
          people: people,
          date: date,
          time: time,
          mesas: mesas,
        );
      }
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

      debugPrint('========================================');
      debugPrint('AI - API EXCEPTION');
      debugPrint('AI - STATUS: ${exception.statusCode}');
      debugPrint('AI - MESSAGE: ${exception.message}');
      debugPrint('AI - FIELD ERRORS: ${exception.fieldErrors}');
      debugPrint('========================================');

      // ========================================================
      // SESIÓN VENCIDA
      // ========================================================

      if (exception.statusCode == 401) {
        await auth.signOut();

        if (!mounted) {
          return;
        }

        Navigator.pushReplacementNamed(context, '/login', arguments: '/app/ai');

        return;
      }

      String errorMessage;

      if (exception.statusCode >= 500) {
        errorMessage =
            'El servidor del asistente presentó un problema. '
            'Verifica que el backend esté funcionando e inténtalo nuevamente.';
      } else if (exception.statusCode == 403) {
        errorMessage = 'No tienes autorización para utilizar el asistente.';
      } else if (exception.statusCode == 422) {
        errorMessage = exception.message.isNotEmpty
            ? exception.message
            : 'La solicitud enviada no es válida.';
      } else {
        errorMessage = exception.message.isNotEmpty
            ? exception.message
            : 'No fue posible procesar la solicitud.';
      }

      setState(() {
        _messages.add(
          _ChatMessage(text: errorMessage, isUser: false, time: DateTime.now()),
        );
      });

      _scrollToBottom();
    } on SocketException catch (exception) {
      if (!mounted) {
        return;
      }

      debugPrint('AI - SOCKET ERROR: $exception');

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'No pude conectarme con el servidor. '
                'Verifica que el backend esté ejecutándose '
                'y que tu celular esté conectado a la misma red Wi-Fi.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } on FormatException catch (exception) {
      if (!mounted) {
        return;
      }

      debugPrint('AI - FORMAT ERROR: $exception');

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'El servidor respondió con un formato que la '
                'aplicación no pudo interpretar.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      debugPrint('========================================');
      debugPrint('AI - ERROR NO CONTROLADO');
      debugPrint('AI - ERROR: $exception');
      debugPrint('AI - TIPO: ${exception.runtimeType}');
      debugPrint('========================================');

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'No pude comunicarme con el asistente en este momento. '
                'Verifica la conexión con el servidor e inténtalo nuevamente.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // PERSONAS
  // ============================================================

  int? _parsePeople(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final direct = int.tryParse(text);

    if (direct != null) {
      return direct;
    }

    final match = RegExp(r'\d+').firstMatch(text);

    if (match == null) {
      return null;
    }

    final numberText = match.group(0);

    if (numberText == null) {
      return null;
    }

    return int.tryParse(numberText);
  }

  // ============================================================
  // FECHA
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // YYYY-MM-DD
    // ----------------------------------------------------------

    final simpleDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);

    if (simpleDate != null) {
      final yearText = simpleDate.group(1);
      final monthText = simpleDate.group(2);
      final dayText = simpleDate.group(3);

      if (yearText == null || monthText == null || dayText == null) {
        return null;
      }

      final year = int.tryParse(yearText);
      final month = int.tryParse(monthText);
      final day = int.tryParse(dayText);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    // ----------------------------------------------------------
    // ISO
    // ----------------------------------------------------------

    final parsedDate = DateTime.tryParse(text);

    if (parsedDate == null) {
      return null;
    }

    if (parsedDate.isUtc) {
      final ecuadorDate = _utcToEcuador(parsedDate);

      return DateTime(ecuadorDate.year, ecuadorDate.month, ecuadorDate.day);
    }

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
  }

  // ============================================================
  // HORA
  // ============================================================

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    debugPrint('AI - HORA ORIGINAL RECIBIDA: $text');

    // ----------------------------------------------------------
    // HH:mm
    // ----------------------------------------------------------

    final simpleMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(text);

    if (simpleMatch != null) {
      final hourText = simpleMatch.group(1);
      final minuteText = simpleMatch.group(2);

      if (hourText == null || minuteText == null) {
        return null;
      }

      final hour = int.tryParse(hourText);
      final minute = int.tryParse(minuteText);

      if (hour == null || minute == null) {
        return null;
      }

      if (hour < 0 || hour > 23) {
        return null;
      }

      if (minute < 0 || minute > 59) {
        return null;
      }

      debugPrint(
        'AI - HORA SIMPLE INTERPRETADA COMO ECUADOR: '
        '$hour:$minute',
      );

      return TimeOfDay(hour: hour, minute: minute);
    }

    // ----------------------------------------------------------
    // ISO
    // ----------------------------------------------------------

    final parsedDate = DateTime.tryParse(text);

    if (parsedDate != null) {
      final ecuadorDate = parsedDate.isUtc
          ? _utcToEcuador(parsedDate)
          : DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              parsedDate.hour,
              parsedDate.minute,
              parsedDate.second,
            );

      debugPrint(
        'AI - HORA ISO CONVERTIDA A ECUADOR: '
        '${ecuadorDate.hour.toString().padLeft(2, '0')}:'
        '${ecuadorDate.minute.toString().padLeft(2, '0')}',
      );

      return TimeOfDay(hour: ecuadorDate.hour, minute: ecuadorDate.minute);
    }

    // ----------------------------------------------------------
    // Buscar HH:mm dentro del texto
    // ----------------------------------------------------------

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);

    if (match == null) {
      return null;
    }

    final hourText = match.group(1);
    final minuteText = match.group(2);

    if (hourText == null || minuteText == null) {
      return null;
    }

    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23) {
      return null;
    }

    if (minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ============================================================
  // OPCIONES DE RESERVA
  // ============================================================

  Future<void> _showReservationOptions({
    required int people,
    required DateTime date,
    required TimeOfDay time,
    required List<dynamic> mesas,
  }) async {
    if (!mounted) {
      return;
    }

    final ecuadorDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final utcDateTime = _ecuadorToUtc(ecuadorDateTime);

    debugPrint('========================================');
    debugPrint('AI - RESERVA DETECTADA');
    debugPrint('Personas: $people');

    debugPrint(
      'Fecha Ecuador: '
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}',
    );

    debugPrint(
      'Hora Ecuador: '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}',
    );

    debugPrint('UTC: ${utcDateTime.toIso8601String()}');

    debugPrint('Mesas disponibles: ${mesas.length}');

    debugPrint('========================================');

    // ----------------------------------------------------------
    // SI NO HAY MESAS
    // ----------------------------------------------------------

    if (mesas.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // MOSTRAR MESAS
    // ----------------------------------------------------------

    final selectedTable = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TableSelectionSheet(
          mesas: mesas,
          people: people,
          date: date,
          time: time,
        );
      },
    );

    if (!mounted || selectedTable == null) {
      return;
    }

    // ----------------------------------------------------------
    // OBTENER ID
    // ----------------------------------------------------------

    int? tableId;

    if (selectedTable is Map) {
      final rawId = selectedTable['id'];

      if (rawId is int) {
        tableId = rawId;
      } else if (rawId is num) {
        tableId = rawId.toInt();
      } else {
        tableId = int.tryParse(rawId?.toString() ?? '');
      }
    }

    if (tableId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible identificar la mesa seleccionada.'),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // PASAR DATOS A NUEVA RESERVA
    // ----------------------------------------------------------

    CreateReservationPage.draftPeople = people.toString();

    CreateReservationPage.draftDate = DateTime(date.year, date.month, date.day);

    CreateReservationPage.draftTime = TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    );

    CreateReservationPage.draftTableId = tableId;

    debugPrint('AI - MESA SELECCIONADA: $tableId');

    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(context, '/app/reservas/nueva');

    // ----------------------------------------------------------
    // LIMPIAR BORRADOR
    // ----------------------------------------------------------

    CreateReservationPage.draftTableId = null;
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // LIMPIAR CHAT
  // ============================================================

  void _clearChat() {
    if (_sending) {
      return;
    }

    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });

    _scrollToBottom();
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(_messages[index]);
                      },
                    ),
            ),

            _buildQuickQuestions(),

            if (_sending) _buildTypingIndicator(),

            _buildInput(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREGUNTAS RÁPIDAS
  // ============================================================

  Widget _buildQuickQuestions() {
    if (_sending || _quickQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preguntas rápidas',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickQuestions.length,
              separatorBuilder: (_, index) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final question = _quickQuestions[index];

                return OutlinedButton(
                  onPressed: () => _sendQuestion(question),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD9B4BA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                  ),
                  child: Text(
                    question,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,

      leading: IconButton(
        tooltip: 'Regresar',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textColor,
          size: 21,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),

      titleSpacing: 0,

      title: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente Leña',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Reservas y disponibilidad',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        IconButton(
          tooltip: 'Limpiar conversación',
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: _textColor,
            size: 23,
          ),
          onPressed: _messages.length > 1 && !_sending ? _clearChat : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  Widget _buildMessage(_ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAssistantAvatar(),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE7E9ED)),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Text(
                    message.text,
                    softWrap: true,
                    style: TextStyle(
                      color: isUser ? Colors.white : _textColor,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (message.time != null)
            Padding(
              padding: EdgeInsets.only(
                top: 5,
                left: isUser ? 0 : 47,
                right: isUser ? 5 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatChatTime(message.time),
                    style: const TextStyle(
                      color: Color(0xFF8792A3),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (isUser) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      color: Color(0xFF8792A3),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),

          if (!isUser && message.mesas != null && message.mesas!.isNotEmpty)
            _buildAvailableTables(
              message.mesas!,
              people: message.people,
              date: message.date,
              time: message.timeOfDay,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAssistantAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  // ============================================================
  // ESCRIBIENDO
  // ============================================================

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
      child: Row(
        children: [
          _buildTypingDot(),
          const SizedBox(width: 5),
          _buildTypingDot(),
          const SizedBox(width: 5),
          _buildTypingDot(),
          const SizedBox(width: 9),
          const Text(
            'Asistente escribiendo...',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: _primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // MESAS DISPONIBLES
  // ============================================================

  Widget _buildAvailableTables(
    List<dynamic> mesas, {
    int? people,
    DateTime? date,
    TimeOfDay? time,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 46, top: 9),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE1E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E7EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_seat_rounded,
                  size: 20,
                  color: _primaryColor,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Mesas disponibles',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E7EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${mesas.length}',
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (people != null && date != null && time != null) ...[
            const SizedBox(height: 9),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: _secondaryTextColor,
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      '$people personas • '
                      '${_formatDate(date)} • '
                      '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          ...mesas.map(
            (mesa) =>
                _buildTableItem(mesa, people: people, date: date, time: time),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESA
  // ============================================================

  Widget _buildTableItem(
    dynamic mesa, {
    int? people,
    DateTime? date,
    TimeOfDay? time,
  }) {
    String numero = '';
    String capacidad = '';

    if (mesa is Map) {
      numero = mesa['numero']?.toString() ?? '';

      capacidad = mesa['capacidad']?.toString() ?? '';
    }

    final hasReservationData = people != null && date != null && time != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7AEB6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasReservationData
              ? () => _selectTableFromCard(
                  mesa,
                  people: people,
                  date: date,
                  time: time,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E7EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_rounded,
                    color: _primaryColor,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa $numero',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '$capacidad personas',
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasReservationData) ...[
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Elegir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECCIONAR MESA DESDE LA TARJETA
  // ============================================================

  Future<void> _selectTableFromCard(
    dynamic mesa, {
    required int people,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    int? tableId;

    if (mesa is Map) {
      final rawId = mesa['id'];

      if (rawId is int) {
        tableId = rawId;
      } else if (rawId is num) {
        tableId = rawId.toInt();
      } else {
        tableId = int.tryParse(rawId?.toString() ?? '');
      }
    }

    if (tableId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible identificar la mesa.')),
      );

      return;
    }

    CreateReservationPage.draftPeople = people.toString();

    CreateReservationPage.draftDate = DateTime(date.year, date.month, date.day);

    CreateReservationPage.draftTime = TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    );

    CreateReservationPage.draftTableId = tableId;

    debugPrint(
      'AI - MESA SELECCIONADA DESDE TARJETA: '
      '$tableId',
    );

    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(context, '/app/reservas/nueva');

    CreateReservationPage.draftTableId = null;
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9DEE6)),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: !_sending,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    hintStyle: TextStyle(
                      color: Color(0xFF8995A6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6B7B91),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Material(
              color: _sending ? Colors.grey.shade400 : _primaryColor,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _sending ? null : _sendMessage,
                child: SizedBox(
                  width: 49,
                  height: 49,
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// COLORES DEL SELECTOR DE MESAS
// ==================================================================
//
// IMPORTANTE:
// _TableSelectionSheet está fuera de _AIPageState.
// Por eso utiliza estos colores globales y no los privados
// de _AIPageState.
//

const Color _aiPrimaryColor = Color(0xFF94152A);
const Color _aiTextColor = Color(0xFF172033);
const Color _aiSecondaryTextColor = Color(0xFF68778D);

// ==================================================================
// HOJA PARA SELECCIONAR MESA
// ==================================================================

class _TableSelectionSheet extends StatelessWidget {
  const _TableSelectionSheet({
    required this.mesas,
    required this.people,
    required this.date,
    required this.time,
  });

  final List<dynamic> mesas;
  final int people;
  final DateTime date;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final timeText =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // INDICADOR SUPERIOR
            // ----------------------------------------------------
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D8DD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // TÍTULO
            // ----------------------------------------------------
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E7EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_rounded,
                    color: _aiPrimaryColor,
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Selecciona una mesa',
                    style: TextStyle(
                      color: _aiTextColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // INFORMACIÓN DE RESERVA
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 17,
                    color: _aiSecondaryTextColor,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      '$people personas • '
                      '$dateText • '
                      '$timeText',
                      style: const TextStyle(
                        color: _aiSecondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // LISTA DE MESAS
            // ----------------------------------------------------
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: mesas.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final mesa = mesas[index];

                  String numero = '';
                  String capacidad = '';

                  if (mesa is Map) {
                    numero = mesa['numero']?.toString() ?? '';

                    capacidad = mesa['capacidad']?.toString() ?? '';
                  }

                  return Material(
                    color: const Color(0xFFFFFBFC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context, mesa);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD7AEB6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8E7EA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.table_restaurant_rounded,
                                color: _aiPrimaryColor,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mesa $numero',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _aiTextColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    '$capacidad personas',
                                    style: const TextStyle(
                                      color: _aiSecondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _aiPrimaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // CANCELAR
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _aiPrimaryColor,
                  side: const BorderSide(color: Color(0xFFD7AEB6)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
