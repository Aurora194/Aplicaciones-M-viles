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
  });

  final String text;
  final bool isUser;
  final DateTime? time;
  final List<dynamic>? mesas;
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
          'Hola, soy Asistente Leña. Puedo ayudarte a consultar reservas, '
          'gestionar mesas y conocer las funciones administrativas de la aplicación.';
    } else {
      text =
          'Hola, soy Asistente Leña. Puedo ayudarte con tus reservas, '
          'mesas disponibles y las funciones de Leña Reserva.';
    }

    _messages.add(
      _ChatMessage(text: text, isUser: false, time: DateTime.now()),
    );
  }

  // ============================================================
  // ECUADOR - UTC-5
  // ============================================================

  DateTime _ecuadorNow() {
    final utc = DateTime.now().toUtc();

    final ecuador = utc.subtract(const Duration(hours: 5));

    return DateTime(
      ecuador.year,
      ecuador.month,
      ecuador.day,
      ecuador.hour,
      ecuador.minute,
      ecuador.second,
      ecuador.millisecond,
      ecuador.microsecond,
    );
  }

  DateTime _ecuadorToday() {
    final now = _ecuadorNow();

    return DateTime(now.year, now.month, now.day);
  }

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
      (_) => '• ',
    );

    result = result.replaceAllMapped(
      RegExp(r'^\s*#+\s*', multiLine: true),
      (_) => '',
    );

    result = result.replaceAllMapped(
      RegExp(r'^[ \t]+', multiLine: true),
      (_) => '',
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
  // ENVIAR PREGUNTA RÁPIDA
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
      final result = await ApiService.askAI(token: token, message: message);

      final answer = _cleanMarkdown(result.answer);

      // ----------------------------------------------------------
      // MESAS DISPONIBLES
      // ----------------------------------------------------------

      List<dynamic>? mesas;

      final availability = result.availability;

      final rawMesas = _mapValue(availability, 'mesas');

      if (rawMesas is List) {
        mesas = List<dynamic>.from(rawMesas);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: answer,
            isUser: false,
            time: DateTime.now(),
            mesas: mesas,
          ),
        );
      });

      _scrollToBottom();

      // ----------------------------------------------------------
      // BORRADOR DE RESERVA
      // ----------------------------------------------------------

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
      debugPrint(
        'AI - HORA PARSEADA ECUADOR: '
        '${time?.hour.toString().padLeft(2, '0')}:'
        '${time?.minute.toString().padLeft(2, '0')}',
      );

      if (people != null && date != null && time != null) {
        await _openReservationDraft(people: people, date: date, time: time);
      }
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

      if (exception.statusCode == 401) {
        await auth.signOut();

        if (!mounted) {
          return;
        }

        Navigator.pushReplacementNamed(context, '/login', arguments: '/app/ai');

        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: exception.message,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'No pude procesar tu solicitud en este momento. '
                'Verifica tu conexión e inténtalo nuevamente.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();

      debugPrint('AI - ERROR: $e');
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

    return int.tryParse(text);
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
    // FECHA SIMPLE:
    // 2026-09-17
    // ----------------------------------------------------------

    final simpleDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);

    if (simpleDate != null) {
      final year = int.tryParse(simpleDate.group(1)!);
      final month = int.tryParse(simpleDate.group(2)!);
      final day = int.tryParse(simpleDate.group(3)!);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    // ----------------------------------------------------------
    // FECHA ISO
    // ----------------------------------------------------------

    final parsedDate = DateTime.tryParse(text);

    if (parsedDate == null) {
      return null;
    }

    // Si viene con Z/UTC, convertir explícitamente a Ecuador.
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
    // CASO 1:
    // Hora normal enviada por la IA.
    //
    // Ejemplo:
    // 20:00
    // 20:00:00
    //
    // Esta hora YA representa Ecuador.
    // NO hacer toLocal() ni toUtc().
    // ----------------------------------------------------------

    final simpleMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(text);

    if (simpleMatch != null) {
      final hour = int.tryParse(simpleMatch.group(1)!);
      final minute = int.tryParse(simpleMatch.group(2)!);

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
    // CASO 2:
    // La IA/backend devuelve una fecha ISO.
    //
    // Ejemplo:
    // 2026-09-18T01:00:00.000Z
    //
    // En este caso sí debemos convertir UTC -> Ecuador.
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
    // CASO 3:
    // Buscar HH:mm dentro de otro texto.
    // ----------------------------------------------------------

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);

    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);

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
      'AI - HORA ENCONTRADA EN TEXTO: '
      '$hour:$minute',
    );

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ============================================================
  // ABRIR RESERVA
  // ============================================================

  Future<void> _openReservationDraft({
    required int people,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    // La fecha que llega aquí representa ECUADOR.
    final ecuadorDate = DateTime(date.year, date.month, date.day);

    // La hora también representa ECUADOR.
    final ecuadorDateTime = DateTime(
      ecuadorDate.year,
      ecuadorDate.month,
      ecuadorDate.day,
      time.hour,
      time.minute,
    );

    // Solamente para comprobar qué se enviará posteriormente.
    final utcDateTime = _ecuadorToUtc(ecuadorDateTime);

    debugPrint('========================================');
    debugPrint('AI - BORRADOR DE RESERVA');
    debugPrint(
      'AI - ECUADOR: '
      '${ecuadorDateTime.year}-'
      '${ecuadorDateTime.month.toString().padLeft(2, '0')}-'
      '${ecuadorDateTime.day.toString().padLeft(2, '0')} '
      '${ecuadorDateTime.hour.toString().padLeft(2, '0')}:'
      '${ecuadorDateTime.minute.toString().padLeft(2, '0')}',
    );
    debugPrint('AI - UTC: ${utcDateTime.toIso8601String()}');
    debugPrint('AI - PERSONAS: $people');
    debugPrint('========================================');

    CreateReservationPage.draftPeople = people.toString();

    CreateReservationPage.draftDate = ecuadorDate;

    CreateReservationPage.draftTime = TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    );

    CreateReservationPage.draftTableId = null;

    if (!mounted) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    Navigator.pushNamed(context, '/app/reservas/nueva');
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
              separatorBuilder: (_, __) {
                return const SizedBox(width: 7);
              },
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
      toolbarHeight: 72,
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
                  'Asistente para reservas y disponibilidad',
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
            _buildAvailableTables(message.mesas!),
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

  Widget _buildAvailableTables(List<dynamic> mesas) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 46, top: 9),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
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
          const Row(
            children: [
              Icon(Icons.event_seat_rounded, size: 20, color: _primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mesas disponibles',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...mesas.map(_buildTableItem),
        ],
      ),
    );
  }

  // ============================================================
  // MESA
  // ============================================================

  Widget _buildTableItem(dynamic mesa) {
    String numero = '';
    String capacidad = '';

    if (mesa is Map) {
      numero = mesa['numero']?.toString() ?? '';
      capacidad = mesa['capacidad']?.toString() ?? '';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFB98992)),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
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
            child: Text(
              'Mesa $numero',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$capacidad personas',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
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
                  hintStyle: TextStyle(color: Color(0xFF8995A6), fontSize: 14),
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
    );
  }
}
