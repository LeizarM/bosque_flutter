import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Providers globales ──────────────────────────────────────────────────────
final codEmpresaMultasProvider = StateProvider<int>((ref) => 0);
const codEmpresasExcluidas = <int>{7};

// ── Formateadores ───────────────────────────────────────────────────────────
final fmtMonto = NumberFormat('#,##0.00', 'en_US');

// ── Constantes ───────────────────────────────────────────────────────────────
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
const wEmp = 250.0;
const wSeg = 150.0;
const wMonto = 120.0;
const wDias = 100.0;
const wAcc = 80.0;
