import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'services/fcm_service.dart';
import 'providers/conversations_provider.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/settings_screen.dart';
import 'utils/app_colors.dart';
// Multi-step signup flow screens
import 'screens/signup/signup_basic_screen.dart';
import 'screens/signup/signup_bio_screen.dart';
import 'screens/signup/signup_interests_screen.dart';
import 'screens/signup/signup_goal_screen.dart';
import 'screens/signup/signup_photo_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔙 (BG) Mensagem recebida: ${message.messageId}');
  try {
    // Se for mensagem apenas de dados, criar notificação local manualmente
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'MindMatch';
      final body = message.data['body'] ?? 'Nova mensagem';
      final conversationId = message.data['conversationId'] ?? 'generic';
      await NotificationService().initialize(); // garante inicialização no isolate
      await NotificationService().showChatNotification(
        senderName: title,
        message: body,
        conversationId: conversationId,
      );
    }
  } catch (e) {
    print('❌ Erro ao mostrar notificação em background: $e');
  }
}

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
    
    // Inicializar o serviço de notificações locais
    await NotificationService().initialize();
    print('✅ Notification service initialized');

    // Configurar Firebase Messaging (push remoto)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initPushMessaging();
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }
  
  runApp(const MindMatchApp());
}

Future<void> _initPushMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Solicitar permissões (iOS / Android 13+ handled by local notifications)
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('🔐 Push permission status: ${settings.authorizationStatus}');

    // Obter token FCM
    final token = await messaging.getToken();
    print('🔑 FCM Token: $token');
  // Salva usando serviço central (tenta se usuário já estiver logado)
  await FcmService.instance.saveCurrentToken();

    // Atualizar token em mudanças
    FcmService.instance.attachTokenRefreshListener();

    // (Opcional) Inscrever em tópico padrão para campanhas diárias
    try {
      await messaging.subscribeToTopic('daily_checkup');
      print('📌 Subscribed to topic: daily_checkup');
    } catch (e) {
      print('⚠️ Falha ao inscrever em tópico daily_checkup: $e');
    }

    // Listener de mensagens foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 (FG) Push recebido: ${message.messageId}');
      final notification = message.notification;
      if (notification != null) {
        NotificationService().showChatNotification(
          senderName: notification.title ?? 'MindMatch',
          message: notification.body ?? 'Nova mensagem',
          conversationId: message.data['conversationId'] ?? 'generic',
        );
      } else if (message.data.isNotEmpty) {
        // Data-only em foreground
        NotificationService().showChatNotification(
          senderName: message.data['title'] ?? 'MindMatch',
          message: message.data['body'] ?? 'Nova mensagem',
          conversationId: message.data['conversationId'] ?? 'generic',
        );
      }
    });

    // Clique em notificação que abriu o app (terminado ou background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🟢 Notificação aberta pelo usuário: ${message.messageId}');
      final convoId = message.data['conversationId'];
      if (convoId != null) {
        // Poderíamos armazenar em algum singleton para abrir conversa após home
        print('➡️ Abrir conversa: $convoId (implementar deep link)');
      }
    });
  } catch (e) {
    print('❌ Erro ao inicializar push messaging: $e');
  }
}

// _storeFcmToken removido – lógica movida para FcmService

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
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('pt', 'BR'),
            ],
            locale: const Locale('pt', 'BR'),
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
    // --- Multi-step signup flow ---
    GoRoute(
      path: '/signupBasic',
      builder: (context, state) => const SignupBasicScreen(),
    ),
    GoRoute(
      path: '/signupBio',
      builder: (context, state) => SignupBioScreen(
        data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null,
      ),
    ),
    GoRoute(
      path: '/signupInterests',
      builder: (context, state) => SignupInterestsScreen(
        data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null,
      ),
    ),
    GoRoute(
      path: '/signupGoal',
      builder: (context, state) => SignupGoalScreen(
        data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null,
      ),
    ),
    GoRoute(
      path: '/signupPhoto',
      builder: (context, state) => SignupPhotoScreen(
        data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null,
      ),
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
        // Inicializar notificações globais cedo
        try {
          final globalNotification = Provider.of<GlobalNotificationService>(context, listen: false);
          await globalNotification.initialize(authService);
        } catch (e) {
          print('⚠️ Falha ao inicializar notificações globais no Splash: $e');
        }
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
