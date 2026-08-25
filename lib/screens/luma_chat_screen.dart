import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../models/consultation_model.dart';
import '../models/conversation_models.dart';
import '../widgets/global_drawer.dart';
import '../widgets/checkup_heart_widget.dart';
import '../widgets/user_avatar.dart';
import '../widgets/navbar_new.dart';
import 'profile_screen.dart';
import 'user_chat_screen.dart';
import 'main_navigation.dart';

class LumaChatScreen extends StatefulWidget {
  final String mode;

  const LumaChatScreen({super.key, this.mode = 'PATIENT'});

  @override
  State<LumaChatScreen> createState() => _LumaChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? content;

  ChatMessage({required this.text, this.isUser = false, this.content});
}

class PsychologistProfile {
  final String name;
  final double rating;
  final String approach;
  final String mode;
  final String availability;
  final String location;
  final String summary;

  const PsychologistProfile({
    required this.name,
    required this.rating,
    required this.approach,
    required this.mode,
    required this.availability,
    required this.location,
    required this.summary,
  });

  Map<String, dynamic> toPromptMap() {
    return {
      'name': name,
      'approach': approach,
      'mode': mode,
      'availability': availability,
      'location': location,
      'summary': summary,
      'rating': rating,
    };
  }
}

class _LumaChatScreenState extends State<LumaChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [];

  String _userName = '';
  Uint8List? _headerImageBytes;
  bool _isLoading = false;
  bool _hasRecommended = false;
  final Map<String, String> _collectedInfo = {};
  final List<Consultation> _todayConsultations = [];
  List<Map<String, dynamic>> _registeredPsychologists = [];
  bool _catalogLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserName();
      await _loadHeaderImage();
      await _loadAppointmentsContext();
      await _loadRegisteredPsychologists();
      _addLumaMessage(
        _buildInitialGreeting(),
        content: widget.mode == 'PSYCHOLOGIST' && _todayConsultations.isNotEmpty
            ? _buildAppointmentCards()
            : null,
      );
    });
  }

  String _buildInitialGreeting() {
    if (widget.mode == 'PSYCHOLOGIST') {
      final prefix = _userName.isNotEmpty ? 'Dr. $_userName' : 'Psicólogo';
      if (_todayConsultations.isNotEmpty) {
        return 'Olá, $prefix. Eu sou a Luma assistente e vi ${_todayConsultations.length} consulta(s) agendada(s) na lista de registros. Posso ajudar a organizar a agenda e preparar mensagens para esses atendimentos.';
      }

      return 'Olá, $prefix. Eu sou a Luma assistente e posso ajudar a organizar sua agenda e preparar mensagens quando houver consultas agendadas.';
    }

    return 'Olá! Eu sou a Luma. Vou conversar com você para entender seu momento e indicar o psicólogo ideal. Pode me contar com suas palavras: o que mais está te incomodando hoje?';
  }

  Future<void> _loadUserName() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final userProfile = await firebaseService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userName = userProfile?['name'] ?? authService.currentUser?.displayName ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name in LumaChat: $e');
    }
  }

  Future<void> _loadHeaderImage() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final userProfile = await firebaseService.getUserProfile(userId);
        final base64 = userProfile?['profileImageBase64'] as String?;
        if (base64 != null && base64.isNotEmpty) {
          try {
            final bytes = base64Decode(base64);
            if (mounted) {
              setState(() {
                _headerImageBytes = bytes;
              });
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error loading header image in LumaChat: $e');
    }
  }

  Future<void> _loadAppointmentsContext() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId == null) return;

      final role = (widget.mode == 'PSYCHOLOGIST') ? 'PSYCHOLOGIST' : 'PATIENT';
      // A agenda da Luma deve incluir consultas futuras, não somente as de hoje.
      final consultations = await firebaseService.getUpcomingConsultationsForUser(userId, role);
      if (!mounted) return;

      setState(() {
        _todayConsultations
          ..clear()
          ..addAll(consultations);
      });
    } catch (e) {
      debugPrint('Error loading appointments context in LumaChat: $e');
    }
  }

  Future<void> _loadRegisteredPsychologists() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final catalog = await firebaseService.getRegisteredPsychologists();
      if (!mounted) return;
      setState(() {
        _registeredPsychologists = catalog;
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registeredPsychologists = [];
        _catalogLoading = false;
      });
      debugPrint('Error loading registered psychologists in LumaChat: $e');
    }
  }

  List<PsychologistProfile> _buildPsychologistProfiles() {
    return _registeredPsychologists.map((data) {
      final name = data['name']?.toString() ?? 'Profissional';
      final specialty = data['specialty']?.toString() ?? '';
      final modality = data['modality']?.toString() ?? '';
      final availability = data['availability']?.toString() ?? '';
      final location = data['officeAddress']?.toString() ?? '';
      final summary = data['personalizedMessage']?.toString().isNotEmpty == true
          ? data['personalizedMessage'].toString()
          : specialty.isNotEmpty
              ? specialty
              : 'Psicólogo cadastrado na aplicação.';
      final parsedRating = double.tryParse(data['rating']?.toString() ?? '');
      return PsychologistProfile(
        name: name,
        rating: parsedRating ?? 4.8,
        approach: specialty.isNotEmpty ? specialty : 'Atendimento psicológico',
        mode: modality.isNotEmpty ? modality : 'Online e presencial',
        availability: availability.isNotEmpty ? availability : 'A combinar',
        location: location.isNotEmpty ? location : 'A combinar',
        summary: summary,
      );
    }).toList();
  }

  String _buildAppointmentsContext() {
    if (_todayConsultations.isEmpty) {
      return 'Nenhuma consulta futura agendada.';
    }

    return _todayConsultations.map((consultation) {
      final patientName = consultation.patientName?.trim().isNotEmpty == true ? consultation.patientName : 'Paciente';
      final psychologistName = consultation.psychologistName?.trim().isNotEmpty == true ? consultation.psychologistName : 'Psicólogo';
      final specialty = consultation.psychologistSpecialty?.trim().isNotEmpty == true ? consultation.psychologistSpecialty : '';
      final modality = consultation.psychologistModality?.trim().isNotEmpty == true ? consultation.psychologistModality : '';
      final availability = consultation.psychologistAvailability?.trim().isNotEmpty == true ? consultation.psychologistAvailability : '';
      return '- $patientName com $psychologistName em ${consultation.hour} (${consultation.modality}, ${consultation.status})${specialty != '' ? ' • Especialidade: $specialty' : ''}${modality != '' ? ' • Atendimento: $modality' : ''}${availability != '' ? ' • Disponibilidade: $availability' : ''}';
    }).join('\n');
  }

  bool _isAppointmentInteraction(String message) {
    final normalized = message.toLowerCase().trim();
    const appointmentTerms = [
      'consulta',
      'consultas',
      'agendamento',
      'agendada',
      'agendado',
    ];
    return appointmentTerms.any(normalized.contains) ||
        (normalized.contains('hoje') &&
            (normalized.contains('tenho') || normalized.contains('psicólogo') || normalized.contains('psicologo')));
  }

  String _buildPatientAppointmentReply(String message) {
    if (_todayConsultations.isEmpty) {
      return 'Não encontrei nenhuma consulta registrada para você. Se quiser, posso continuar nossa conversa para entender o que você está sentindo e ajudar a encontrar um psicólogo.';
    }

    final asksToday = message.toLowerCase().contains('hoje');
    final today = DateTime.now();
    final consultations = asksToday
        ? _todayConsultations.where((consultation) {
            final date = DateTime.fromMillisecondsSinceEpoch(consultation.date);
            return date.year == today.year && date.month == today.month && date.day == today.day;
          }).toList()
        : _todayConsultations;

    if (consultations.isEmpty) {
      return 'Não encontrei consulta registrada para hoje. Posso te mostrar suas próximas consultas ou continuar nossa conversa sobre como você está se sentindo.';
    }

    final details = consultations.map((consultation) {
      final date = DateTime.fromMillisecondsSinceEpoch(consultation.date);
      final dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final psychologist = consultation.psychologistName?.trim().isNotEmpty == true
          ? consultation.psychologistName!.trim()
          : 'seu psicólogo';
      return '$dateLabel às ${consultation.hour} com $psychologist (${_modalityLabel(consultation.modality).toLowerCase()})';
    }).join('; ');

    return consultations.length == 1
        ? 'Sim. Você tem uma consulta registrada para $details.'
        : 'Encontrei ${consultations.length} consultas registradas: $details.';
  }

  Widget _buildAppointmentCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _todayConsultations
          .map((consultation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAppointmentCard(consultation),
              ))
          .toList(),
    );
  }

  Widget _buildAppointmentCard(Consultation consultation) {
    final patientName = consultation.patientName?.trim().isNotEmpty == true
        ? consultation.patientName!.trim()
        : 'Paciente';
    final date = DateTime.fromMillisecondsSinceEpoch(consultation.date);
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAppointmentDetails(consultation),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Colors.green.shade400,
                child: const Icon(Icons.person_outline, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateLabel • ${consultation.hour} • ${_modalityLabel(consultation.modality)}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }

  String _modalityLabel(String modality) {
    switch (modality) {
      case 'CALL':
        return 'Online';
      case 'IN_PERSON':
        return 'Presencial';
      case 'MESSAGE':
        return 'Mensagem';
      default:
        return modality.isEmpty ? 'A combinar' : modality;
    }
  }

  void _showAppointmentDetails(Consultation consultation) {
    final patientName = consultation.patientName?.trim().isNotEmpty == true
        ? consultation.patientName!.trim()
        : 'Paciente';
    final date = DateTime.fromMillisecondsSinceEpoch(consultation.date);
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.green.shade400,
                child: const Icon(Icons.person_outline, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 14),
              Text(
                patientName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.green.shade900.withOpacity(0.35) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    _buildDetailLine('Atendimento', _modalityLabel(consultation.modality)),
                    const SizedBox(height: 6),
                    _buildDetailLine('Dia', dateLabel),
                    const SizedBox(height: 6),
                    _buildDetailLine('Horário', consultation.hour.isEmpty ? 'A combinar' : consultation.hour),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openPatientChat(consultation, patientName);
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Abrir conversa com o paciente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(color: Colors.green.shade800, fontSize: 13),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  void _openPatientChat(Consultation consultation, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          otherUser: ChatUser(id: consultation.idPatient, name: patientName),
        ),
      ),
    );
  }

  void _addLumaMessage(String text, {Widget? content}) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: false, content: content));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _buildConversationContext() {
    final ordered = _messages.reversed.toList();
    return ordered
        .map((msg) => '${msg.isUser ? 'Usuário' : 'Luma'}: ${msg.text}')
        .join('\n');
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _addUserMessage(text);
    _controller.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.mode == 'PSYCHOLOGIST') {
        final reply = await _geminiService.generatePsychologistAssistantResponse(
          userMessage: text,
          conversationContext: _buildConversationContext(),
          userName: _userName.isNotEmpty ? _userName : null,
          contextData: {
            ..._collectedInfo,
            'consultas_de_hoje': _buildAppointmentsContext(),
          },
        );
        _addLumaMessage(reply);
      } else {
        final psychologistProfiles = _buildPsychologistProfiles();
        if (psychologistProfiles.isEmpty || _catalogLoading) {
          _addLumaMessage('Ainda não encontrei psicólogos cadastrados na aplicação para recomendar. Assim que houver profissionais registrados, eu consigo fazer a triagem com base no que eles configuraram.');
          return;
        }

        final triageResult = await _geminiService.generatePsychologistTriageResponse(
          userMessage: text,
          conversationContext: _buildConversationContext(),
          collectedInfo: {
            ..._collectedInfo,
            'consultas_agendadas': _buildAppointmentsContext(),
          },
          userName: _userName.isNotEmpty ? _userName : null,
          psychologistOptions: _registeredPsychologists,
        );

        final extracted = triageResult['extracted_info'];
        final interactionType = triageResult['interaction_type']?.toString().toLowerCase();
        if (interactionType != 'agenda' && extracted is Map) {
          extracted.forEach((key, value) {
            final parsed = value?.toString().trim() ?? '';
            if (parsed.isNotEmpty) {
              _collectedInfo[key.toString()] = parsed;
            }
          });
        }

        final reply = (triageResult['assistant_reply']?.toString().trim().isNotEmpty ?? false)
            ? triageResult['assistant_reply'].toString().trim()
            : 'Entendi. Quero te ajudar com cuidado. Pode me contar um pouco mais sobre seu momento atual?';

        _addLumaMessage(reply);

        final ready = interactionType != 'agenda' && triageResult['ready_for_recommendation'] == true;
        if (ready && !_hasRecommended) {
          final recommended = _resolveRecommendedProfile(triageResult['recommended_psychologist']);
          setState(() {
            _hasRecommended = true;
          });
          _addLumaMessage(
            'Com base no que você compartilhou, encontrei um profissional que combina com o seu momento:',
            content: _buildProfessionalCard(recommended),
          );
        }
      }
    } catch (e) {
      _addLumaMessage(widget.mode == 'PSYCHOLOGIST'
          ? (_todayConsultations.isNotEmpty
              ? 'Posso ajudar com agenda, pacientes e mensagens. O que você quer organizar agora?'
              : 'Não encontrei consultas agendadas para hoje. Posso ajudar com a organização da agenda quando houver atendimentos.')
          : 'Desculpe, tive uma instabilidade agora. Podemos continuar? Me conta mais sobre como você está se sentindo.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  PsychologistProfile _resolveRecommendedProfile(dynamic raw) {
    if (raw is Map) {
      final name = raw['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        for (final p in _buildPsychologistProfiles()) {
          if (p.name.toLowerCase() == name.toLowerCase()) {
            return p;
          }
        }

        return PsychologistProfile(
          name: name,
          rating: double.tryParse(raw['rating']?.toString() ?? '') ?? 4.8,
          approach: raw['approach']?.toString() ?? 'Abordagem personalizada',
          mode: raw['mode']?.toString() ?? 'Online e Presencial',
          availability: raw['availability']?.toString() ?? 'A combinar',
          location: raw['location']?.toString() ?? 'A combinar',
          summary: raw['summary']?.toString() ?? 'Indicação baseada no seu contexto atual.',
        );
      }
    }

    final profiles = _buildPsychologistProfiles();
    if (profiles.isNotEmpty) return profiles.first;
    return const PsychologistProfile(
      name: 'Profissional',
      rating: 4.8,
      approach: 'Atendimento psicológico',
      mode: 'Online e presencial',
      availability: 'A combinar',
      location: 'A combinar',
      summary: 'Psicólogo cadastrado na aplicação.',
    );
  }

  Widget _buildProfessionalCard(PsychologistProfile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showProfessionalModal(profile),
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(10.0),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        width: double.infinity,
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, color: Colors.green.shade700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.approach,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 6), Text(profile.rating.toStringAsFixed(1))]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.green.shade700)
          ],
        ),
      ),
    );
  }

  void _showProfessionalModal(PsychologistProfile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 42, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, size: 40, color: Colors.green.shade700)),
                const SizedBox(height: 12),
                Text(profile.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Text('Avaliação: ${profile.rating.toStringAsFixed(1)}/5', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.green.shade100), borderRadius: BorderRadius.circular(8), color: isDark ? const Color(0xFF1E1E1E) : Colors.green.shade50),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Abordagem: ${profile.approach}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Atendimento: ${profile.mode}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Localização: ${profile.location}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Disponibilidade: ${profile.availability}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final profileMap = profile.toPromptMap();
                      try {
                        context.go('/scheduleAppointment', extra: profileMap);
                      } catch (_) {
                        Navigator.pushNamed(context, '/scheduleAppointment', arguments: profileMap);
                      }
                    },
                    child: const Text('Marcar consulta'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleAiColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerSurface = isDark ? const Color(0xFF171717) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      drawer: GlobalDrawer(userRole: widget.mode),
      appBar: AppBar(
        toolbarHeight: 88,
        elevation: 0,
        backgroundColor: headerSurface,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MindMatch', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                widget.mode == 'PSYCHOLOGIST' ? _getPsychologistGreeting() : _getGreeting(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          const Padding(padding: EdgeInsets.only(right: 12.0), child: CheckupHeartWidget()),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _showProfileOptions(),
              child: UserAvatar(
                imageBytes: _headerImageBytes,
                radius: 18,
                useAuthPhoto: true,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: CustomNavbar(
        selectedIndex: MainNavigation.lastTabIndex,
        onItemTapped: (index) {
          Navigator.of(context).pop();
          MainNavigation.switchTab(index);
        },
        // A Luma jÃ¡ estÃ¡ aberta; tocar no avatar central nÃ£o cria outra tela.
        onCenterAvatarTap: () {},
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: _messages.isEmpty
                ? Center(child: Text(widget.mode == 'PSYCHOLOGIST' ? 'Converse com a Luma assistente' : 'Converse com a Luma', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)))
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!msg.isUser) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    backgroundImage: const AssetImage('assets/images/oiLuma.png'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (msg.text.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: msg.isUser ? Colors.green.shade600 : bubbleAiColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            msg.text,
                                            style: TextStyle(color: msg.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87)),
                                          ),
                                        ),
                                      if (msg.content != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: msg.content!,
                                        ),
                                    ],
                                  ),
                                ),
                                if (msg.isUser) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(radius: 16, backgroundColor: Colors.green.shade700, child: const Icon(Icons.person, color: Colors.white, size: 16)),
                                ]
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(color: scheme.onSurface.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    UserAvatar(imageBytes: _headerImageBytes, radius: 28, useAuthPhoto: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Meu Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                        const SizedBox(height: 4),
                        Text('Gerencie sua conta', style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.edit, color: scheme.primary)),
                  title: const Text('Ver Perfil'),
                  subtitle: const Text('Alterar informações pessoais'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.settings, color: scheme.primary)),
                  title: const Text('Configurações'),
                  subtitle: const Text('Preferências do app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    try {
                      context.push('/settings');
                    } catch (_) {
                      Navigator.pushNamed(context, '/settings');
                    }
                  },
                ),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.help_outline, color: scheme.primary)),
                  title: const Text('Ajuda e Suporte'),
                  subtitle: const Text('Central de ajuda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Ajuda e Suporte'),
                        content: const Text('Precisa de ajuda? Aqui você encontra perguntas frequentes, tutoriais e contato com suporte.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Fechar')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout, color: Colors.red)),
                  title: const Text('Sair', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Fazer logout da conta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final auth = Provider.of<AuthService>(context, listen: false);
                    try {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao sair. Tente novamente.'), backgroundColor: Colors.red));
                    }
                  },
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? 'Luma está pensando...' : 'Digite aqui...',
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isLoading ? Colors.grey : Colors.green.shade700,
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _handleSend,
            ),
          )
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty ? ', $_userName' : '';

    if (hour < 12) {
      return 'Bom dia$name!';
    } else if (hour < 18) {
      return 'Boa tarde$name!';
    } else {
      return 'Boa noite$name!';
    }
  }

  String _getPsychologistGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty ? ', Dr. $_userName' : ', Dr. Gustavo';

    if (hour < 12) {
      return 'Bom dia$name!';
    } else if (hour < 18) {
      return 'Boa tarde$name!';
    } else {
      return 'Boa noite$name!';
    }
  }
}
