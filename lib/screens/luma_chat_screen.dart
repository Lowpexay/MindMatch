import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../widgets/global_drawer.dart';
import '../widgets/checkup_heart_widget.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';

class LumaChatScreen extends StatefulWidget {
  const LumaChatScreen({super.key});

  @override
  State<LumaChatScreen> createState() => _LumaChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? content;

  ChatMessage({required this.text, this.isUser = false, this.content});
}

class PsychologistProfile {
  final String name;
  final double rating;
  final String approach;
  final String mode;
  final String availability;
  final String location;
  final String summary;

  const PsychologistProfile({
    required this.name,
    required this.rating,
    required this.approach,
    required this.mode,
    required this.availability,
    required this.location,
    required this.summary,
  });

  Map<String, dynamic> toPromptMap() {
    return {
      'name': name,
      'approach': approach,
      'mode': mode,
      'availability': availability,
      'location': location,
      'summary': summary,
      'rating': rating,
    };
  }
}

class _LumaChatScreenState extends State<LumaChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [];

  String _userName = '';
  Uint8List? _headerImageBytes;
  bool _isLoading = false;
  bool _hasRecommended = false;
  final Map<String, String> _collectedInfo = {};

  final List<PsychologistProfile> _profiles = const [
    PsychologistProfile(
      name: 'Dr. Gustavo Teodoro Gabilan',
      rating: 4.9,
      approach: 'TCC para ansiedade e regulação emocional',
      mode: 'Online e Presencial',
      availability: 'Segunda a Sábado, 09:00 às 19:00',
      location: 'Morro da Mooca',
      summary: 'Especialista em ansiedade, autocobrança e estresse no trabalho.',
    ),
    PsychologistProfile(
      name: 'Dra. Camila Nogueira',
      rating: 4.8,
      approach: 'Terapia focada em relacionamentos e comunicação',
      mode: 'Online',
      availability: 'Segunda a Sexta, 10:00 às 20:00',
      location: 'Atendimento remoto',
      summary: 'Foco em relacionamentos, conflitos familiares e autoestima.',
    ),
    PsychologistProfile(
      name: 'Dr. Rafael Mendes',
      rating: 4.7,
      approach: 'Psicoterapia breve para rotina e organização emocional',
      mode: 'Presencial e Online',
      availability: 'Terça a Sexta, 08:00 às 18:00',
      location: 'Vila Mariana',
      summary: 'Atende questões de rotina, produtividade e sobrecarga mental.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserName();
      _loadHeaderImage();
      _addLumaMessage(
        'Olá! Eu sou a Luma. Vou conversar com você para entender seu momento e indicar o psicólogo ideal. '
        'Pode me contar com suas palavras: o que mais está te incomodando hoje?',
      );
    });
  }

  Future<void> _loadUserName() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final userProfile = await firebaseService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userName = userProfile?['name'] ?? authService.currentUser?.displayName ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name in LumaChat: $e');
    }
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
            if (mounted) {
              setState(() {
                _headerImageBytes = bytes;
              });
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error loading header image in LumaChat: $e');
    }
  }

  void _addLumaMessage(String text, {Widget? content}) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: false, content: content));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _buildConversationContext() {
    final ordered = _messages.reversed.toList();
    return ordered
        .map((msg) => '${msg.isUser ? 'Usuário' : 'Luma'}: ${msg.text}')
        .join('\n');
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _addUserMessage(text);
    _controller.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      final triageResult = await _geminiService.generatePsychologistTriageResponse(
        userMessage: text,
        conversationContext: _buildConversationContext(),
        collectedInfo: _collectedInfo,
        userName: _userName.isNotEmpty ? _userName : null,
        psychologistOptions: _profiles.map((p) => p.toPromptMap()).toList(),
      );

      final extracted = triageResult['extracted_info'];
      if (extracted is Map) {
        extracted.forEach((key, value) {
          final parsed = value?.toString().trim() ?? '';
          if (parsed.isNotEmpty) {
            _collectedInfo[key.toString()] = parsed;
          }
        });
      }

      final reply = (triageResult['assistant_reply']?.toString().trim().isNotEmpty ?? false)
          ? triageResult['assistant_reply'].toString().trim()
          : 'Entendi. Quero te ajudar com cuidado. Pode me contar um pouco mais sobre seu momento atual?';

      _addLumaMessage(reply);

      final ready = triageResult['ready_for_recommendation'] == true;
      if (ready && !_hasRecommended) {
        final recommended = _resolveRecommendedProfile(triageResult['recommended_psychologist']);
        setState(() {
          _hasRecommended = true;
        });
        _addLumaMessage(
          'Com base no que você compartilhou, encontrei um profissional que combina com o seu momento:',
          content: _buildProfessionalCard(recommended),
        );
      }
    } catch (e) {
      _addLumaMessage('Desculpe, tive uma instabilidade agora. Podemos continuar? Me conta mais sobre como você está se sentindo.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  PsychologistProfile _resolveRecommendedProfile(dynamic raw) {
    if (raw is Map) {
      final name = raw['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        for (final p in _profiles) {
          if (p.name.toLowerCase() == name.toLowerCase()) {
            return p;
          }
        }

        return PsychologistProfile(
          name: name,
          rating: double.tryParse(raw['rating']?.toString() ?? '') ?? 4.8,
          approach: raw['approach']?.toString() ?? 'Abordagem personalizada',
          mode: raw['mode']?.toString() ?? 'Online e Presencial',
          availability: raw['availability']?.toString() ?? 'A combinar',
          location: raw['location']?.toString() ?? 'A combinar',
          summary: raw['summary']?.toString() ?? 'Indicação baseada no seu contexto atual.',
        );
      }
    }

    return _profiles.first;
  }

  Widget _buildProfessionalCard(PsychologistProfile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showProfessionalModal(profile),
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(10.0),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        width: double.infinity,
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, color: Colors.green.shade700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.approach,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 6), Text(profile.rating.toStringAsFixed(1))]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.green.shade700)
          ],
        ),
      ),
    );
  }

  void _showProfessionalModal(PsychologistProfile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 42, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, size: 40, color: Colors.green.shade700)),
                const SizedBox(height: 12),
                Text(profile.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Text('Avaliação: ${profile.rating.toStringAsFixed(1)}/5', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.green.shade100), borderRadius: BorderRadius.circular(8), color: isDark ? const Color(0xFF1E1E1E) : Colors.green.shade50),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Abordagem: ${profile.approach}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Atendimento: ${profile.mode}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Localização: ${profile.location}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Disponibilidade: ${profile.availability}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final profileMap = profile.toPromptMap();
                      try {
                        context.go('/scheduleAppointment', extra: profileMap);
                      } catch (_) {
                        Navigator.pushNamed(context, '/scheduleAppointment', arguments: profileMap);
                      }
                    },
                    child: const Text('Marcar consulta'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleAiColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerSurface = isDark ? const Color(0xFF171717) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const GlobalDrawer(),
      appBar: AppBar(
        toolbarHeight: 88,
        elevation: 0,
        backgroundColor: headerSurface,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MindMatch', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          const Padding(padding: EdgeInsets.only(right: 12.0), child: CheckupHeartWidget()),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _showProfileOptions(),
              child: UserAvatar(
                imageBytes: _headerImageBytes,
                radius: 18,
                useAuthPhoto: true,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: _messages.isEmpty
                    ? Center(child: Text('Converse com a Luma', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)))
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!msg.isUser) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    backgroundImage: const AssetImage('assets/images/oiLuma.png'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (msg.content != null) msg.content!,
                                      if (msg.text.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: msg.isUser ? Colors.green.shade600 : bubbleAiColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            msg.text,
                                            style: TextStyle(color: msg.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (msg.isUser) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(radius: 16, backgroundColor: Colors.green.shade700, child: const Icon(Icons.person, color: Colors.white, size: 16)),
                                ]
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(color: scheme.onSurface.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    UserAvatar(imageBytes: _headerImageBytes, radius: 28, useAuthPhoto: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Meu Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                        const SizedBox(height: 4),
                        Text('Gerencie sua conta', style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.edit, color: scheme.primary)),
                  title: const Text('Ver Perfil'),
                  subtitle: const Text('Alterar informações pessoais'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.settings, color: scheme.primary)),
                  title: const Text('Configurações'),
                  subtitle: const Text('Preferências do app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    try {
                      context.push('/settings');
                    } catch (_) {
                      Navigator.pushNamed(context, '/settings');
                    }
                  },
                ),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.help_outline, color: scheme.primary)),
                  title: const Text('Ajuda e Suporte'),
                  subtitle: const Text('Central de ajuda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Ajuda e Suporte'),
                        content: const Text('Precisa de ajuda? Aqui você encontra perguntas frequentes, tutoriais e contato com suporte.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Fechar')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout, color: Colors.red)),
                  title: const Text('Sair', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Fazer logout da conta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final auth = Provider.of<AuthService>(context, listen: false);
                    try {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao sair. Tente novamente.'), backgroundColor: Colors.red));
                    }
                  },
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? 'Luma está pensando...' : 'Digite aqui...',
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isLoading ? Colors.grey : Colors.green.shade700,
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _handleSend,
            ),
          )
        ],
      ),
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
}
