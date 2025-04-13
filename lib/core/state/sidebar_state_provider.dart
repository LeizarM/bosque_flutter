
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estado para manejar la visibilidad del sidebar
class SidebarVisibilityNotifier extends StateNotifier<bool> {
  SidebarVisibilityNotifier() : super(true) {
    _loadState();
  }

  // Cargar el estado desde SharedPreferences
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sidebar_visible') ?? true;
  }

  // Guardar el estado en SharedPreferences
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_visible', state);
  }

  // Método para alternar la visibilidad del sidebar
  void toggleSidebar() {
    state = !state;
    _saveState();
  }

  // Método para establecer la visibilidad directamente
  void setSidebarVisible(bool isVisible) {
    state = isVisible;
    _saveState();
  }
}

// Provider para la visibilidad del sidebar
final sidebarVisibilityProvider = StateNotifierProvider<SidebarVisibilityNotifier, bool>((ref) {
  return SidebarVisibilityNotifier();
});