import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SafeNavigation {
  /// Navega de forma segura, tratando erros "Pigeon" e outros problemas de navegação
  static Future<void> safeNavigate(BuildContext context, String route, {
    Object? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!context.mounted) return;
    
    try {
      // Aguarda um frame para garantir que o contexto está válido
      await Future.delayed(Duration(milliseconds: 100));
      
      if (context.mounted) {
        if (pathParameters != null || queryParameters != null || extra != null) {
          context.goNamed(
            route,
            pathParameters: pathParameters ?? {},
            queryParameters: queryParameters ?? {},
            extra: extra,
          );
        } else {
          context.go(route);
        }
      }
    } catch (e) {
      debugPrint('Navigation error caught: $e');
      
      // Se for erro Pigeon, aguarda um pouco e tenta novamente
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('channel-error') ||
          e.toString().contains('List<Object?>')) {
        
        debugPrint('Pigeon error detected in navigation, retrying...');
        
        // Aguarda e tenta novamente
        await Future.delayed(Duration(milliseconds: 500));
        
        if (context.mounted) {
          try {
            context.go(route);
          } catch (retryError) {
            debugPrint('Retry navigation also failed: $retryError');
            // Se ainda falhar, navega para home como fallback
            if (context.mounted && route != '/home') {
              context.go('/home');
            }
          }
        }
      } else {
        // Para outros erros, tenta navegar para home como fallback
        if (context.mounted && route != '/home') {
          try {
            context.go('/home');
          } catch (fallbackError) {
            debugPrint('Fallback navigation also failed: $fallbackError');
          }
        }
      }
    }
  }
  
  /// Navega de forma segura substituindo a rota atual
  static Future<void> safeReplace(BuildContext context, String route) async {
    if (!context.mounted) return;
    
    try {
      await Future.delayed(Duration(milliseconds: 100));
      
      if (context.mounted) {
        context.pushReplacement(route);
      }
    } catch (e) {
      debugPrint('Replace navigation error: $e');
      // Fallback para navigate normal
      await safeNavigate(context, route);
    }
  }
  
  /// Verifica se a navegação é segura (contexto válido)
  static bool canNavigate(BuildContext context) {
    return context.mounted;
  }
  
  /// Aguarda e depois navega (útil após operações assíncronas)
  static Future<void> delayedNavigate(
    BuildContext context, 
    String route, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(delay);
    await safeNavigate(context, route);
  }
}
