import 'package:flutter/foundation.dart';
import '../models/conversation_models.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

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
    _conversations = conversations;
    _isLoading = false;
    notifyListeners();
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
