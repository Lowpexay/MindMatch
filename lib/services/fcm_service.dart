import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Serviço responsável por registrar e sincronizar o token FCM do usuário.
/// Colocado separado para poder ser chamado tanto no boot (main) quanto
/// assim que o usuário autentica (listener em AuthService).
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _subscribed = false;

  /// Salva o token atual do dispositivo no documento do usuário logado.
  Future<void> saveCurrentToken({bool log = true}) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (log) print('ℹ️ FcmService: Usuário não autenticado, adiando saveCurrentToken');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        if (log) print('⚠️ FcmService: getToken retornou null');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      if (log) print('✅ FcmService: Token salvo: $token');

      // Assinar tópicos padrão apenas uma vez por sessão
      if (!_subscribed) {
        await _subscribeDefaultTopics();
        _subscribed = true;
      }
    } catch (e) {
      print('❌ FcmService: erro ao salvar token: $e');
    }
  }

  /// Assina tópicos para campanhas (ex: notificações diárias)
  Future<void> _subscribeDefaultTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('daily_checkup');
      print('📌 FcmService: inscrito em daily_checkup');
    } catch (e) {
      print('⚠️ FcmService: falha ao inscrever em tópico daily_checkup: $e');
    }
  }

  /// Deve ser chamado no main depois de configurar FirebaseMessaging.onTokenRefresh.
  void attachTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('🔁 FcmService: token refresh recebido');
      await saveCurrentToken();
    });
  }

  /// Remove token do usuário ao deslogar (opcional, para evitar envios indevidos).
  Future<void> clearTokenOnSignOut(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': null,
        'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      print('🧹 FcmService: token removido no signOut');
    } catch (e) {
      print('⚠️ FcmService: erro ao limpar token: $e');
    }
  }
}
