import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Tema del modulo de Cheques.
///
/// **Es una copia del patron de `GarantiasTema` a proposito**, no una
/// importacion: ese archivo es de otro modulo y cualquier ajuste alla (un tono,
/// un tamano) se colaria aqui sin que nadie lo mirara. Los nombres cambian
/// (`SemanticaCheque`, `cifraCheque`) para que una pantalla que importe los dos
/// temas no choque.
///
/// Igual que en Garantias, el modulo se envuelve en su propio [Theme] y el resto
/// de la app queda intacto. Cambia dos cosas y nada mas —colores de marca, modo
/// oscuro y semilla siguen saliendo del tema de la app—:
///
/// - **Tipografia.** Plus Jakarta Sans en la interfaz y **JetBrains Mono para
///   importes, numeros de cheque y fechas** ([ChequesCifras.cifraCheque]). Un
///   cheque es un documento con monto y plazo: en monoespaciada las columnas de
///   cifras alinean por construccion y el 0 lleva barra, asi no se confunde con
///   la O al leer un numero de cheque.
///
/// - **Colores de estado** ([ChequesColores]). Lo que dice «atrasado», «cobra
///   hoy» o «cerrado» no puede cambiar de color segun la semilla que eligio cada
///   usuario: con la semilla verde el terciario sale celeste y una alerta se
///   leia como informacion. Aca el significado sale de tonos HSL fijos.
class ChequesTema {
  const ChequesTema._();

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
///
/// Los dialogos cuelgan del Navigator raiz: lo que se abre desde el `State` de
/// la pantalla (cuyo contexto esta **por encima** de este envoltorio) no hereda
/// la tipografia. Por eso `abrirPanelCheque` lo vuelve a poner.
class ChequesScope extends StatelessWidget {
  const ChequesScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: ChequesTema.temaModulo(context), child: child);
}

/// Estilo de cifras del modulo: importes, numeros de cheque y fechas.
extension ChequesCifras on BuildContext {
  /// JetBrains Mono. [tam] por defecto 12.5: la monoespaciada se ve mas grande
  /// que la proporcional al mismo tamano y compite con el texto si no se baja.
  TextStyle cifraCheque({bool fuerte = false, Color? color, double tam = 12.5}) =>
      TextStyle(
        fontFamily: ChequesTema.fuenteCifras,
        fontSize: tam,
        fontWeight: fuerte ? Peso.dato : FontWeight.w400,
        color: color ?? Theme.of(this).colorScheme.onSurface,
        height: 1.2,
      );
}

/// Los significados que se pintan en el modulo.
///
/// - exito: lo que termino bien (cheque cerrado, cierre por cobro).
/// - aviso: lo que pide atencion hoy (pendiente, cobra hoy, en cobranza).
/// - peligro: lo que ya paso de fecha o salio mal (atrasado, devuelto).
/// - info: lo que informa sin urgir (por cobrar pronto, recibido, respaldo).
/// - neutro: lo comun, sin enfasis (del `ColorScheme`).
enum SemanticaCheque { exito, aviso, peligro, info, neutro }

/// Colores de estado del modulo, derivados por HSL de tonos fijos (como
/// `GarantiasColores`): el matiz es el del significado y la luminosidad se ajusta
/// al modo claro u oscuro para mantener el contraste. La prueba de contraste
/// del modulo lo comprueba con las nueve semillas, en claro y en oscuro.
///
/// Cada semantica tiene tres tonos suaves y dos llenos:
///
/// - [fondo] y [texto]: la pastilla suave. Texto sobre fondo, 4,5:1 como minimo.
/// - [pleno]: franjas, puntos e iconos sueltos sobre la superficie, 3:1.
/// - [fondoFuerte] y [textoFuerte]: la pastilla llena, para lo urgente
///   (atrasado, cobra hoy). 4,5:1 como minimo.
class ChequesColores {
  const ChequesColores._();

  static bool _oscuro(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static double? _matiz(SemanticaCheque s) => switch (s) {
    SemanticaCheque.exito => 158,
    SemanticaCheque.aviso => 36,
    SemanticaCheque.peligro => 6,
    SemanticaCheque.info => 214,
    SemanticaCheque.neutro => null,
  };

  /// Contraste WCAG entre dos colores opacos.
  static double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final alto = la > lb ? la : lb;
    final bajo = la > lb ? lb : la;
    return (alto + 0.05) / (bajo + 0.05);
  }

  /// Oscurece (claro) o aclara (oscuro) [matiz] hasta que [minimo] se cumpla
  /// contra [contra]. Termina siempre: los extremos son negro y blanco.
  static Color _ajustar({
    required double matiz,
    required double saturacion,
    required double inicio,
    required Color contra,
    required double minimo,
    required bool oscurecer,
  }) {
    var l = inicio;
    while (true) {
      final color = HSLColor.fromAHSL(1, matiz, saturacion, l).toColor();
      if (contraste(color, contra) >= minimo || l <= 0.04 || l >= 0.96) {
        return color;
      }
      l += oscurecer ? -0.01 : 0.01;
    }
  }

  /// Fondo suave de pastillas y recuadros.
  static Color fondo(BuildContext c, SemanticaCheque s) {
    final h = _matiz(s);
    if (h == null) return Theme.of(c).colorScheme.surfaceContainerHighest;
    return HSLColor.fromAHSL(1, h, 0.62, _oscuro(c) ? 0.20 : 0.92).toColor();
  }

  /// Texto e iconos sobre [fondo].
  static Color texto(BuildContext c, SemanticaCheque s) {
    final h = _matiz(s);
    if (h == null) return Theme.of(c).colorScheme.onSurfaceVariant;
    // 0,25 y no 0,28 (el de Garantias): el verde azulado es el mas luminoso de
    // los cuatro y con 0,28 quedaba a 4,1:1 sobre una fila bajo el mouse.
    return HSLColor.fromAHSL(1, h, 0.70, _oscuro(c) ? 0.82 : 0.25).toColor();
  }

  /// Tono pleno: franjas de fila, puntos, bordes e iconos sobre la superficie.
  /// Se ajusta para que se distinga de ella (3:1) en cualquier semilla.
  static Color pleno(BuildContext c, SemanticaCheque s) {
    final cs = Theme.of(c).colorScheme;
    final h = _matiz(s);
    if (h == null) return cs.outline;
    final oscuro = _oscuro(c);
    return _ajustar(
      matiz: h,
      saturacion: 0.66,
      inicio: oscuro ? 0.58 : 0.50,
      contra: cs.surface,
      minimo: 3.2,
      oscurecer: !oscuro,
    );
  }

  /// Fondo de la pastilla llena. Con [textoFuerte] da 4,5:1 como minimo.
  static Color fondoFuerte(BuildContext c, SemanticaCheque s) {
    final h = _matiz(s);
    if (h == null) return Theme.of(c).colorScheme.onSurfaceVariant;
    final oscuro = _oscuro(c);
    return _ajustar(
      matiz: h,
      saturacion: 0.72,
      inicio: oscuro ? 0.60 : 0.46,
      contra: textoFuerte(c, s),
      minimo: 4.8,
      oscurecer: !oscuro,
    );
  }

  /// Texto sobre [fondoFuerte]: casi blanco en claro, casi negro en oscuro.
  static Color textoFuerte(BuildContext c, SemanticaCheque s) {
    final h = _matiz(s);
    if (h == null) return Theme.of(c).colorScheme.surface;
    return HSLColor.fromAHSL(1, h, 0.30, _oscuro(c) ? 0.08 : 0.98).toColor();
  }
}
