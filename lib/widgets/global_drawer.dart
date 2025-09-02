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
import '../screens/quick_eventlog_test.dart';
import '../screens/eventlog_report_screen.dart';
import '../screens/emotional_reports_screen.dart';

class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

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
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayEmail,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
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
                  title: 'IA Assistente',
                  subtitle: 'Apoio emocional',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAI(context);
                  },
                ),
                
                const Divider(height: 32),
                
                _buildMenuItem(
                  context,
                  icon: Icons.person,
                  title: 'Meu Perfil',
                  subtitle: 'Editar informações',
                  onTap: () {
                    Navigator.pop(context);
                    _showProfile(context);
                  },
                ),
                
                _buildMenuItem(
                  context,
                  icon: Icons.mood,
                  title: 'Histórico de Humor',
                  subtitle: 'Ver evolução emocional',
                  onTap: () {
                    Navigator.pop(context);
                    _showMoodHistory(context);
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
                  icon: Icons.dashboard,
                  title: 'Relatórios EventLog',
                  subtitle: 'Painel ManageEngine',
                  onTap: () {
                    Navigator.pop(context);
                    _openEventLogReports(context);
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
                    _showSettings(context);
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
                
                _buildMenuItem(
                  context,
                  icon: Icons.network_check,
                  title: 'Teste EventLog',
                  subtitle: 'Testar conexão API',
                  onTap: () {
                    Navigator.pop(context);
                    _testEventLog(context);
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
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.gray400,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Implementar navegação para home se necessário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando para Início...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToConversations(BuildContext context) {
    // Implementar navegação para conversas se necessário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando para Conversas...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToAI(BuildContext context) {
    // Implementar navegação para IA se necessário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando para IA Assistente...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meu Perfil'),
        content: const Text(
          'Aqui você poderá editar suas informações pessoais, '
          'foto do perfil, bio e configurar suas preferências '
          'de compatibilidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Editar Perfil'),
          ),
        ],
      ),
    );
  }

  void _showMoodHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Histórico de Humor'),
        content: const Text(
          'Visualize a evolução do seu bem-estar emocional '
          'ao longo do tempo com gráficos e estatísticas '
          'detalhadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Histórico'),
          ),
        ],
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

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações'),
        content: const Text(
          'Ajuste suas preferências do aplicativo:\n\n'
          '• Notificações\n'
          '• Privacidade\n'
          '• Tema do app\n'
          '• Idioma\n'
          '• Backup de dados',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abrir Configurações'),
          ),
        ],
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

  void _openEventLogReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventLogReportScreen(),
      ),
    );
  }

  void _testEventLog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickEventLogTestScreen(),
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
