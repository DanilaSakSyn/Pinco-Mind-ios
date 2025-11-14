import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _loadPersistedMode();
  }

  static const String _themeModeKey = 'settings.themeMode';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  void updateMode(ThemeMode newMode) {
    if (newMode == _mode) {
      return;
    }
    _mode = newMode;
    notifyListeners();
    _persistMode(newMode);
  }

  void _loadPersistedMode() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      final String? stored = prefs.getString(_themeModeKey);
      if (stored == null) {
        return;
      }
      final ThemeMode? parsed = _themeModeFromString(stored);
      if (parsed != null && parsed != _mode) {
        _mode = parsed;
        notifyListeners();
      }
    });
  }

  void _persistMode(ThemeMode mode) {
    SharedPreferences.getInstance().then(
      (SharedPreferences prefs) => prefs.setString(_themeModeKey, mode.name),
    );
  }

  static ThemeMode? _themeModeFromString(String value) {
    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return null;
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({required super.notifier, required super.child, super.key});

  static ThemeController of(BuildContext context) {
    final ThemeScope? scope = context
        .dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in context');
    return scope!.notifier!;
  }
}

class AppPalette {
  static const Color darkPrimary = Color(0xFFD946EF);
  static const Color darkPrimarySoft = Color(0xFF9D4CFF);
  static const Color darkSurface = Color(0xFF0F001F);
  static const Color darkSurfaceElevated = Color(0xFF1C0135);
  static const Color darkGlow = Color(0xFFFF7AF6);
  static const Color darkTextPrimary = Color(0xFFF6EBFF);
  static const Color darkTextSecondary = Color(0xFFCFB5FF);
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: <Color>[Color(0xFF080013), Color(0xFF230035), Color(0xFF3F0060)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: <Color>[Color(0x33250047), Color(0x26380067)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0xB3FF7AF6),
      blurRadius: 30,
      spreadRadius: 2,
      offset: Offset(0, 14),
    ),
  ];
}
