import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Visibilidad del sidebar, persistida en SharedPreferences.
class SidebarVisibilityNotifier extends StateNotifier<bool> {
  SidebarVisibilityNotifier() : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sidebar_visible') ?? true;
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_visible', state);
  }

  void toggleSidebar() {
    state = !state;
    _saveState();
  }

  void setSidebarVisible(bool isVisible) {
    state = isVisible;
    _saveState();
  }
}

final sidebarVisibilityProvider =
    StateNotifierProvider<SidebarVisibilityNotifier, bool>((ref) {
      return SidebarVisibilityNotifier();
    });
