import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    print('🔔 Initializing notification service...');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    print('✅ Notification service initialized');
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('🔔 Notification tapped: $payload');
    if (payload != null && appNavigatorKey.currentState != null) {
      // Navegar usando GoRouter se disponível ou direto para rota básica
      try {
        // Usando pushNamed se estivesse configurado; aqui, fallback simples
        // Se já estivermos no app, podemos direcionar para /home e depois abrir a conversa
        // Simplesmente empurrar home primeiro para garantir stack
        appNavigatorKey.currentState!.pushNamed('/home');
        // Poderíamos armazenar payload globalmente para a tela de conversas abrir direto
      } catch (e) {
        debugPrint('⚠️ Falha ao navegar a partir de notificação: $e');
      }
    }
  }

  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    if (!_initialized) {
      print('⚠️ Notification service not initialized');
      return;
    }

    print('🔔 Showing chat notification from $senderName');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Mensagens de Chat',
      channelDescription: 'Notificações de novas mensagens de chat',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(
      conversationId.hashCode, // Use conversation ID as notification ID
      'Nova mensagem de $senderName',
      message.length > 100 ? '${message.substring(0, 100)}...' : message,
      notificationDetails,
      payload: conversationId,
    );
  }

  Future<void> cancelNotification(String conversationId) async {
    await _notifications.cancel(conversationId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
