import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

/// Etapa de bio (opcional). Agora recebe explicitamente o mapa acumulado via construtor
/// para reduzir risco de perda de dados quando GoRouterState.extra não propaga.
/// Mantemos fallback em GoRouterState.of(context).extra por segurança.
class SignupBioScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SignupBioScreen({super.key, this.data});

  @override
  State<SignupBioScreen> createState() => _SignupBioScreenState();
}

class _SignupBioScreenState extends State<SignupBioScreen> {
  final _controller = TextEditingController();

  Map<String, dynamic>? get _incomingData {
    // Prioriza widget.data; fallback para state.extra se disponível.
    final stateExtra = GoRouterState.of(context).extra;
    return widget.data ?? (stateExtra is Map<String, dynamic> ? stateExtra : null);
  }

  @override
  void initState() {
    super.initState();
    // Logging inicial para diagnóstico de perda de dados.
    // (Não impacta produção significativamente; pode ser removido depois.)
    debugPrint('[SignupBio] init data = ' + (widget.data?.toString() ?? 'null'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    // Bio é opcional: se vazio, simplesmente passa string vazia
    final previous = _incomingData;
    debugPrint('[SignupBio] forwarding with previous=$previous bio=${_controller.text.trim()}');
    context.push('/signupInterests', extra: {
      ...?previous,
      'bio': _controller.text.trim(),
    });
  }
  
  void _skip() {
    final previous = _incomingData;
    debugPrint('[SignupBio] skip pressed; previous=$previous');
    context.push('/signupInterests', extra: {
      ...?previous,
      'bio': '', // Skip bio input
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: isDark? Colors.white: AppColors.textPrimary),
        title: const Text('Sua bio'),
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
              Text(
                'Fale um pouco sobre você (opcional):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 260),
                child: Scrollbar(
                  thumbVisibility: false,
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ex: Sou uma pessoa curiosa, gosto de aprender coisas novas... (deixe em branco se preferir)',
                      helperText: 'Você pode preencher depois',
                      helperStyle: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                      counterText: _controller.text.isEmpty ? '' : '${_controller.text.length}/400',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (v) {
                      if (v.length > 400) {
                        _controller.text = v.substring(0, 400);
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      }
                      setState(() {}); // Atualiza counter
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _skip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                    side: BorderSide(color: isDark ? Colors.white24 : AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Pular'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
