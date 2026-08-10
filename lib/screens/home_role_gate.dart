import 'package:flutter/material.dart';
import 'package:mindmatch/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import 'psychologist_navigation.dart';

class HomeRoleGate extends StatefulWidget {
  const HomeRoleGate({super.key});

  @override
  State<HomeRoleGate> createState() => _HomeRoleGateState();
}

class _HomeRoleGateState extends State<HomeRoleGate> {
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileFuture != null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    _profileFuture = userId == null
        ? Future<Map<String, dynamic>?>.value(null)
        : firebaseService.getUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      return const HomeScreen();
    }

    final future = _profileFuture;
    if (future == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = (snapshot.data?['role']?.toString() ?? '').toUpperCase();
        if (role == 'PSYCHOLOGIST') {
          return const PsychologistNavigation();
        }

        return const MainNavigation();
      },
    );
  }
}
