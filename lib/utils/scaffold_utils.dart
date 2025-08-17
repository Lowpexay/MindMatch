import 'package:flutter/material.dart';
import '../screens/main_navigation.dart';

class ScaffoldUtils {
  /// Mostra um SnackBar usando a chave global do MainNavigation
  static void showSnackBar(String message, {Color? backgroundColor}) {
    final scaffoldState = MainNavigation.scaffoldKey.currentState;
    if (scaffoldState != null && scaffoldState.mounted) {
      ScaffoldMessenger.of(scaffoldState.context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  /// Mostra um SnackBar de sucesso
  static void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Mostra um SnackBar de erro
  static void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }
}
