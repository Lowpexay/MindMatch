import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../providers/conversations_provider.dart';
import '../utils/app_colors.dart';
import '../models/conversation_models.dart';
import 'user_chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isLoading = true;
  List<Conversation> _conversations = [];
  FirebaseService? _firebaseService;
  AuthService? _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context);
    _authService = Provider.of<AuthService>(context);
    
    // Usar o provider para conversas
    final conversationsProvider = Provider.of<ConversationsProvider>(context);
    _conversations = conversationsProvider.conversations;
    _isLoading = conversationsProvider.isLoading;
    
    // Atualizar provider com usuário atual
    final userId = _authService?.currentUser?.uid;
    if (userId != null) {
      conversationsProvider.updateUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          ),
        ),
        title: const Text(
          'Conversas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showConversationOptions,
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando conversas...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma conversa ainda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando você começar a conversar com outras pessoas, suas conversas aparecerão aqui.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Voltar para a tela inicial para encontrar pessoas
                // Como estamos usando IndexedStack, podemos usar um callback
                Navigator.pop(context);
              },
              icon: const Icon(Icons.people),
              label: const Text('Encontrar pessoas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Consumer<ConversationsProvider>(
      builder: (context, conversationsProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            // Recarregar através do provider
            final userId = _authService?.currentUser?.uid;
            if (userId != null) {
              conversationsProvider.updateUser(userId);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversationsProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversationsProvider.conversations[index];
              return _buildConversationCard(conversation);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final otherUser = conversation.otherUser;
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.unreadCount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.gray200,
              backgroundImage: otherUser.profileImageUrl != null 
                  ? NetworkImage(otherUser.profileImageUrl!) 
                  : null,
              child: otherUser.profileImageUrl == null
                  ? const Icon(Icons.person, size: 28, color: AppColors.gray500)
                  : null,
            ),
            if (otherUser.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (lastMessage != null) ...[
                  // Mostrar se foi você que enviou a última mensagem
                  if (lastMessage.senderId == _authService?.currentUser?.uid)
                    Text(
                      'Você: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      lastMessage.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Iniciar conversa',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatMessageTime(lastMessage?.timestamp ?? conversation.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Mostrar status da mensagem se você enviou a última
                if (lastMessage?.senderId == _authService?.currentUser?.uid) ...[
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: unreadCount == 0 ? AppColors.primary : AppColors.gray400,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.gray400,
        ),
        onTap: () => _openChat(otherUser),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      return weekdays[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<void> _openChat(ChatUser otherUser) async {
    // Marcar conversa como lida
    final userId = _authService?.currentUser?.uid;
    if (userId != null) {
      final conversationId = [userId, otherUser.id]..sort();
      final conversationIdString = conversationId.join('_');
      
      final conversationsProvider = Provider.of<ConversationsProvider>(context, listen: false);
      await conversationsProvider.markConversationAsRead(conversationIdString);
    }

    // Navegar para o chat
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatScreen(otherUser: otherUser),
      ),
    );
  }

  void _showConversationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opções de Conversa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: const Text('Buscar conversas'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read, color: AppColors.primary),
              title: const Text('Marcar todas como lidas'),
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArchivedConversations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showBlockedUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showChatSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Conversas'),
        content: const Text(
          'Como usar as conversas:\n\n'
          '• Encontre pessoas compatíveis na tela inicial\n'
          '• Clique em "Conversar" para iniciar um chat\n'
          '• Suas conversas ficam salvas aqui\n'
          '• Use o menu lateral para mais opções\n'
          '• Notificações mostram mensagens não lidas',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar conversas'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Digite o nome da pessoa...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // TODO: Implementar busca
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      await _firebaseService?.markAllConversationsAsRead(userId);
      
      // Usar o provider para atualizar
      final conversationsProvider = Provider.of<ConversationsProvider>(context, listen: false);
      conversationsProvider.updateUser(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as conversas marcadas como lidas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao marcar conversas como lidas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
