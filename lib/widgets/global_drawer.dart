import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: user?.photoURL != null 
                          ? NetworkImage(user!.photoURL!) 
                          : null,
                      child: user?.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'Usuário',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatórios Personalizados'),
        content: const Text(
          'Acesse análises detalhadas sobre seu bem-estar, '
          'compatibilidade com outros usuários e insights '
          'gerados pela IA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Relatórios'),
          ),
        ],
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
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
