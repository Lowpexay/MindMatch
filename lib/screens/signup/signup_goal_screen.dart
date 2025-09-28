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
  final List<String> _goals = const [
    'Desabafar e ser ouvido(a)',
    'Conversar sobre temas profundos',
    'Aprender com outras perspectivas',
    'Fazer novas amizades',
    'Encontrar apoio emocional',
    'Compartilhar experiências',
    'Outro (personalizar)'
  ];
  String _selected = '';
  final TextEditingController _customGoalController = TextEditingController();

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  void _next() {
    String finalGoal = _selected;
    if (_selected == 'Outro (personalizar)') {
      final trimmed = _customGoalController.text.trim();
      if (trimmed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite seu objetivo personalizado ou escolha outra opção.')));
        return;
      }
      finalGoal = trimmed;
    }
    // Objetivo pode ser opcional? Mantemos exigência de algum valor.
    if (finalGoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione ou escreva um objetivo.')));
      return;
    }
    final stateExtra = GoRouterState.of(context).extra;
    final previous = widget.data ?? (stateExtra is Map<String,dynamic> ? stateExtra : null);
    debugPrint('[SignupGoal] previous=$previous finalGoal=$finalGoal');
    context.push('/signupPhoto', extra: {
      ...?previous,
      'goal': finalGoal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: isDark? Colors.white: AppColors.textPrimary),
        title: const Text('Objetivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark? Colors.white: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qual seu objetivo no MindMatch:', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: isDark? Colors.white: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (_,i){
                    final goal = _goals[i];
                    final selected = goal == _selected;
                    final isCustom = goal == 'Outro (personalizar)';
                    return Column(
                      children: [
                        InkWell(
                          onTap: ()=> setState(()=> _selected = goal),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(.12) : (isDark? const Color(0xFF1E1E1E): Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(child: Text(goal, style: TextStyle(fontWeight: FontWeight.w600, color: isDark? Colors.white : AppColors.textPrimary))),
                              ],
                            ),
                          ),
                        ),
                        if (selected && isCustom)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextField(
                              controller: _customGoalController,
                              maxLength: 120,
                              decoration: InputDecoration(
                                hintText: 'Descreva seu objetivo...',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                counterText: '',
                              ),
                              onChanged: (_) => setState((){}),
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
