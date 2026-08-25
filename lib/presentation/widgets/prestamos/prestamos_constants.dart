import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Providers globales ──────────────────────────────────────────────────────
final codEmpresaPrestamosProvider = StateProvider<int>((ref) => 0);
const codEmpresasExcluidas = <int>{7};

// ── Formateadores ───────────────────────────────────────────────────────────
final fmtPrestamo = NumberFormat('#,##0.00', 'en_US');
final fmtFechaPrestamo = DateFormat('dd/MM/yyyy');

// ── Constantes ───────────────────────────────────────────────────────────────
const estadosAsignacion = ['TODOS', 'NO ASIGNADO', 'ASIGNADO'];

// ── Anchos de columna (desktop) ──────────────────────────────────────────────
const wN = 52.0;
const wTrans = 250.0;
const wFec = 108.0;
const wMon = 148.0;
const wEst = 150.0;
const wAcc = 120.0;

// ── Helper: config visual de estado ─────────────────────────────────────────
typedef ECfg = ({Color bg, Color fg, IconData icon, String label});

ECfg eCfg(String estado, bool isDark) => switch (estado.toUpperCase()) {
  'ASIGNADO' => (
    bg: isDark ? const Color(0xFF1B3A2F) : const Color(0xFFE8F5E9),
    fg: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
    icon: Icons.check_circle_rounded,
    label: estado,
  ),
  'NO ASIGNADO' => (
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
