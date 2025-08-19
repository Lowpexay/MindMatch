import 'package:flutter/foundation.dart';
import '../models/conversation_models.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class ConversationsProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  final AuthService _authService;
  
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  ConversationsProvider(this._firebaseService, this._authService) {
    _initializeListener();
  }
  
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get unreadCount => _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  
  void _initializeListener() {
    _currentUserId = _authService.currentUser?.uid;
    if (_currentUserId != null) {
      print('🔄 Initializing conversations listener for user: $_currentUserId');
      _firebaseService.listenToUserConversations(_currentUserId!, _onConversationsUpdate);
    }
  }
  
  void _onConversationsUpdate(List<Conversation> conversations) {
    print('📱 ConversationsProvider: Received ${conversations.length} conversations');
    
    // Detectar novas mensagens para notificações
    for (final newConv in conversations) {
      final oldConv = _conversations.where((c) => c.id == newConv.id).firstOrNull;
      
      // Verificar se há uma nova mensagem
      bool hasNewMessage = false;
      
      if (oldConv == null) {
        // Nova conversa - só notificar se a última mensagem não foi enviada por mim
        // E se tem unread count > 0 (significa que há mensagens não lidas)
        hasNewMessage = newConv.lastMessage != null && 
                       newConv.lastMessage!.senderId != _currentUserId &&
                       newConv.unreadCount > 0;
      } else {
        // Conversa existente - verificar se a última mensagem mudou
        final oldLastMessage = oldConv.lastMessage;
        final newLastMessage = newConv.lastMessage;
        
        if (newLastMessage != null) {
          // Mensagem é nova se:
          // 1. Não havia mensagem antes, OU
          // 2. O ID da mensagem é diferente, OU
          // 3. O timestamp é mais recente
          bool isDifferentMessage = oldLastMessage == null ||
                                   newLastMessage.id != oldLastMessage.id ||
                                   newLastMessage.timestamp.isAfter(oldLastMessage.timestamp);
          
          // Só notificar se:
          // - É uma mensagem diferente
          // - Não foi enviada por mim
          // - O unread count aumentou
          hasNewMessage = isDifferentMessage &&
                         newLastMessage.senderId != _currentUserId &&
                         newConv.unreadCount > (oldConv.unreadCount);
        }
      }
      
      // Mostrar notificação se há nova mensagem
      if (hasNewMessage && newConv.lastMessage != null) {
        print('🔔 Showing notification for new message from ${newConv.otherUser.name}');
        print('📋 Message: ${newConv.lastMessage!.content}');
        print('📊 Unread count: ${newConv.unreadCount}');
        
        NotificationService().showChatNotification(
          senderName: newConv.otherUser.name,
          message: newConv.lastMessage!.content,
          conversationId: newConv.id,
        );
      }
    }
    
    _conversations = conversations;
    _isLoading = false;
    notifyListeners();
    
    // Debug: Imprimir contagem de não lidas
    final totalUnread = conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
    print('📊 Total unread count: $totalUnread');
  }
  
  // Marcar conversa como lida
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      if (_currentUserId != null) {
        await _firebaseService.markMessagesAsRead(conversationId, _currentUserId!);
        
        // Atualizar localmente também
        final index = _conversations.indexWhere((conv) => conv.id == conversationId);
        if (index != -1) {
          final updatedConversation = Conversation(
            id: _conversations[index].id,
            userId1: _conversations[index].userId1,
            userId2: _conversations[index].userId2,
            otherUser: _conversations[index].otherUser,
            lastMessage: _conversations[index].lastMessage,
            createdAt: _conversations[index].createdAt,
            updatedAt: _conversations[index].updatedAt,
            unreadCount: 0, // Zerar contador
            isArchived: _conversations[index].isArchived,
            isBlocked: _conversations[index].isBlocked,
          );
          
          _conversations[index] = updatedConversation;
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
    }
  }
  
  // Atualizar quando usuário muda
  void updateUser(String? userId) {
    if (userId != _currentUserId) {
      _currentUserId = userId;
      _conversations.clear();
      if (userId != null) {
        _isLoading = true;
        notifyListeners();
        _firebaseService.listenToUserConversations(userId, _onConversationsUpdate);
      }
    }
  }
}
