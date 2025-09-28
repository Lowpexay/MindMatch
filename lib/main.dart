import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/global_notification_service.dart';
import 'services/checkup_streak_service.dart';
import 'services/achievement_service.dart';
import 'services/course_service.dart';
import 'services/course_progress_service.dart';
import 'services/daily_checkup_history_service.dart';
import 'services/theme_service.dart';
import 'providers/conversations_provider.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/settings_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure error handling for Pigeon errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool isPigeonError = details.exception.toString().contains('PigeonUserDetails') ||
                        details.exception.toString().contains('channel-error') ||
                        details.exception.toString().contains('List<Object?>');
    
    if (isPigeonError) {
      print('🔧 Pigeon error caught and handled: ${details.exception}');
      // Return a minimal widget instead of error screen for Pigeon errors
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // For other errors, show the default error widget
    return ErrorWidget(details.exception);
  };
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully with proper options');
    
    // Inicializar o serviço de notificações
    await NotificationService().initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }
  
  runApp(const MindMatchApp());
}

class MindMatchApp extends StatelessWidget {
  const MindMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()),
        Provider(create: (_) => GlobalNotificationService()),
        ChangeNotifierProvider(create: (_) => CheckupStreakService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => DailyCheckupHistoryService()),
        ChangeNotifierProxyProvider<AchievementService, CourseProgressService>(
          create: (context) => CourseProgressService(
            Provider.of<AchievementService>(context, listen: false),
          ),
          update: (context, achievementService, previous) =>
              previous ?? CourseProgressService(achievementService),
        ),
        ChangeNotifierProxyProvider<AchievementService, CourseService>(
          create: (context) => CourseService(
            Provider.of<AchievementService>(context, listen: false),
          ),
          update: (context, achievementService, previous) =>
              previous ?? CourseService(achievementService),
        ),
        ChangeNotifierProxyProvider2<AuthService, FirebaseService, ConversationsProvider>(
          create: (context) => ConversationsProvider(
            Provider.of<FirebaseService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, firebaseService, previous) =>
              previous ?? ConversationsProvider(firebaseService, authService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          // Light theme (original look) - minimal overrides
          final lightTheme = ThemeData(
            primarySwatch: Colors.blue,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          );
          // Dark theme: keep brand color, make background truly dark/black
          final baseDark = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          );
          final darkTheme = baseDark.copyWith(
            scaffoldBackgroundColor: AppColors.darkSurface,
            canvasColor: AppColors.darkSurface,
            colorScheme: baseDark.colorScheme.copyWith(
              background: AppColors.darkSurface,
              surface: AppColors.darkSurface,
              surfaceVariant: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
            dialogBackgroundColor: AppColors.darkSurface,
            cardColor: AppColors.darkSurface,
          );
          return MaterialApp.router(
            title: 'MindMatch',
            theme: themeService.isDark ? darkTheme : lightTheme,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) {
    // Handle routing errors gracefully
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text('Erro de navegação'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => MainNavigation(key: MainNavigation.mainNavigationKey),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profileEdit',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => const CoursesScreen(),
    ),
    // Settings route to be implemented
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (isFirstTime) {
      context.go('/onboarding');
    } else {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/luma_com_fundo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain, // Mudando para contain para preservar transparência
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback para o ícone antigo se a imagem não carregar
                    return const Icon(
                      Icons.favorite,
                      size: 60,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MindMatch',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Conecte-se com pessoas que pensam como você',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
