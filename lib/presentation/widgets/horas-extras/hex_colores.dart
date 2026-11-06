/// Color e íconos del módulo Horas Extras: el verde y el ámbar armonizados
/// con la semilla del usuario, el tono de cada estado y la ficha con ícono.
/// El color nunca va solo: cada estado lleva además su ícono y su texto.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Matiz de partida del verde (aprobado, pagado, cumple) y del ámbar (en
/// espera, aviso), en grados HSL, y el tramo del que no salen al armonizar.
/// Pasado 42° el ámbar pleno se ve oliva; antes de 34°, se acerca al error.
const double _matizVerde = 140;
const double _matizAmbar = 40;
const (double, double) _tramoVerde = (115, 155);
const (double, double) _tramoAmbar = (34, 42);

/// Lo más que se acerca un matiz al de `primary`, como `harmonize` de Material.
const double _giroMaximo = 15;

/// Verde y ámbar semánticos del módulo, armonizados con la semilla elegida.
/// Cada familia sale de `ColorScheme.fromSeed`, así respeta claro y oscuro.
@immutable
class HexColores {
  const HexColores._({
    required this.exito,
    required this.alEnExito,
    required this.exitoContenedor,
    required this.alEnExitoContenedor,
    required this.pendiente,
    required this.alEnPendiente,
    required this.pendienteContenedor,
    required this.alEnPendienteContenedor,
  });

  final Color exito;
  final Color alEnExito;
  final Color exitoContenedor;
  final Color alEnExitoContenedor;
  final Color pendiente;
  final Color alEnPendiente;
  final Color pendienteContenedor;
  final Color alEnPendienteContenedor;

  static final Map<(int, Brightness), HexColores> _cache = {};

  /// Los colores del tema actual.
  static HexColores de(BuildContext context) =>
      desde(Theme.of(context).colorScheme);

  /// Una sola vez por (primary, brillo): `fromSeed` no es gratis.
  static HexColores desde(ColorScheme cs) => _cache.putIfAbsent((
    cs.primary.toARGB32(),
    cs.brightness,
  ), () => _armar(cs));

  static HexColores _armar(ColorScheme cs) {
    final destino = HSLColor.fromColor(cs.primary).hue;
    ColorScheme familia(
      double base,
      (double, double) tramo,
      double saturacion,
      double luz,
    ) => ColorScheme.fromSeed(
      seedColor:
          HSLColor.fromAHSL(
            1,
            matizArmonizado(base, destino).clamp(tramo.$1, tramo.$2),
            saturacion,
            luz,
          ).toColor(),
      brightness: cs.brightness,
    );
    final verde = familia(_matizVerde, _tramoVerde, 0.6, 0.4);
    final ambar = familia(_matizAmbar, _tramoAmbar, 0.9, 0.5);
    return HexColores._(
      exito: verde.primary,
      alEnExito: verde.onPrimary,
      exitoContenedor: verde.primaryContainer,
      alEnExitoContenedor: verde.onPrimaryContainer,
      pendiente: ambar.primary,
      alEnPendiente: ambar.onPrimary,
      pendienteContenedor: ambar.primaryContainer,
      alEnPendienteContenedor: ambar.onPrimaryContainer,
    );
  }

  /// [base] acercado a [destino] la mitad de la distancia, hasta 15°, por el
  /// lado más corto del círculo: el mismo giro que `Blend.harmonize`.
  @visibleForTesting
  static double matizArmonizado(double base, double destino) {
    final distancia = 180 - ((base - destino).abs() % 360 - 180).abs();
    final giro = math.min(distancia * 0.5, _giroMaximo);
    final sentido = (destino - base) % 360 <= 180 ? 1 : -1;
    return (base + giro * sentido) % 360;
  }

  @visibleForTesting
  static void olvidarCache() => _cache.clear();
}

/// Las familias de color del módulo: los roles del tema más el verde y el
/// ámbar de [HexColores].
enum TonoHex {
  neutro,
  primario,
  primarioSolido,
  terciario,
  pendiente,
  exito,
  exitoSolido,
  error,
}

/// El fondo y la letra de una ficha en [tono].
({Color fondo, Color letra}) coloresTonoHex(
  BuildContext context,
  TonoHex tono,
) {
  final cs = Theme.of(context).colorScheme;
  final hc = HexColores.desde(cs);
  return switch (tono) {
    TonoHex.neutro => (
      fondo: cs.surfaceContainerHighest,
      letra: cs.onSurfaceVariant,
    ),
    TonoHex.primario => (
      fondo: cs.primaryContainer,
      letra: cs.onPrimaryContainer,
    ),
    TonoHex.primarioSolido => (fondo: cs.primary, letra: cs.onPrimary),
    TonoHex.terciario => (
      fondo: cs.tertiaryContainer,
      letra: cs.onTertiaryContainer,
    ),
    TonoHex.pendiente => (
      fondo: hc.pendienteContenedor,
      letra: hc.alEnPendienteContenedor,
    ),
    TonoHex.exito => (fondo: hc.exitoContenedor, letra: hc.alEnExitoContenedor),
    TonoHex.exitoSolido => (fondo: hc.exito, letra: hc.alEnExito),
    TonoHex.error => (fondo: cs.errorContainer, letra: cs.onErrorContainer),
  };
}

