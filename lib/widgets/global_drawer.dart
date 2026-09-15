import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/firebase_service.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';
import '../utils/app_colors.dart';
import '../screens/emotional_reports_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/luma_chat_screen.dart';

class GlobalDrawer extends StatelessWidget {
  final String userRole;

  const GlobalDrawer({super.key, this.userRole = 'PATIENT'});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Header do drawer — responsive height to avoid overflow on small screens
          Builder(builder: (context) {
            final headerHeight =
                min(200.0, MediaQuery.of(context).size.height * 0.25);
            return Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Builder(builder: (context) {
                    // Avatar size scales with header height to avoid vertical overflow
                    final avatarDiameter = min(80.0, headerHeight * 0.5);
                    final avatarRadius = avatarDiameter / 2;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: user != null
                          ? Provider.of<FirebaseService>(context, listen: false)
                              .getUserProfile(user.uid)
                          : Future.value(null),
                      builder: (context, snapshot) {
                        String? imageUrlFromDoc;
                        Uint8List? imageBytes;
                        String? nameFromDoc;
                        String? emailFromDoc;
                        if (snapshot.hasData && snapshot.data != null) {
                          final profile = snapshot.data!;
                          imageUrlFromDoc = (profile['profileImageUrl'] ??
                              profile['photoURL']) as String?;
                          nameFromDoc = (profile['displayName'] ??
                              profile['name']) as String?;
                          emailFromDoc = (profile['email']) as String?;
                          final base64 =
                              profile['profileImageBase64'] as String?;
                          if (base64 != null && base64.isNotEmpty) {
                            try {
                              imageBytes = base64Decode(base64);
                            } catch (_) {
                              imageBytes = null;
                            }
                          }
                        }

                        final effectiveUrl = imageUrlFromDoc ?? user?.photoURL;
                        final displayName =
                            nameFromDoc ?? user?.displayName ?? 'Usuário';
                        final displayEmail = emailFromDoc ?? user?.email ?? '';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: avatarDiameter,
                              height: avatarDiameter,
                              child: UserAvatar(
                                imageUrl: effectiveUrl,
                                imageBytes: imageBytes,
                                radius: avatarRadius,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name and email to the right
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayEmail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.onPrimary.withOpacity(0.85),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ),
            );
          }),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home,
                  title: 'Início',
                  subtitle: 'Tela principal',
                  onTap: () => _selectTab(context, 0),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.video_library,
                  title: 'Cursos',
                  subtitle: 'Conteúdo e evolução',
                  onTap: () => _selectTab(context, 1),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Conversas',
                  subtitle: 'Chats com usuários',
                  onTap: () => _selectTab(context, 2),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.psychology,
                  title: 'Luma (IA)',
                  subtitle: 'Assistente emocional',
                  onTap: () {
                    Navigator.pop(context);
                    _openAiChat(context);
                  },
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context,
                  icon: Icons.person,
                  title: 'Meu Perfil',
                  subtitle: 'Ver informações pessoais',
                  onTap: () => _selectTab(context, 3),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  subtitle: 'Análises personalizadas',
                  onTap: () {
                    Navigator.pop(context);
                    _showReports(context);
                  },
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: 'Configurações',
                  subtitle: 'Preferências do app',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings screen route
                    try {
                      context.push('/settings');
                    } catch (_) {
                      // Fallback if GoRouter not available in this context
                      Navigator.pushNamed(context, '/settings');
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Ajuda e Suporte',
                  subtitle: 'Central de ajuda',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelp(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Sobre o App',
                  subtitle: 'Versão e informações',
                  onTap: () {
                    Navigator.pop(context);
                    _showAbout(context);
                  },
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Sair',
                  subtitle: 'Fazer logout',
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (iconColor ?? scheme.primary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? scheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: scheme.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.outlineVariant,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _selectTab(BuildContext context, int index) {
    final state = MainNavigation.mainNavigationKey.currentState;
    if (state == null) {
      _fallbackSnack(context, 'Não foi possível trocar de seção.');
      return;
    }

    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) state.switchToTab(index);
    });
  }

  void _openAiChat(BuildContext context) {
    final state = MainNavigation.mainNavigationKey.currentState;
    if (state != null) {
      // Abrir AI Chat como rota sem tentar fechar a MainNavigation (evita comportamento de "fechar app")
      MainNavigation.openAIChat();
    } else {
      // Fallback se não estiver na estrutura principal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LumaChatScreen(mode: userRole),
        ),
      );
    }
  }

  void _fallbackSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmotionalReportsScreen(),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda e Suporte'),
        content: const Text(
          'Precisa de ajuda? Aqui você encontra:\n\n'
          '• Perguntas frequentes (FAQ)\n'
          '• Tutoriais do aplicativo\n'
          '• Contato com suporte\n'
          '• Reportar problemas\n'
          '• Feedback do usuário',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abrir Central de Ajuda'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o MindMatch'),
        content: const Text(
          'MindMatch\n\n'
          'Uma plataforma de saúde mental que aproxima pacientes e psicólogos '
          'de forma acolhedora e segura. O app oferece checkups emocionais, '
          'acompanhamento da rotina, conteúdos de bem-estar, conversas e o apoio '
          'da Luma, nossa assistente de inteligência artificial.\n\n'
          'Desenvolvido para promover cuidado, conexão e evolução emocional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do App'),
        content: const Text(
          'Tem certeza que deseja sair? '
          'Você precisará fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final authService =
                    Provider.of<AuthService>(context, listen: false);

                // Fazer logout
                await authService.signOut();
                print('✅ SignOut realizado com sucesso');

                // Usar GoRouter para limpar toda a pilha e ir para login
                if (context.mounted) {
                  print('✅ Navegando para /login');
                  context.go('/login');
                }
              } catch (e) {
                print('❌ Erro no logout: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao sair. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
