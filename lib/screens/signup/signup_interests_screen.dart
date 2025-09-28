import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../widgets/tag_selector.dart';

class SignupInterestsScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SignupInterestsScreen({super.key, this.data});

  @override
  State<SignupInterestsScreen> createState() => _SignupInterestsScreenState();
}

class _SignupInterestsScreenState extends State<SignupInterestsScreen> {
  List<String> _selected = [];
  final List<String> _available = const [
    '#filosofia', '#saúde mental', '#tecnologia', '#cinema', '#música', '#arte', '#literatura', '#viagem', '#culinária', '#esportes', '#meditação', '#yoga', '#psicologia', '#ciência', '#natureza', '#fotografia'
  ];

  void _next() {
    // Tags agora podem ser opcionais; mostramos aviso suave, mas deixamos prosseguir.
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você pode escolher interesses depois (continuando assim).')),
      );
    }
    final stateExtra = GoRouterState.of(context).extra;
    final previous = widget.data ?? (stateExtra is Map<String,dynamic> ? stateExtra : null);
    debugPrint('[SignupInterests] previous=$previous selected=$_selected');
    context.push('/signupGoal', extra: {
      ...?previous,
      'tags': _selected,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: isDark? Colors.white: AppColors.textPrimary),
        title: const Text('Interesses'),
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
              Text('Selecione alguns dos seus interesses (opcional):', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: isDark? Colors.white: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: TagSelector(
                    availableTags: _available,
                    selectedTags: _selected,
                    onTagsChanged: (t){ setState(()=>_selected=t); },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _next,
                    child: const Text('Pular'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
