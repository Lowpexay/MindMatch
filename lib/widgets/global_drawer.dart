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
import '../screens/eventlog_report_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/main_navigation.dart';

class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

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
            final headerHeight = min(200.0, MediaQuery.of(context).size.height * 0.25);
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
                        ? Provider.of<FirebaseService>(context, listen: false).getUserProfile(user.uid)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      String? imageUrlFromDoc;
                      Uint8List? imageBytes;
                      String? nameFromDoc;
                      String? emailFromDoc;
                      if (snapshot.hasData && snapshot.data != null) {
                        final profile = snapshot.data!;
                        imageUrlFromDoc = (profile['profileImageUrl'] ?? profile['photoURL']) as String?;
                        nameFromDoc = (profile['displayName'] ?? profile['name']) as String?;
                        emailFromDoc = (profile['email']) as String?;
                        final base64 = profile['profileImageBase64'] as String?;
                        if (base64 != null && base64.isNotEmpty) {
                          try {
                            imageBytes = base64Decode(base64);
                          } catch (_) {
                            imageBytes = null;
                          }
                        }
                      }

                      final effectiveUrl = imageUrlFromDoc ?? user?.photoURL;
                      final displayName = nameFromDoc ?? user?.displayName ?? 'Usuário';
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
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToHome(context);
                  },
                ),
                
                _buildMenuItem(
                  context,
                  icon: Icons.chat,
                  title: 'Conversas',
                  subtitle: 'Chat com pessoas',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToConversations(context);
                  },
                ),
                
                _buildMenuItem(
                  context,
                  icon: Icons.psychology,
                  title: 'Chat Luma',
                  subtitle: 'IA para apoio emocional',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToLuma(context);
                  },
                ),
                
                const Divider(height: 32),
                
                _buildMenuItem(
                  context,
                  icon: Icons.person,
                  title: 'Meu Perfil',
                  subtitle: 'Ver informações pessoais',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToProfile(context);
                  },
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
                
                _buildMenuItem(
                  context,
                  icon: Icons.security,
                  title: 'Relatório EventLog',
                  subtitle: 'Logins e segurança',
                  onTap: () {
                    Navigator.pop(context);
                    _showEventLogReports(context);
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

  void _navigateToHome(BuildContext context) {
    // Navega para a aba Home (índice 0)
    final state = MainNavigation.mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navegando para Início...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _navigateToConversations(BuildContext context) {
    // Navega para a aba de Conversas (índice 1)
    final state = MainNavigation.mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navegando para Conversas...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _navigateToLuma(BuildContext context) {
    // Navega para a aba da Luma (índice 2) 
    final state = MainNavigation.mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navegando para Chat Luma...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    // Navega para a tela de perfil
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
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

  void _showEventLogReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventLogReportScreen(),
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
          'MindMatch v1.0.0\n\n'
          'Um aplicativo inovador que conecta pessoas '
          'com base em afinidades emocionais e valores, '
          'promovendo relacionamentos mais significativos.\n\n'
          '© 2025 MindMatch Team\n'
          'Desenvolvido com 💙 para conectar mentes',
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
                final authService = Provider.of<AuthService>(context, listen: false);
                
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
