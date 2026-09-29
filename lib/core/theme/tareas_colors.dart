// Destino final: lib/core/theme/tareas_colors.dart
//
// Sistema de color semántico para el módulo Tareas Rutinarias.
//
// Por qué no son hex fijos: AppTheme usa colorSchemeSeed elegible por el
// usuario (9 semillas, ver app_theme.dart) + modo oscuro — un hex fijo se
// vería bien con una semilla y mal (o ilegible) con otra, o en el modo de
// brillo contrario. Todo aquí deriva de HSLColor sobre tonos base fijos
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

  static Color vencido(BuildContext context) => _tone(
    context,
    hue: 6,
    lightBg: 0.94,
    darkBg: 0.22,
  ); // coral, no rojo puro
  static Color vencidoTexto(BuildContext context) => _toneText(context, hue: 6);

  static Color realizado(BuildContext context) =>
      _tone(context, hue: 152, lightBg: 0.93, darkBg: 0.20); // verde azulado
  static Color realizadoTexto(BuildContext context) =>
      _toneText(context, hue: 152);

  static Color noAplica(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color noAplicaTexto(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  // ── Acciones ────────────────────────────────────────────────────────────

  /// Rojo de accion destructiva: el tacho que borra una fila del formulario.
  ///
  /// **Mas saturado que [vencido] a proposito, aunque compartan familia de
  /// tono.** `vencido` es un ESTADO: tine fondos enteros de tarjetas y filas,
  /// asi que tiene que ser tenue o la lista se vuelve una pared roja. Este es
  /// un icono de 20px perdido en el borde de una planilla, y tiene el trabajo
  /// contrario: que se note que ese boton borra antes de tocarlo.
  ///
  /// No se usa `colorScheme.error` porque ese rojo lo fija el tema global de
  /// la app y no acompana a la paleta HSL del modulo.
  static Color eliminar(BuildContext context) =>
      HSLColor.fromAHSL(1.0, 4, 0.72, _isDark(context) ? 0.68 : 0.47).toColor();

  /// Fondo tenue del mismo rojo, para el hover/splash del boton de borrar.
  static Color eliminarFondo(BuildContext context) =>
      _tone(context, hue: 4, lightBg: 0.95, darkBg: 0.20);

  // ── Cuadre de arqueo (tac_arqueoCajaSucursales) ─────────────────────────
  static Color cuadrado(BuildContext context) => realizado(context);
  static Color cuadradoTexto(BuildContext context) => realizadoTexto(context);
  static Color descuadrado(BuildContext context) => vencido(context);
  static Color descuadradoTexto(BuildContext context) => vencidoTexto(context);

  // ── Acentos de sección (pantallas con varios bloques temáticos, p.ej.
  // Arqueo de caja) ────────────────────────────────────────────────────────
  // No son estado (como pendiente/vencido/realizado): son identidad visual
  // fija por tipo de contenido, para que el ojo separe de un vistazo "esto
  // es un dato de SAP" de "esto es el tipo de cambio" de "esto es un vale",
  // igual que el legacy los distinguía con tablas/colores propios por
  // bloque (Marcelo, 2026-09-07: "sigue feo, feo la UI/UX"). Hues elegidos
  // para no pisar los ya usados arriba (32/6/152) ni los de frecuencia
  // (210/265/320/20/145). El propio "Cortes" no tiene tono aquí a propósito:
  // usa colorScheme.primary directo, porque es el dato accionable central
  // de la pantalla, no uno más entre varios bloques informativos.
  static Color sapMovimiento(BuildContext context) =>
      _tone(context, hue: 199, lightBg: 0.93, darkBg: 0.20); // azul dato/banco
  static Color sapMovimientoTexto(BuildContext context) =>
      _toneText(context, hue: 199);

  static Color tipoCambio(BuildContext context) =>
      _tone(context, hue: 45, lightBg: 0.93, darkBg: 0.20); // dorado
  static Color tipoCambioTexto(BuildContext context) =>
      _toneText(context, hue: 45);

  static Color documentacion(BuildContext context) =>
      _tone(context, hue: 280, lightBg: 0.94, darkBg: 0.22); // violeta
  static Color documentacionTexto(BuildContext context) =>
      _toneText(context, hue: 280);

  static Color vales(BuildContext context) =>
      _tone(context, hue: 350, lightBg: 0.94, darkBg: 0.22); // rosado
  static Color valesTexto(BuildContext context) => _toneText(context, hue: 350);

  static Color cajaFuerte(BuildContext context) =>
      _tone(context, hue: 85, lightBg: 0.93, darkBg: 0.20); // oliva
  static Color cajaFuerteTexto(BuildContext context) =>
      _toneText(context, hue: 85);

  // ── Tipo de tarea (tac_accionTareaRutinaria.idATR) ──────────────────────
  // La insignia del encabezado de cada pantalla y la de su fila en "Mis
  // tareas": el mismo icono y el mismo tono en los dos lugares, para que se
  // reconozca adónde se entró. Es identidad, no estado, así que ninguno usa
  // los hues de pendiente/vencido/realizado (32/6/152). Algunos coinciden con
  // los de frecuencia; no se confunden porque la insignia lleva su icono y la
  // frecuencia es una píldora de texto.
  static const Map<int, double> _huePorTipo = {
    2: 45, // Arqueo de caja: dorado, dinero contado
    3: 230, // Cierre de operaciones: azul
    4: 85, // Caja fuerte: oliva, el de su bloque en Arqueo
    5: 255, // Verificar cierre: índigo, el paso del supervisor
    6: 25, // Coches: naranja
    7: 350, // Caja chica: rosado, el de los vales
    11: 175, // Traspaso de efectivo (TesBase): turquesa
    12: 199, // Caja AXA: el azul de dato bancario de SAP
  };

  /// Fondo de la insignia de un tipo de tarea. Las tareas simples y las
  /// pantallas que no son de un tipo (bitácora, catálogo) usan el tono
  /// secundario del tema.
  static Color tipoTarea(BuildContext context, int? idATR) {
    final hue = _huePorTipo[idATR];
    if (hue == null) return Theme.of(context).colorScheme.secondaryContainer;
    return _tone(context, hue: hue, lightBg: 0.90, darkBg: 0.24);
  }

  static Color tipoTareaTexto(BuildContext context, int? idATR) {
    final hue = _huePorTipo[idATR];
    if (hue == null) return Theme.of(context).colorScheme.onSecondaryContainer;
    return _toneText(context, hue: hue);
  }

  // ── Frecuencia (tac_frecuencia) — 6 tonos distinguibles entre sí ────────
  // Recorren la rueda de color ordenados de "más seguido" (diaria) a "menos
  // seguido" (anual) para que la progresión se sienta, no solo se distinga.
  // El 4 (Bimestral) no tenía tono y caía en el 0: el rojo de "vencida", así
  // que una tarea bimestral parecía atrasada.
  static Color frecuencia(BuildContext context, int idFrec) {
    const huePorFrecuencia = {
      6: 210, // Diario   — azul
      2: 265, // Semanal  — violeta
      1: 320, // Mensual  — magenta suave
      4: 345, // Bimestral — rosa
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
      4: 345.0,
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

  /// El tono de PRIMER PLANO: iconos de seccion, texto de las pildoras de
  /// frecuencia, cifras de estado.
  ///
  /// Saturacion 0.68 y no 0.55 (2026-09-08, a pedido de Marcelo: "que se vean
  /// esos pequenos detalles mas vividos"). A 0.55 un icono de 18px sobre fondo
  /// claro se leia casi gris: el tono estaba, pero en un elemento tan chico no
  /// alcanzaba para distinguir la seccion de un vistazo.
  ///
  /// Deliberadamente NO se toca [_tone], que es el fondo: ese tine tarjetas y
  /// filas enteras, y subirle la saturacion convierte la pantalla en un
  /// semaforo. La regla del modulo es fondos calmos, acentos vivos.
  static Color _toneText(BuildContext context, {required double hue}) {
    final l = _isDark(context) ? 0.82 : 0.30;
    return HSLColor.fromAHSL(1.0, hue, 0.68, l).toColor();
  }
}
