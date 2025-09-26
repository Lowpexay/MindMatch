import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'dart:convert';
// restored: no extra imports
import '../utils/app_colors.dart';
import '../widgets/global_drawer.dart';
import '../widgets/checkup_heart_widget.dart';
import '../widgets/user_avatar.dart';
import '../providers/conversations_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/global_notification_service.dart';
import 'home_screen.dart';
import 'ai_chat_screen.dart';
import 'conversations_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  // Chave global para acessar a própria MainNavigation
  static final GlobalKey<_MainNavigationState> mainNavigationKey = GlobalKey<_MainNavigationState>();
  // Chave global para acessar o drawer
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  // Chave global para acessar métodos da ConversationsScreen
  static final GlobalKey<ConversationsScreenState> conversationsKey = GlobalKey<ConversationsScreenState>();
  // Chave global para acessar métodos da AiChatScreen
  static final GlobalKey<AiChatScreenState> aiChatKey = GlobalKey<AiChatScreenState>();

  // Método estático para navegar para a aba do chat IA
  static void navigateToAIChat() {
    final state = mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(2); // Índice 2 é a aba do AI Chat
    }
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _notificationServiceInitialized = false;
  String _userName = ''; // Nome do usuário
  Uint8List? _headerImageBytes;
  // kept minimal state
  PageController _pageController = PageController();
  late AnimationController _animationController;

  final List<Widget> _screens = [
    const HomeScreen(),
    ConversationsScreen(key: MainNavigation.conversationsKey),
    AiChatScreen(key: MainNavigation.aiChatKey, userMood: null), // IA sem contexto de humor específico
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGlobalNotifications();
      _loadUserName();
      _loadHeaderImage();
    });
  }

  Future<void> _loadHeaderImage() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final userProfile = await firebaseService.getUserProfile(userId);
        final base64 = userProfile?['profileImageBase64'] as String?;
        if (base64 != null && base64.isNotEmpty) {
          try {
            final bytes = base64Decode(base64);
            setState(() {
              _headerImageBytes = bytes;
            });
          } catch (_) {}
        }
      }
    } catch (e) {
      print('❌ Error loading header image: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId != null) {
        final userProfile = await firebaseService.getUserProfile(userId);
        setState(() {
          _userName = userProfile?['name'] ?? authService.currentUser?.displayName ?? '';
        });
        print('👤 Nome do usuário carregado no header: $_userName');
      }
    } catch (e) {
      print('❌ Error loading user name in header: $e');
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _userName = authService.currentUser?.displayName ?? '';
      });
    }
  }

  Future<void> _initializeGlobalNotifications() async {
    if (_notificationServiceInitialized) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final globalNotificationService = Provider.of<GlobalNotificationService>(context, listen: false);
      
      if (authService.isAuthenticated) {
        await globalNotificationService.initialize(authService);
        _notificationServiceInitialized = true;
        print('✅ Global notification service initialized');
      }
    } catch (e) {
      print('❌ Error initializing global notification service: $e');
    }
  }

  // Método para trocar de aba programaticamente
  void switchToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      
      setState(() {
        _currentIndex = index;
      });
      
      // Notificar AiChatScreen quando se tornar ativo
      if (index == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MainNavigation.aiChatKey.currentState?.checkAndInitializeWhenActive();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      key: MainNavigation.scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const GlobalDrawer(),
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              MainNavigation.aiChatKey.currentState?.checkAndInitializeWhenActive();
            });
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_rounded, label: 'Início', index: 0),
                _buildNavItem(icon: Icons.chat_rounded, label: 'Conversas', index: 1, hasNotification: true),
                _buildNavItem(icon: Icons.psychology, label: 'IA', index: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool hasNotification = false,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentIndex = index);
        if (index == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MainNavigation.aiChatKey.currentState?.checkAndInitializeWhenActive();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.gray500),
                  size: 24,
                ),
                if (hasNotification && index == 1)
                  Consumer<ConversationsProvider>(
                    builder: (context, conversationsProvider, child) {
                      final unreadCount = conversationsProvider.unreadCount;
                      if (unreadCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : AppColors.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    String? subtitle;
    
    switch (_currentIndex) {
      case 0:
        title = 'MindMatch';
        subtitle = _getGreeting();
        break;
      case 1:
        title = 'Conversas';
        break;
      case 2:
        title = 'Luma';
        subtitle = 'Sua assistente de bem-estar';
        break;
      default:
        title = 'MindMatch';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () => MainNavigation.scaffoldKey.currentState?.openDrawer(),
          icon: Icon(Icons.menu, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      actions: [
        // Coração de streak - apenas na tela principal
        if (_currentIndex == 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: const CheckupHeartWidget(),
          ),
        
        // Mostrar ações baseadas na aba atual
        if (_currentIndex == 1) // Conversas
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                // Chamar método da ConversationsScreen usando a chave global
                MainNavigation.conversationsKey.currentState?.showConversationOptions();
              },
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        
        if (_currentIndex == 2) // IA Chat
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                // Chamar método da AiChatScreen usando a chave global
                _showAiChatOptions();
              },
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
            ),
          ),
        
        // Avatar do usuário sempre visível
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _showUserMenu,
            child: UserAvatar(
              imageBytes: _headerImageBytes,
              radius: 20,
              useAuthPhoto: true,
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty ? ', $_userName' : '';
    
    if (hour < 12) {
      return 'Bom dia$name!';
    } else if (hour < 18) {
      return 'Boa tarde$name!';
    } else {
      return 'Boa noite$name!';
    }
  }

  void _showAiChatOptions() {
    // Chamar método do AiChatScreen usando a chave global
    MainNavigation.aiChatKey.currentState?.showChatOptions();
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header do perfil
            Row(
              children: [
                UserAvatar(
                  imageBytes: _headerImageBytes,
                  radius: 24,
                  useAuthPhoto: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meu Perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Gerencie sua conta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Opções do menu
            _buildMenuOption(
              icon: Icons.edit,
              title: 'Ver Perfil',
              subtitle: 'Alterar informações pessoais',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            
            _buildMenuOption(
              icon: Icons.settings,
              title: 'Configurações',
              subtitle: 'Preferências do app',
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Ajuda e Suporte',
              subtitle: 'Central de ajuda',
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
            
            const Divider(height: 24),
            
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Sair',
              subtitle: 'Fazer logout da conta',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await _handleLogout();
              },
            ),
            
            // Espaço para SafeArea
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : AppColors.gray400,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : null,
          title: Text(
            'Ajuda e Suporte',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
          ),
          content: Text(
          'MindMatch - Conectando pessoas com afinidades emocionais.\n\n'
          '📱 Versão: 1.0.0\n'
          '💙 Para suporte: mindmatch@exemplo.com\n\n'
          'Este app foi desenvolvido para promover conexões humanas '
          'significativas baseadas em bem-estar emocional.',
            style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white : AppColors.primary,
              ),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService?>(context, listen: false);
      await authService?.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao fazer logout. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
