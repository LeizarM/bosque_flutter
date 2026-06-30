import 'package:flutter/material.dart';

typedef ECfg = ({Color bg, Color fg, IconData icon, String label});

ECfg eCfgPlanilla(String estado, bool isDark) => switch (estado.toUpperCase()) {
  'EJECUTADO' => (
    bg: isDark ? const Color(0xFF1B3A2F) : const Color(0xFFE8F5E9),
    fg: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
    icon: Icons.check_circle_rounded,
    label: estado,
  ),
  'NO EJECUTADO' => (
    bg: isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0),
    fg: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
    icon: Icons.schedule_rounded,
    label: estado,
  ),
  _ => (
    bg: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
    fg: isDark ? Colors.white70 : Colors.grey.shade600,
    icon: Icons.help_outline_rounded,
    label: estado,
  ),
};
