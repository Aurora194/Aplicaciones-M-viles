import 'dart:async';
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

  final List<dynamic>? mesas;

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

  String _formatDateContext(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final tomorrow = today.add(const Duration(days: 1));

    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Hoy · ${_formatDate(date)}';
    }

    if (selected == tomorrow) {
      return 'Mañana · ${_formatDate(date)}';
    }

    return _formatDate(date);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
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
      debugPrint('AI - Enviando consulta...');
      debugPrint('AI - API: ${ApiService.baseUrl}');
      debugPrint('AI - Autenticación disponible: ${token.isNotEmpty}');

      final result = await ApiService.askAI(token: token, message: message);

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

      // ========================================================
      // BORRADOR DE RESERVA
      // ========================================================

      final draft = result.reservationDraft;

      final peopleValue = _mapValue(draft, 'people');

      final dateValue = _mapValue(draft, 'date');

      final timeValue = _mapValue(draft, 'time');

      final people = _parsePeople(peopleValue);
      final date = _parseDate(dateValue);
      final time = _parseTime(timeValue);

      if (!mounted) {
        return;
      }

      // ========================================================
      // RESPUESTA DEL ASISTENTE
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
      //
      // IMPORTANTE:
      // NO seleccionamos ninguna mesa.
      // Solo mostramos el botón para ir a Nueva reserva.
      // ========================================================

      if (people != null && date != null && time != null) {
        await _showReservationOptions(people: people, date: date, time: time);
      }
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

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
            'Verifica que el backend esté funcionando '
            'e inténtalo nuevamente.';
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
    } on SocketException {
      if (!mounted) {
        return;
      }

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
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'El asistente está tardando demasiado en responder. '
                'El servidor puede estar procesando la solicitud. '
                'Inténtalo nuevamente en unos segundos.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } on FormatException {
      if (!mounted) {
        return;
      }

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
    } catch (_) {
      if (!mounted) {
        return;
      }

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

      return TimeOfDay(hour: hour, minute: minute);
    }

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

      return TimeOfDay(hour: ecuadorDate.hour, minute: ecuadorDate.minute);
    }

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
  //
  // Ya NO selecciona mesa.
  // Solo muestra los datos detectados y permite
  // enviarlos a Nueva reserva.
  // ============================================================

  Future<void> _showReservationOptions({
    required int people,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ReservationDraftSheet(
          people: people,
          date: date,
          time: time,
          onSelectTable: () async {
            Navigator.pop(sheetContext);

            await _openNewReservation(people: people, date: date, time: time);
          },
        );
      },
    );
  }

  // ============================================================
  // IR A NUEVA RESERVA
  // ============================================================

  Future<void> _openNewReservation({
    required int people,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    // ==========================================================
    // IMPORTANTE:
    // La mesa SIEMPRE queda en null.
    // Nueva reserva será la encargada de seleccionarla.
    // ==========================================================

    CreateReservationPage.draftPeople = people.toString();

    CreateReservationPage.draftDate = DateTime(date.year, date.month, date.day);

    CreateReservationPage.draftTime = TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    );

    CreateReservationPage.draftTableId = null;

    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(context, '/app/reservas/nueva');

    // Al regresar dejamos explícitamente
    // la mesa sin selección.
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
          if (!isUser &&
              message.people != null &&
              message.date != null &&
              message.timeOfDay != null)
            _buildReservationDetectedCard(
              people: message.people!,
              date: message.date!,
              time: message.timeOfDay!,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA DE RESERVA DETECTADA
  // ============================================================

  Widget _buildReservationDetectedCard({
    required int people,
    required DateTime date,
    required TimeOfDay time,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 46, top: 10),
      padding: const EdgeInsets.all(13),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E7EA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: _primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Datos de la reserva',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                _buildReservationInfoRow(
                  icon: Icons.people_alt_outlined,
                  label: 'Personas',
                  value: '$people',
                ),
                const SizedBox(height: 8),
                _buildReservationInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: _formatDateContext(date),
                ),
                const SizedBox(height: 8),
                _buildReservationInfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Hora',
                  value: _formatTimeOfDay(time),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La mesa se seleccionará en la pantalla de nueva reserva.',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openNewReservation(people: people, date: date, time: time);
              },
              icon: const Icon(Icons.table_restaurant_rounded, size: 19),
              label: const Text('Seleccionar mesa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _secondaryTextColor),
        const SizedBox(width: 7),
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
// COLORES DEL PANEL DE RESERVA
// ==================================================================

const Color _draftPrimaryColor = Color(0xFF94152A);

const Color _draftTextColor = Color(0xFF172033);

const Color _draftSecondaryTextColor = Color(0xFF68778D);

// ==================================================================
// PANEL DE DATOS DE RESERVA
// ==================================================================

class _ReservationDraftSheet extends StatelessWidget {
  const _ReservationDraftSheet({
    required this.people,
    required this.date,
    required this.time,
    required this.onSelectTable,
  });

  final int people;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onSelectTable;

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateContext(DateTime value) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final tomorrow = today.add(const Duration(days: 1));

    final selected = DateTime(value.year, value.month, value.day);

    if (selected == today) {
      return 'Hoy · ${_formatDate(value)}';
    }

    if (selected == tomorrow) {
      return 'Mañana · ${_formatDate(value)}';
    }

    return _formatDate(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E7EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: _draftPrimaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reserva detectada',
                    style: TextStyle(
                      color: _draftTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa los datos antes de seleccionar la mesa.',
              style: TextStyle(
                color: _draftSecondaryTextColor,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E5EA)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.people_alt_outlined,
                    title: 'Personas',
                    value: '$people personas',
                  ),
                  const SizedBox(height: 11),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Fecha',
                    value: _formatDateContext(date),
                  ),
                  const SizedBox(height: 11),
                  _buildInfoRow(
                    icon: Icons.access_time_rounded,
                    title: 'Hora',
                    value: _formatTime(time),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ====================================================
            // BOTÓN SOLICITADO
            // ====================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSelectTable,
                icon: const Icon(Icons.table_restaurant_rounded, size: 19),
                label: const Text('Seleccionar mesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _draftPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ====================================================
            // CANCELAR
            // ====================================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _draftPrimaryColor,
                  side: const BorderSide(color: Color(0xFFD7AEB6)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: _draftPrimaryColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _draftSecondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _draftTextColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
