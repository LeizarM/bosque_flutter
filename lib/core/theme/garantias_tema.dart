import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Tema del modulo de Garantias de cobranza.
///
/// Mismo patron que `TareasTema` y `ComisionesTema`: el modulo se envuelve en
/// su propio [Theme] y el resto de la app queda intacto. Cambia dos cosas y
/// nada mas —colores de marca, modo oscuro y semilla siguen saliendo del tema
/// de la app—:
///
/// - **Tipografia.** Plus Jakarta Sans en la interfaz (la de Tareas y
///   Comisiones: Roboto «se lee como pantalla sin diseñar») y **JetBrains Mono
///   para cifras, fechas, codigos y numeracion** ([GarantiasCifras.cifra]).
///   Una garantia es un documento con monto y plazo: en monoespaciada los
///   importes alinean por construccion en cualquier columna y el 0 lleva barra,
///   asi no se confunde con la O al leer un codigo SAP o un N° de garantia.
///
/// - **Colores de estado** ([GarantiasColores]). Las piezas comunes de la app
///   pintan el «aviso» con el color terciario de la semilla, que con la semilla
///   verde sale celeste: una garantia por vencer se leia como informacion, no
///   como advertencia. Aca el significado no depende de la semilla.
class GarantiasTema {
  const GarantiasTema._();

  static const String fuenteUI = 'PlusJakartaSans';
  static const String fuenteCifras = 'JetBrainsMono';

  static ThemeData temaModulo(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: fuenteUI),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fuenteUI),
    );
  }
}

/// Envoltorio de todo lo que dibuja el modulo: la pantalla y cada panel.
class GarantiasScope extends StatelessWidget {
  const GarantiasScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: GarantiasTema.temaModulo(context), child: child);
}

/// Estilo de cifras del modulo: importes, fechas, codigos y numeracion.
extension GarantiasCifras on BuildContext {
  /// JetBrains Mono. [tam] por defecto 12.5: la monoespaciada se ve mas grande
  /// que la proporcional al mismo tamaño y compite con el texto si no se baja.
  TextStyle cifra({bool fuerte = false, Color? color, double tam = 12.5}) =>
      TextStyle(
        fontFamily: GarantiasTema.fuenteCifras,
        fontSize: tam,
        fontWeight: fuerte ? Peso.dato : FontWeight.w400,
        color: color ?? Theme.of(this).colorScheme.onSurface,
        height: 1.2,
      );
}

/// Los cuatro significados que se pintan en el modulo.
enum Semantica { exito, aviso, peligro, neutro }

/// Colores de estado del modulo, derivados por HSL de tonos fijos (como
/// `TareasColors`): el significado de «vence pronto» no cambia segun la
/// semilla que eligio cada usuario, y la luminosidad se ajusta al modo claro u
/// oscuro para mantener el contraste.
///
/// - exito  = verde azulado (vigente)
/// - aviso  = ambar (por vencer, linea distinta de SAP, sin traspaso)
/// - peligro = coral, no rojo puro (caducada)
/// - neutro = del ColorScheme (cerrada, informacion)
class GarantiasColores {
  const GarantiasColores._();

  static bool _oscuro(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static double? _hue(Semantica s) => switch (s) {
    Semantica.exito => 158,
    Semantica.aviso => 36,
    Semantica.peligro => 6,
    Semantica.neutro => null,
  };

  /// Fondo suave de pastillas y avisos.
  static Color fondo(BuildContext c, Semantica s) {
    final h = _hue(s);
    if (h == null) return Theme.of(c).colorScheme.surfaceContainerHighest;
    return HSLColor.fromAHSL(1, h, 0.62, _oscuro(c) ? 0.20 : 0.92).toColor();
  }

  /// Texto e iconos sobre [fondo].
  static Color texto(BuildContext c, Semantica s) {
    final h = _hue(s);
    if (h == null) return Theme.of(c).colorScheme.onSurfaceVariant;
    return HSLColor.fromAHSL(1, h, 0.70, _oscuro(c) ? 0.82 : 0.28).toColor();
  }

  /// Tono pleno: barras de vigencia, marcas de fila, bordes.
  static Color pleno(BuildContext c, Semantica s) {
    final h = _hue(s);
    if (h == null) return Theme.of(c).colorScheme.outline;
    return HSLColor.fromAHSL(1, h, 0.66, _oscuro(c) ? 0.62 : 0.44).toColor();
  }
}
