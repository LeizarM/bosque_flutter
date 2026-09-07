// Destino final: lib/core/theme/tareas_colors.dart
//
// Sistema de color semántico para el módulo Tareas Rutinarias.
//
// Por qué no son hex fijos: AppTheme usa colorSchemeSeed elegible por el
// usuario (9 semillas, ver app_theme.dart) + modo oscuro — un hex fijo se
// vería bien con una semilla y mal (o ilegible) con otra, o en el modo de
// brillo contrario. Todo acá deriva de HSLColor sobre tonos base fijos
// (no del seed del usuario, a propósito: el significado de "vencido" o
// "cuadrado" no debe cambiar según qué color eligió cada quien) ajustando
// solo luminosidad/saturación según el brillo activo, así siempre hay
// contraste suficiente en los dos modos.
//
// Lección ya aprendida en este proyecto (ver el comentario en
// AppTheme.getTheme sobre dataTableTheme): el acento saturado se reserva
// para lo ACCIONABLE, no para etiquetas pasivas. Estos tonos de estado usan
// la misma disciplina — son fondos suaves de "chip"/badge con texto de alto
// contraste, nunca bloques saturados compitiendo con las acciones reales de
// la pantalla (que siguen usando colorScheme.primary vía los botones
// estándar de Material).
import 'package:flutter/material.dart';

class TareasColors {
  TareasColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Estado de una ocurrencia (tac_bitTareaRuti.fueRealizado) ────────────
  // 12=pendiente, 13=realizado, 14=no aplica — ver memoria del proyecto.
  static Color pendiente(BuildContext context) =>
      _tone(context, hue: 32, lightBg: 0.94, darkBg: 0.22); // ámbar cálido
  static Color pendienteTexto(BuildContext context) =>
      _toneText(context, hue: 32);

  static Color vencido(BuildContext context) =>
      _tone(context, hue: 6, lightBg: 0.94, darkBg: 0.22); // coral, no rojo puro
  static Color vencidoTexto(BuildContext context) =>
      _toneText(context, hue: 6);

  static Color realizado(BuildContext context) =>
      _tone(context, hue: 152, lightBg: 0.93, darkBg: 0.20); // verde azulado
  static Color realizadoTexto(BuildContext context) =>
      _toneText(context, hue: 152);

  static Color noAplica(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color noAplicaTexto(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  // ── Cuadre de arqueo (tac_arqueoCajaSucursales) ─────────────────────────
  static Color cuadrado(BuildContext context) => realizado(context);
  static Color cuadradoTexto(BuildContext context) => realizadoTexto(context);
  static Color descuadrado(BuildContext context) => vencido(context);
  static Color descuadradoTexto(BuildContext context) => vencidoTexto(context);

  // ── Frecuencia (tac_frecuencia) — 5 tonos distinguibles entre sí ────────
  // Recorren la rueda de color a intervalos parejos, ordenados de "más
  // seguido" (diaria) a "menos seguido" (anual) para que la progresión se
  // sienta, no solo se distinga.
  static Color frecuencia(BuildContext context, int idFrec) {
    const huePorFrecuencia = {
      6: 210, // Diario   — azul
      2: 265, // Semanal  — violeta
      1: 320, // Mensual  — magenta suave
      5: 20, // Semestral — naranja
      3: 145, // Anual     — verde
    };
    final hue = huePorFrecuencia[idFrec] ?? 0;
    return _tone(context, hue: hue.toDouble(), lightBg: 0.93, darkBg: 0.22);
  }

  static Color frecuenciaTexto(BuildContext context, int idFrec) {
    const huePorFrecuencia = {
      6: 210.0,
      2: 265.0,
      1: 320.0,
      5: 20.0,
      3: 145.0,
    };
    return _toneText(context, hue: huePorFrecuencia[idFrec] ?? 0);
  }

  // ── Profundidad en el árbol de dependientes (0=directo, más=más lejos) ──
  // Nivel 1 llega con más contraste; se atenúa a medida que baja, para leer
  // "cerca de mí" vs. "lejos en la cadena" de un vistazo.
  static Color profundidad(BuildContext context, int nivel) {
    final t = (1 - (nivel.clamp(1, 6) / 6)) * 0.5 + 0.5; // 1.0 → 0.5
    final base = Theme.of(context).colorScheme.primary;
    return Color.lerp(
      Theme.of(context).colorScheme.surfaceContainerHighest,
      base,
      t,
    )!;
  }

  // ── Helpers internos ─────────────────────────────────────────────────
  static Color _tone(
    BuildContext context, {
    required double hue,
    required double lightBg,
    required double darkBg,
  }) {
    final l = _isDark(context) ? darkBg : lightBg;
    return HSLColor.fromAHSL(1.0, hue, 0.55, l).toColor();
  }

  static Color _toneText(BuildContext context, {required double hue}) {
    final l = _isDark(context) ? 0.82 : 0.30;
    return HSLColor.fromAHSL(1.0, hue, 0.55, l).toColor();
  }
}
