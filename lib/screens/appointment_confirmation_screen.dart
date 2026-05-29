import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra ?? ModalRoute.of(context)?.settings.arguments;
    final appointment = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
    final profile = appointment['profile'] is Map<String, dynamic>
        ? appointment['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final name = profile['name']?.toString() ?? 'Dr. Gustavo Teodoro Gabilan';
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
                  const Text(
                    'Deseja mais informações sobre o\nprofissional e a consulta? Fale\ndiretamente com o Dr. Gustavo',
                    style: TextStyle(fontSize: 32 / 2, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w600, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Em breve: chat direto com o profissional.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF56B35D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Falar com o profissional', style: TextStyle(fontWeight: FontWeight.w700)),
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
