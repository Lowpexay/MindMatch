import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../security/eventlog_service.dart';

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

  // Email/Password Sign In com EventLog integrado
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    String? userId;
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      userId = userCredential.user?.uid;
      
      // Log successful login attempt with detailed info
      if (userId != null) {
        await EventLogService.logLoginAttempt(
          userId: userId,
          userName: email, // Email completo para EventLog
          deviceInfo: _getDeviceInfo(),
          isSuccessful: true,
          ipAddress: await _getClientIP(),
          userAgent: 'MindMatch-Mobile-v1.0',
        );
        
        // Configure security alerts for first-time users
        await EventLogService.configureSecurityAlerts(userId);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing in: ${e.message}');
      
      // Log failed login attempt with detailed info
      await EventLogService.logLoginAttempt(
        userId: 'failed_attempt',
        userName: email, // Email completo para EventLog
        deviceInfo: _getDeviceInfo(),
        isSuccessful: false,
        ipAddress: await _getClientIP(),
        userAgent: 'MindMatch-Mobile-v1.0',
      );
      
      throw e;
    }
  }

  // Email/Password Sign Up com EventLog
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log successful registration
      if (userCredential.user != null) {
        await EventLogService.logLoginAttempt(
          userId: userCredential.user!.uid,
          userName: email,
          deviceInfo: _getDeviceInfo(),
          isSuccessful: true,
          ipAddress: await _getClientIP(),
          userAgent: 'MindMatch-Mobile-v1.0',
        );
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error creating user: $e');
      
      // Log failed registration
      await EventLogService.logLoginAttempt(
        userId: 'failed_registration',
        userName: email,
        deviceInfo: _getDeviceInfo(),
        isSuccessful: false,
        ipAddress: await _getClientIP(),
        userAgent: 'MindMatch-Mobile-v1.0',
      );
      
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Log Google login
      if (userCredential.user != null) {
        await EventLogService.logLoginAttempt(
          userId: userCredential.user!.uid,
          userName: userCredential.user!.email ?? 'google_user',
          deviceInfo: _getDeviceInfo(),
          isSuccessful: true,
          ipAddress: await _getClientIP(),
          userAgent: 'MindMatch-Google-Auth',
        );
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Alias methods for backward compatibility
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await signInWithEmailAndPassword(email, password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await createUserWithEmailAndPassword(email, password);
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    return await updateProfile(displayName: displayName, photoURL: photoURL);
  }

  // Update Profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      if (displayName != null || photoURL != null) {
        await currentUser.updateDisplayName(displayName);
        if (photoURL != null) {
          await currentUser.updatePhotoURL(photoURL);
        }
      }

      try {
        await currentUser.reload();
      } catch (e) {
        debugPrint('Warning reloading user after update: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Obter informações detalhadas do device para EventLog
  String _getDeviceInfo() {
    if (kIsWeb) {
      return 'Web_Browser';
    } else {
      return 'Mobile_Device';
    }
  }

  /// Obter IP do cliente (simulado por enquanto)
  Future<String> _getClientIP() async {
    return '192.168.1.100';
  }
}
