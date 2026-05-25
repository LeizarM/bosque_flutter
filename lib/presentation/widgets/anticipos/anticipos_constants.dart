import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Providers globales ──────────────────────────────────────────────────────
final codEmpresaAnticiposProvider = StateProvider<int>((ref) => 0);
const codEmpresasExcluidas = <int>{7};

// ── Formateadores ───────────────────────────────────────────────────────────
final fmtAnticipo = NumberFormat('#,##0.00', 'en_US');
final fmtFechaAnticipo = DateFormat('dd/MM/yyyy');

// ── Constantes ───────────────────────────────────────────────────────────────
const estados = ['NO ASIGNADO', 'ASIGNADO', 'ANULADO', 'CANCELADO'];
const meses = [
  {'v': '1', 'l': 'ENERO'},
  {'v': '2', 'l': 'FEBRERO'},
  {'v': '3', 'l': 'MARZO'},
  {'v': '4', 'l': 'ABRIL'},
  {'v': '5', 'l': 'MAYO'},
  {'v': '6', 'l': 'JUNIO'},
  {'v': '7', 'l': 'JULIO'},
  {'v': '8', 'l': 'AGOSTO'},
  {'v': '9', 'l': 'SEPTIEMBRE'},
  {'v': '10', 'l': 'OCTUBRE'},
  {'v': '11', 'l': 'NOVIEMBRE'},
  {'v': '12', 'l': 'DICIEMBRE'},
];

// ── Configuración de gestiones ──────────────────────────────────────────────
const anioBase = 2026;
const maxGestiones = 5; // Cuántas gestiones mostrar hacia atrás

// ── Anchos de columna (desktop) ──────────────────────────────────────────────
const wN = 52.0;
const wRef = 120.0;
const wFec = 108.0;
const wMon = 148.0;
const wEst = 150.0;
const wAcc = 180.0;

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
  'ANULADO' => (
    bg: isDark ? const Color(0xFF3B1A1A) : const Color(0xFFFFEBEE),
    fg: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
    icon: Icons.cancel_rounded,
    label: estado,
  ),
  'CANCELADO' => (
    bg: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEDE7F6),
    fg: isDark ? const Color(0xFFB39DDB) : const Color(0xFF4527A0),
    icon: Icons.lock_outline_rounded,
    label: estado,
  ),
  _ => (
    bg: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
    fg: isDark ? Colors.white70 : Colors.grey.shade600,
    icon: Icons.help_outline_rounded,
    label: estado,
  ),
};
