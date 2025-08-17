import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Serviço global de notificações que escuta mudanças em tempo real
/// mesmo quando o usuário não está na tela de conversas
class GlobalNotificationService {
  static final GlobalNotificationService _instance = GlobalNotificationService._internal();
  factory GlobalNotificationService() => _instance;
  GlobalNotificationService._internal();

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  String? _currentUserId;
  String? _currentChatScreen; // Para evitar notificações quando estiver no chat ativo
  bool _isInitialized = false;

  Future<void> initialize(AuthService authService) async {
    if (_isInitialized) return;

    _currentUserId = authService.currentUser?.uid;
    if (_currentUserId == null) {
      print('⚠️ GlobalNotificationService: No user authenticated');
      return;
    }

    print('🌍 GlobalNotificationService: Initializing for user $_currentUserId');
    
    await _notificationService.initialize();
    await _setupGlobalListeners();
    
    _isInitialized = true;
    print('✅ GlobalNotificationService: Initialized successfully');
  }

  Future<void> _setupGlobalListeners() async {
    if (_currentUserId == null) return;

    // Escutar mudanças nas conversações em tempo real
    print('👂 Setting up global conversations listener');
    _conversationsSubscription = _firestore
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) async {
      await _processConversationChanges(snapshot);
    });

    // Escutar notificações diretas do usuário
    print('👂 Setting up global notifications listener');
    _notificationsSubscription = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) async {
      await _processNotificationChanges(snapshot);
    });
  }

  Future<void> _processConversationChanges(QuerySnapshot snapshot) async {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.modified) {
        final data = docChange.doc.data() as Map<String, dynamic>;
        final lastMessage = data['lastMessage'];
        
        if (lastMessage != null) {
          final senderId = lastMessage['senderId'];
          final content = lastMessage['content'];
          final conversationId = docChange.doc.id;
          
          // Só mostrar notificação se:
          // 1. A mensagem não foi enviada por mim
          // 2. Não estou na tela do chat atual
          // 3. A mensagem é nova (verificar timestamp)
          if (senderId != _currentUserId && 
              _currentChatScreen != conversationId &&
              content != null && content.isNotEmpty) {
            
            await _showConversationNotification(
              conversationId: conversationId,
              senderId: senderId,
              content: content,
              timestamp: lastMessage['timestamp'],
            );
          }
        }
      }
    }
  }

  Future<void> _processNotificationChanges(QuerySnapshot snapshot) async {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added) {
        final data = docChange.doc.data() as Map<String, dynamic>;
        
        if (data['type'] == 'message') {
          final conversationId = data['conversationId'];
          
          // Evitar notificação se estiver no chat ativo
          if (_currentChatScreen != conversationId) {
            await _notificationService.showChatNotification(
              senderName: data['senderName'] ?? 'Usuário',
              message: data['content'] ?? 'Nova mensagem',
              conversationId: conversationId,
            );
          }
        }
      }
    }
  }

  Future<void> _showConversationNotification({
    required String conversationId,
    required String senderId,
    required String content,
    required int timestamp,
  }) async {
    try {
      // Buscar nome do remetente
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();

      final senderName = senderDoc.exists 
          ? (senderDoc.data()?['name'] ?? 'Usuário')
          : 'Usuário';

      await _notificationService.showChatNotification(
        senderName: senderName,
        message: content,
        conversationId: conversationId,
      );

      print('🔔 Global notification shown: $senderName -> $content');
    } catch (e) {
      print('❌ Error showing global notification: $e');
    }
  }

  /// Definir a tela de chat ativa para evitar notificações duplicadas
  void setActiveChatScreen(String? conversationId) {
    _currentChatScreen = conversationId;
    print('📱 Active chat screen: ${_currentChatScreen ?? 'none'}');
  }

  /// Marcar notificação como lida
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Limpar todas as notificações não lidas
  Future<void> clearAllNotifications() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  void dispose() {
    _notificationsSubscription?.cancel();
    _conversationsSubscription?.cancel();
    _isInitialized = false;
    print('🗑️ GlobalNotificationService disposed');
  }
}