/// El color pleno de [tono] para un ícono o un texto sobre la superficie.
Color acentoTonoHex(BuildContext context, TonoHex tono) {
  final cs = Theme.of(context).colorScheme;
  final hc = HexColores.desde(cs);
  return switch (tono) {
    TonoHex.neutro => cs.onSurfaceVariant,
    TonoHex.primario || TonoHex.primarioSolido => cs.primary,
    TonoHex.terciario => cs.tertiary,
    TonoHex.pendiente => hc.pendiente,
    TonoHex.exito || TonoHex.exitoSolido => hc.exito,
    TonoHex.error => cs.error,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// MAPAS: ESTADOS, TIPOS, DÍAS Y COMIDAS
// ═══════════════════════════════════════════════════════════════════════════

/// Cómo se ve un estado: su tono, su ícono y si va tachado.
typedef EstadoVisualHex = ({TonoHex tono, IconData icono, bool tachado});

/// El mapa de estados del reporte y de la planilla (contrato D29).
EstadoVisualHex estadoVisualHex(String? estado) => switch (estado) {
  'REPORTADO' => (
    tono: TonoHex.pendiente,
    icono: Icons.hourglass_top,
    tachado: false,
  ),
  'VISTO_BUENO' => (
    tono: TonoHex.terciario,
    icono: Icons.task_alt,
    tachado: false,
  ),
  'APROBADO' => (
    tono: TonoHex.exito,
    icono: Icons.verified_outlined,
    tachado: false,
  ),
  'LIQUIDADO' => (
    tono: TonoHex.exitoSolido,
    icono: Icons.paid_outlined,
    tachado: false,
  ),
  'RECHAZADO' => (
    tono: TonoHex.error,
    icono: Icons.cancel_outlined,
    tachado: false,
  ),
  'ANULADO' => (tono: TonoHex.neutro, icono: Icons.block, tachado: true),
  'EJECUTADA' => (
    tono: TonoHex.exitoSolido,
    icono: Icons.receipt_long,
    tachado: false,
  ),
  'ANULADA' => (tono: TonoHex.neutro, icono: Icons.block, tachado: false),
  _ => (tono: TonoHex.neutro, icono: Icons.label_outline, tachado: false),
};

/// Tono de la etiqueta según el estado de un reporte o de una planilla.
TonoHex tonoEstadoHex(String? estado) => estadoVisualHex(estado).tono;

/// Tono del punto de un evento del historial (`tipo` del SP): las firmas con
/// el color del estado al que llevan; lo demás en `primary`.
TonoHex tonoEventoHex(String? tipo) => switch (tipo) {
  'VISTO_BUENO' || 'EDICION' => TonoHex.terciario,
  'APROBACION' || 'LIQUIDACION' => TonoHex.exito,
  'RECHAZO' => TonoHex.error,
  'ANULACION' || 'PLANILLA_ANULADA' => TonoHex.neutro,
  _ => TonoHex.primario,
};

/// Ícono del tipo de reporte (`tipo` del SP).
IconData iconoTipoReporteHex(String? tipo) => switch (tipo) {
  'ANTES' => Icons.wb_twilight,
  'DESPUES' => Icons.nightlight_outlined,
  'SIN_HORARIO' => Icons.event_available_outlined,
  _ => Icons.schedule,
};

/// Domingo y feriado rinden más: van en la familia terciaria.
bool diaEspecialHex(String? tipoDia) =>
    tipoDia == 'DOMINGO' || tipoDia == 'FERIADO';

/// Ícono del tipo de día (`tipoDia` del SP).
IconData iconoTipoDiaHex(String? tipoDia) => switch (tipoDia) {
  'DOMINGO' => Icons.weekend_outlined,
  'FERIADO' => Icons.celebration_outlined,
  _ => Icons.calendar_today_outlined,
};

/// De qué es un código de la planilla: horas extra (tramo) o comida.
enum FamiliaCodigoHex { tramo, comida }

/// El ícono de una comida por la última letra de su código, como los carga el
/// script inicial (D/DD, A/DA, C/DC); otra letra lleva el ícono genérico.
IconData iconoComidaHex(String codigo) {
  final c = codigo.trim().toUpperCase();
  if (c.isEmpty) return Icons.restaurant_outlined;
  return switch (c[c.length - 1]) {
    'D' => Icons.free_breakfast_outlined,
    'A' => Icons.lunch_dining_outlined,
    'C' => Icons.dinner_dining_outlined,
    _ => Icons.restaurant_outlined,
  };
}

/// Una comida doble lleva el código de dos letras (DD, DA, DC).
bool comidaDobleHex(String codigo) => codigo.trim().length > 1;

/// El fondo y la letra de un código: tramos en la familia principal, con más
/// presencia cuanto mayor es el factor; comidas en la terciaria, la doble plena.
({Color fondo, Color letra}) coloresCodigoHex(
  BuildContext context,
  String codigo, {
  FamiliaCodigoHex? familia,
  double? multiplicador,
}) {
  final cs = Theme.of(context).colorScheme;
  Color suave(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.55), cs.surface);
  return switch (familia) {
    null => (fondo: cs.surfaceContainerHighest, letra: cs.onSurface),
    FamiliaCodigoHex.comida =>
      comidaDobleHex(codigo)
          ? (fondo: cs.tertiaryContainer, letra: cs.onTertiaryContainer)
          : (fondo: suave(cs.tertiaryContainer), letra: cs.onTertiaryContainer),
    FamiliaCodigoHex.tramo => switch (multiplicador) {
      final m? when m >= 2 => (fondo: cs.primary, letra: cs.onPrimary),
      final m? when m > 1 => (
        fondo: cs.primaryContainer,
        letra: cs.onPrimaryContainer,
      ),
      _ => (fondo: suave(cs.primaryContainer), letra: cs.onPrimaryContainer),
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// FICHA CON ÍCONO
// ═══════════════════════════════════════════════════════════════════════════

/// Ficha con ícono y texto (12 sp, ícono de 16) en un [tono] del módulo. Con
/// [contorno], fondo transparente y el ícono en [colorIcono]. [ayuda] la
/// explica al pasar el puntero o con pulsación larga.
class ChipHex extends StatelessWidget {
  const ChipHex({
    super.key,
    required this.texto,
    this.icono,
    this.tono = TonoHex.neutro,
    this.tachado = false,
    this.contorno = false,
    this.colorIcono,
    this.ayuda,
  });

  final String texto;
  final IconData? icono;
  final TonoHex tono;
  final bool tachado;
  final bool contorno;
  final Color? colorIcono;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final par = coloresTonoHex(context, tono);
    final letra = contorno ? cs.onSurface : par.letra;
    final ico = icono;
    // `min` + `Flexible` suelto: envuelve en una celda angosta y no falla
    // dentro de una fila sin ancho límite.
    final ficha = Container(
      padding: EdgeInsets.fromLTRB(ico == null ? Esp.s : 6, 3, Esp.s, 3),
      decoration: BoxDecoration(
        color: contorno ? null : par.fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
        border: contorno ? Border.all(color: cs.outlineVariant) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ico != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 0.5),
              child: Icon(
                ico,
                size: 16,
                color: colorIcono ?? (contorno ? cs.primary : letra),
              ),
            ),
            const SizedBox(width: Esp.xs),
          ],
          Flexible(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: letra,
                fontWeight: FontWeight.w600,
                decoration: tachado ? TextDecoration.lineThrough : null,
                decorationColor: letra,
              ),
            ),
          ),
        ],
      ),
    );
    final explicacion = ayuda?.trim() ?? '';
    return explicacion.isEmpty
        ? ficha
        : Tooltip(message: explicacion, child: ficha);
  }
}

