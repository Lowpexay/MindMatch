import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/conversation_models.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../screens/user_chat_screen.dart';

class AppointmentConfirmationScreen extends StatefulWidget {
  const AppointmentConfirmationScreen({super.key});

  @override
  State<AppointmentConfirmationScreen> createState() => _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState extends State<AppointmentConfirmationScreen> {
  bool _isSaving = false;

  Map<String, dynamic> get _appointment {
    final extra = GoRouterState.of(context).extra ?? ModalRoute.of(context)?.settings.arguments;
    return extra is Map<String, dynamic> ? extra : <String, dynamic>{};
  }

  Future<void> _confirmAppointment() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final patientId = currentUser?.uid;
      if (patientId == null) {
        throw Exception('Usuário não autenticado');
      }

      final appointment = _appointment;
      final profile = appointment['profile'] is Map<String, dynamic>
          ? appointment['profile'] as Map<String, dynamic>
          : <String, dynamic>{};

      final psychologistName = profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : 'Profissional';
        final psychologistIdFromAppointment = appointment['psychologistId']?.toString().trim();
        final psychologistNameFromAppointment = appointment['psychologistName']?.toString().trim();
      final dateIso = appointment['date']?.toString();
      final time = appointment['time']?.toString() ?? '11:00';
      final consultationType = appointment['consultation_type']?.toString() ?? 'Online';
        final psychologistModality = (appointment['psychologistModality'] ?? profile['modality'] ?? '').toString();
      final parsedDate = DateTime.tryParse(dateIso ?? '');
      final selectedDate = parsedDate ?? DateTime.now().add(const Duration(days: 1));
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final formattedDate = '${startOfDay.day.toString().padLeft(2, '0')}/${startOfDay.month.toString().padLeft(2, '0')}/${startOfDay.year}';

      final patientProfile = await firebaseService.getUserProfile(patientId);
      final patientName = (patientProfile?['name'] ?? currentUser?.displayName ?? 'Paciente').toString();
      final resolvedPsychologist = psychologistIdFromAppointment != null && psychologistIdFromAppointment.isNotEmpty
          ? {'id': psychologistIdFromAppointment}
          : profile['id']?.toString().isNotEmpty == true
              ? {'id': profile['id'].toString()}
              : psychologistNameFromAppointment != null && psychologistNameFromAppointment.isNotEmpty
                  ? await firebaseService.findPsychologistByName(psychologistNameFromAppointment)
                  : await firebaseService.findPsychologistByName(psychologistName);
      final psychologistId = resolvedPsychologist?['id']?.toString();
      if (psychologistId == null || psychologistId.isEmpty) {
        throw Exception('Não foi possível localizar o psicólogo selecionado');
      }

      if (!_isSupportedAttendanceType(psychologistModality, consultationType)) {
        throw Exception('O psicólogo selecionado não atende no formato $consultationType. Escolha uma modalidade compatível com o cadastro dele.');
      }

      final modality = consultationType.toUpperCase() == 'PRESENCIAL' ? 'IN_PERSON' : 'CALL';
      final consultationData = <String, dynamic>{
        'idPsychologist': psychologistId,
        'idPatient': patientId,
        'psychologistName': psychologistNameFromAppointment ?? psychologistName,
        'psychologistSpecialty': appointment['psychologistSpecialty']?.toString() ?? profile['specialty']?.toString(),
        'psychologistModality': appointment['psychologistModality']?.toString() ?? profile['modality']?.toString(),
        'psychologistAvailability': appointment['psychologistAvailability']?.toString() ?? profile['availability']?.toString(),
        'patientName': patientName,
        'date': startOfDay.millisecondsSinceEpoch,
        'hour': time,
        'modality': modality,
        'status': 'SCHEDULED',
      };

      final consultationRef = await firebaseService.createConsultation(consultationData);
      final conversationId = await firebaseService.getOrCreateConversation(patientId, psychologistId);
      if (conversationId != null) {
        final chatMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: patientId,
          receiverId: psychologistId,
          content: 'Nova consulta agendada com ${psychologistNameFromAppointment ?? psychologistName} para $formattedDate às $time ($consultationType).',
          type: MessageType.system,
          timestamp: DateTime.now(),
        );
        await firebaseService.sendChatMessage(chatMessage);
      }

      if (!mounted) return;
      final chatUser = ChatUser(
        id: psychologistId,
        name: psychologistName,
        profileImageUrl: profile['profileImageUrl']?.toString(),
        profileImageBase64: profile['profileImageBase64']?.toString(),
        isOnline: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta salva e mensagem enviada ao psicólogo.')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserChatScreen(otherUser: chatUser),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir o agendamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _isSupportedAttendanceType(String psychologistModality, String consultationType) {
    final modality = psychologistModality.toLowerCase();
    final selected = consultationType.toLowerCase();

    if (modality.contains('online e presencial') || modality.contains('both')) {
      return selected == 'online' || selected == 'presencial';
    }
    if (modality.contains('online')) {
      return selected == 'online';
    }
    if (modality.contains('presencial')) {
      return selected == 'presencial';
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    final profile = appointment['profile'] is Map<String, dynamic>
        ? appointment['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final name = profile['name']?.toString() ?? 'Profissional';
    final dateIso = appointment['date']?.toString();
    final time = appointment['time']?.toString() ?? '11:00';
    final consultationType = appointment['consultation_type']?.toString() ?? 'Online';

    final parsedDate = DateTime.tryParse(dateIso ?? '');
    final dateText = parsedDate == null
        ? '21/04/2026'
        : '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 360,
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDFDFDF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF56B35D), width: 7),
                          ),
                        ),
                        const Icon(Icons.check, color: Color(0xFF56B35D), size: 76),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Center(
                    child: Text(
                      'Consulta agendada com\nsucesso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF56B35D),
                        fontSize: 39 / 2,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sua consulta esta agendada com:',
                    style: TextStyle(fontSize: 31 / 2, color: Color(0xFF262626), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF262626), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dia: $dateText as $time',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF262626), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tipo da consulta: $consultationType',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF262626), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Na semana da sua consulta, você\nreceberá uma notificação para\nconfirmar o agendamento, fique de\nolho nas notificações!',
                    style: TextStyle(fontSize: 32 / 2, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w600, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No dia da sua consulta, o psicólogo irá\nte mandar um convite para entrar na\nchamada, olhe sempre as conversas\npara não perder!',
                    style: TextStyle(fontSize: 32 / 2, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w600, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Deseja mais informações sobre o\nprofissional e a consulta? Fale\ndiretamente com $name',
                    style: const TextStyle(fontSize: 32 / 2, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w600, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _confirmAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF56B35D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Falar com o profissional', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        try {
                          context.go('/home');
                        } catch (_) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2B2B2B),
                        side: const BorderSide(color: Color(0xFF56B35D), width: 1.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Voltar para o inicio', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
