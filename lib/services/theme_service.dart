import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeService manages light/dark theme state with persistence.
class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'is_dark_theme';
  bool _isDark = false;
  bool _loaded = false;

  bool get isDark => _isDark;
  bool get isLoaded => _loaded; // can be used to show splash if needed

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      debugPrint('ThemeService load error: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDark);
    } catch (e) {
      debugPrint('ThemeService save error: $e');
    }
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDark);
    } catch (e) {
      debugPrint('ThemeService save error: $e');
    }
  }
}
