import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isDarkModeProvider = StateProvider<bool>((ref) => false);

//Lista de colores inmutable

final colorListProvider = Provider((ref) => colorList);

final selectedColorProvider = StateProvider((ref) => 0);

// un objeto de tipo AppTheme

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, AppTheme>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<AppTheme> {
  final _storage = SecureStorage();

  ThemeNotifier() : super(AppTheme()) {
    _loadSavedTheme();
  }

  /// Carga el tema guardado desde el almacenamiento con timeout de seguridad
  Future<void> _loadSavedTheme() async {
    try {
      final results = await Future.wait([
        _storage.getThemeColor(),
        _storage.getThemeDarkMode(),
      ]).timeout(
        const Duration(seconds: 3),
        onTimeout: () => [2, false], // defaults: color verde, modo claro
      );

      state = state.copyWith(
        selectedColor: results[0] as int,
        isDarkMode: results[1] as bool,
      );
    } catch (e) {
      // Si falla, usar valores por defecto (ya están en el estado inicial)
    }
  }

  void toggleDarkMode() {
    final newDarkMode = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newDarkMode);
    _storage.saveThemeDarkMode(newDarkMode);
  }

  void changeColorIndex(int colorIndex) {
    state = state.copyWith(selectedColor: colorIndex);
    _storage.saveThemeColor(colorIndex);
  }
}
