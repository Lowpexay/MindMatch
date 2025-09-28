import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/safe_navigation.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/configuration_error_dialog.dart';

/// Tela de login simplificada. Cadastro multi-step em /signupBasic.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 24),
              Text('Bem-vindo de volta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )),
              const SizedBox(height: 8),
              Text('Entre para continuar sua jornada no MindMatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  )),
              const SizedBox(height: 40),
              _buildGoogleButton(isDark),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Não tem uma conta? ',
                      style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  TextButton(
                    onPressed: () { if (mounted) context.push('/signupBasic'); },
                    child: const Text('Cadastre-se', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Row(children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 32),
              _buildLoginForm(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/images/luma_com_fundo.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 40),
              ),
            ),
          ),
        ),
      );

  Widget _buildGoogleButton(bool isDark) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata, size: 28),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('Entrar com Google', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.primary : Colors.white,
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            side: isDark ? BorderSide.none : const BorderSide(color: AppColors.gray300, width: 1),
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: isDark ? 2 : 0,
          ),
        ),
      );

  Widget _buildLoginForm(bool isDark) => Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Por favor, insira seu e-mail';
                final trimmed = value.trim();
                // Regex corrigido: o anterior usava \\ dentro de raw string, quebrando o \w.
                // Este permite letras, números, ponto, hífen e underscore nas partes antes/depois do @
                final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[A-Za-z]{2,}$');
                if (!emailRegex.hasMatch(trimmed)) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: 'Senha',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Por favor, insira sua senha';
                if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Entrar'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Esqueceu sua senha?', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        await SafeNavigation.safeNavigate(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('configuração do Google Sign-In')) {
        ConfigurationErrorDialog.show(
          context,
          title: 'Configuração do Google Sign-In',
          message: 'Configure o Google Sign-In no Firebase Console.',
          steps: const [
            'Acesse console.firebase.google.com',
            'Projeto mindmatch-ba671',
            'Project Settings > Your apps',
            'Adicione SHA-1 e SHA-256',
            'Baixe google-services.json',
            'Reinicie o app'
          ],
          onRetry: _signInWithGoogle,
        );
      } else {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.currentUser == null) {
          _showSnack('Erro ao entrar com Google: $e', error: true);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await authService.signInWithEmail(_emailController.text.trim(), _passwordController.text);
      } catch (e) {
        // Tratamento similar ao fluxo de signup para erros de canal/Pigeon que acontecem mas o login funciona
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('channel-error') ||
            e.toString().contains('List<Object?>')) {
          // Pequeno delay e continuamos se o usuário estiver autenticado
          await Future.delayed(const Duration(milliseconds: 400));
        } else {
          rethrow;
        }
      }
      if (mounted) {
        final authService2 = Provider.of<AuthService>(context, listen: false);
        if (authService2.currentUser != null) {
          await SafeNavigation.safeNavigate(context, '/home');
        } else {
          _showSnack('Falha ao autenticar. Tente novamente.', error: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao entrar: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnack('Insira o e-mail primeiro', error: true);
      return;
    }
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      _showSnack('E-mail de recuperação enviado!');
    } catch (e) {
      _showSnack('Erro ao enviar recuperação: $e', error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }
}
 
