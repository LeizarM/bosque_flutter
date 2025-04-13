import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estado para manejar el tema de la aplicación
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  // Cargar el tema desde SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 1; // Por defecto ThemeMode.light (1)
    state = ThemeMode.values[themeIndex];
  }

  // Guardar el tema en SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  // Cambiar al tema oscuro
  void setDarkMode() {
    state = ThemeMode.dark;
    _saveThemeMode(state);
  }

  // Cambiar al tema claro
  void setLightMode() {
    state = ThemeMode.light;
    _saveThemeMode(state);
  }

  // Alternar entre temas
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(state);
  }
}

// Provider para el modo del tema
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});