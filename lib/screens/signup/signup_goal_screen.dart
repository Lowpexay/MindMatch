import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

class SignupGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SignupGoalScreen({super.key, this.data});

  @override
  State<SignupGoalScreen> createState() => _SignupGoalScreenState();
}

class _SignupGoalScreenState extends State<SignupGoalScreen> {
  final List<Map<String, String>> _goals = const [
    {'id': 'U', 'label': '🙋 Sou um paciente procurando por uma consulta'},
    {'id': 'P', 'label': '👨‍⚕️ Sou um(a) psicologo(a) procurando por pacientes'},
  ];
  String _selectedGoalId = '';
  final TextEditingController _customGoalController = TextEditingController();

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  void _next() {
    final String finalGoalId = _selectedGoalId;
    if (finalGoalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma opção!')));
      return;
    }
    final stateExtra = GoRouterState.of(context).extra;
    final previous = widget.data ?? (stateExtra is Map<String,dynamic> ? stateExtra : null);
    debugPrint('[SignupGoal] previous=$previous finalGoalId=$finalGoalId');
    if(_selectedGoalId == "U"){
      context.push('/cadastroPaciente', extra: {
      ...?previous,
      'goal': finalGoalId,
    });
    }else{
      context.push('/signupInterests', extra: {
      ...?previous,
      'goal': finalGoalId,
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Objetivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('O que procura dentro do MindMatch', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color:AppColors.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (_, i) {
                    final goal = _goals[i];
                    final selected = goal['id'] == _selectedGoalId;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedGoalId = goal['id']!),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(.12) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(child: Text(goal['label']!, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (_,__)=> const SizedBox(height: 10),
                  itemCount: _goals.length,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
