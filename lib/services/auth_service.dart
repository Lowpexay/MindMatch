import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../security/eventlog_service.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Temporariamente desabilitado

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  // Email and Password Sign Up
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing up: ${e.message}');
      throw e;
    }
  }

  // Email and Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    String? userId;
    String userName = email.split('@')[0]; // Nome baseado no email
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      userId = userCredential.user?.uid;
      
      // Log successful login attempt
      if (userId != null) {
        await EventLogService.logLoginAttempt(
          userId: userId,
          userName: userName,
          deviceInfo: kIsWeb ? 'web_browser' : 'mobile_device',
          isSuccessful: true,
          ipAddress: 'dynamic',
        );
        
        // Configure security alerts for first-time users
        await EventLogService.configureSecurityAlerts(userId);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing in: ${e.message}');
      
      // Log failed login attempt
      await EventLogService.logLoginAttempt(
        userId: userId ?? 'unknown',
        userName: userName,
        deviceInfo: kIsWeb ? 'web_browser' : 'mobile_device',
        isSuccessful: false,
        ipAddress: 'dynamic',
      );
      
      throw e;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    String? userId;
    String userName = 'google_user';
    
    try {
      debugPrint('🔐 Iniciando Google Sign-In...');
      
      // Força o logout antes de tentar logar novamente
      await _googleSignIn.signOut();
      debugPrint('🔐 Logout anterior realizado');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🔐 Google Sign In cancelado pelo usuário');
        return null;
      }
      
      userName = googleUser.displayName ?? googleUser.email.split('@')[0];
      debugPrint('🔐 Usuário Google selecionado: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Falha ao obter credenciais do Google');
        throw Exception('Failed to get Google credentials');
      }
      
      debugPrint('🔐 Credenciais obtidas com sucesso');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      userId = userCredential.user?.uid;
      
      // Log successful login attempt
      if (userId != null) {
        await EventLogService.logLoginAttempt(
          userId: userId,
          userName: userName,
          deviceInfo: kIsWeb ? 'web_browser' : 'mobile_device',
          isSuccessful: true,
          ipAddress: 'dynamic',
        );
        
        // Configure security alerts for first-time users
        await EventLogService.configureSecurityAlerts(userId);
      }
      
      debugPrint('✅ Google Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Error signing in with Google: $e');
      
      // Log failed login attempt
      await EventLogService.logLoginAttempt(
        userId: userId ?? 'unknown',
        userName: userName,
        deviceInfo: kIsWeb ? 'web_browser' : 'mobile_device',
        isSuccessful: false,
        ipAddress: 'dynamic',
      );
      
      if (e.toString().contains('ApiException: 10')) {
        throw Exception('Erro de configuração do Google Sign-In. É necessário configurar as chaves SHA-1 no Firebase Console.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Falha no Google Sign-In. Verifique sua conexão com a internet e tente novamente.');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
      }
      
      throw Exception('Erro no Google Sign-In: ${e.toString()}');
    }
  }

  // Apple Sign In - Temporariamente desabilitado
  Future<UserCredential?> signInWithApple() async {
    throw UnimplementedError('Apple Sign In temporariamente indisponível');
    /*
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      throw e;
    }
    */
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw e;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sending password reset email: ${e.message}');
      throw e;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    // Update fields individually and handle a known Pigeon casting issue
    // Some firebase_auth native channel calls can throw a cast error like:
    // "type 'List<Object?>' is not a subtype of type 'PigeonUserInfo' in type cast"
    // In that case we log a warning and continue (the user often still exists and profile may be set server-side).
    try {
      if (displayName != null) {
        try {
          await currentUser?.updateDisplayName(displayName);
        } catch (e) {
          debugPrint('Warning updating displayName: $e');
          if (e.toString().contains('PigeonUserInfo') || e.toString().contains('List<Object?>')) {
            // swallow known plugin/platform casting bug
          } else {
            rethrow;
          }
        }
      }

      if (photoURL != null) {
        try {
          await currentUser?.updatePhotoURL(photoURL);
        } catch (e) {
          debugPrint('Warning updating photoURL: $e');
          if (e.toString().contains('PigeonUserInfo') || e.toString().contains('List<Object?>')) {
            // swallow known plugin/platform casting bug
          } else {
            rethrow;
          }
        }
      }

      try {
        await currentUser?.reload();
      } catch (e) {
        debugPrint('Warning reloading user after update: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      // Don't rethrow to avoid breaking higher-level flows (signup/login). Caller will see logs.
    }
  }
}