/// Ícono y texto sin ficha, en el color pleno de [tono]: para celdas angostas
/// donde una ficha partiría las palabras.
class IconoTextoHex extends StatelessWidget {
  const IconoTextoHex({
    super.key,
    required this.texto,
    required this.icono,
    this.tono = TonoHex.neutro,
    this.colorIcono,
    this.colorTexto,
    this.estilo,
  });

  final String texto;
  final IconData icono;
  final TonoHex tono;
  final Color? colorIcono;
  final Color? colorTexto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final acento = acentoTonoHex(context, tono);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icono, size: 16, color: colorIcono ?? acento),
        ),
        const SizedBox(width: Esp.xs),
        Flexible(
          child: Text(
            texto,
            style: (estilo ?? Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
                  fontSize: 12,
                  color: colorTexto ?? acento,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

/// Un aviso a todo el ancho en un [tono] del módulo: [titulo] en negrita y
/// [texto] debajo. Se anuncia a los lectores de pantalla al aparecer.
class AvisoHex extends StatelessWidget {
  const AvisoHex({
    super.key,
    required this.texto,
    required this.icono,
    this.tono = TonoHex.neutro,
    this.titulo,
    this.maxLineas,
  });

  final String texto;
  final IconData icono;
  final TonoHex tono;
  final String? titulo;
  final int? maxLineas;

  @override
  Widget build(BuildContext context) {
    final par = coloresTonoHex(context, tono);
    final t = Theme.of(context).textTheme;
    final cabeza = titulo?.trim() ?? '';
    final cuerpo = texto.trim();
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: par.fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 20, color: par.letra),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cabeza.isNotEmpty)
                    Text(
                      cabeza,
                      style: t.bodyMedium?.copyWith(
                        color: par.letra,
                        fontWeight: Peso.titulo,
                      ),
                    ),
                  if (cuerpo.isNotEmpty)
                    Text(
                      cuerpo,
                      maxLines: maxLineas,
                      overflow:
                          maxLineas == null ? null : TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: par.letra,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El título de una sección con su ícono en `primary`.
class TituloSeccionHex extends StatelessWidget {
  const TituloSeccionHex(this.texto, {super.key, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Row(
      children: [
        Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: context.tituloSeccion())),
      ],
    ),
  );
}
