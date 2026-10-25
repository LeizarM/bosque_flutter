/// Las piezas visuales del bingo: el bolillo (con su versión grande del en
/// vivo), el tablero agrupado por letra, la figura con su editor y el cartón.
/// Todo el color sale del `ColorScheme` que eligió el usuario.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MÁSCARA DE LA FIGURA (0/1 por casilla, fila por fila)
// ═══════════════════════════════════════════════════════════════════════════

/// Índice de la casilla central, la del comodín.
int ttkCentro(int filas, int columnas) =>
    (filas ~/ 2) * columnas + columnas ~/ 2;

/// Si la casilla [i] es el comodín del cartón.
bool ttkEsComodin(int i, int filas, int columnas, bool conComodin) =>
    conComodin &&
    filas.isOdd &&
    columnas.isOdd &&
    i == ttkCentro(filas, columnas);

/// Ajusta la máscara a [n] casillas (rellena con 0 o recorta).
String ttkMascara(String? mascara, int n) {
  final limpia = (mascara ?? '').replaceAll(RegExp('[^01]'), '');
  if (limpia.length >= n) return limpia.substring(0, n);
  return limpia.padRight(n, '0');
}

/// Cambia la casilla [i] de 0 a 1 o al revés.
String ttkAlternar(String mascara, int i) {
  if (i < 0 || i >= mascara.length) return mascara;
  final nuevo = mascara[i] == '1' ? '0' : '1';
  return mascara.replaceRange(i, i + 1, nuevo);
}

/// Casillas de la figura sin contar el comodín (la regla que valida el SP).
int ttkCasillasUtiles(
  String mascara,
  int filas,
  int columnas,
  bool conComodin,
) {
  var n = 0;
  for (var i = 0; i < mascara.length; i++) {
    if (mascara[i] == '1' && !ttkEsComodin(i, filas, columnas, conComodin)) n++;
  }
  return n;
}

enum FormaRapidaTtk { llena, vacia, invertir, marco, equis }

String ttkFormaRapida(
  FormaRapidaTtk forma,
  String actual,
  int filas,
  int columnas,
) {
  final n = filas * columnas;
  final b = StringBuffer();
  for (var i = 0; i < n; i++) {
    final f = i ~/ columnas;
    final c = i % columnas;
    final marcar = switch (forma) {
      FormaRapidaTtk.llena => true,
      FormaRapidaTtk.vacia => false,
      FormaRapidaTtk.invertir => i < actual.length && actual[i] != '1',
      FormaRapidaTtk.marco =>
        f == 0 || c == 0 || f == filas - 1 || c == columnas - 1,
      FormaRapidaTtk.equis =>
        filas == columnas ? (f == c || f + c == columnas - 1) : f == c,
    };
    b.write(marcar ? '1' : '0');
  }
  return b.toString();
}

/// Letra de la columna [c] o vacío si el bingo no usa letras.
String ttkLetra(String? letras, int c) =>
    letras != null && c >= 0 && c < letras.length ? letras[c] : '';

// ═══════════════════════════════════════════════════════════════════════════
// BOLILLO
// ═══════════════════════════════════════════════════════════════════════════

enum EstadoBolilloTtk { libre, marcado, ultimo }

/// Un bolillo del tablero. Libre: contorno; marcado: lleno; el último lleva
/// un anillo para ubicarlo de un vistazo.
class BolilloTtk extends StatelessWidget {
  const BolilloTtk({
    super.key,
    required this.numero,
    this.estado = EstadoBolilloTtk.libre,
    this.diametro = 40,
    this.alTocar,
    this.pendiente = false,
    this.etiqueta,
    this.lampara = false,
  });

  final int numero;
  final EstadoBolilloTtk estado;
  final double diametro;
  final VoidCallback? alTocar;
  final bool pendiente;
  final String? etiqueta;

  /// Celda cuadrada que se enciende, como el tablero luminoso de un salón.
  final bool lampara;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra, borde) = switch (estado) {
      EstadoBolilloTtk.libre when lampara => (
        cs.surfaceContainerHigh,
        cs.onSurfaceVariant,
        cs.surfaceContainerHigh,
      ),
      EstadoBolilloTtk.libre => (
        cs.surface,
        cs.onSurfaceVariant,
        cs.outlineVariant,
      ),
      EstadoBolilloTtk.marcado => (cs.primary, cs.onPrimary, cs.primary),
      EstadoBolilloTtk.ultimo => (cs.tertiary, cs.onTertiary, cs.tertiary),
    };
    // El último lleva un anillo por dentro del mismo tamaño: la fila no salta.
    final anillo = estado == EstadoBolilloTtk.ultimo;
    final interior = anillo ? diametro - (lampara ? 10 : 8) : diametro;
    final radio = BorderRadius.circular(diametro * 0.16);
    final sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bola = AnimatedContainer(
      duration:
          sinMovimiento ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      width: interior,
      height: interior,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        shape: lampara ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: lampara ? radio : null,
        border: Border.all(
          color: borde,
          width: estado == EstadoBolilloTtk.libre && !lampara ? 1 : 0,
        ),
      ),
      padding: EdgeInsets.all(interior * (lampara ? 0.1 : 0.14)),
      child:
          pendiente
              ? SizedBox(
                width: interior * 0.4,
                height: interior * 0.4,
                child: CircularProgressIndicator(strokeWidth: 2, color: letra),
              )
              : FittedBox(
                child: Text(
                  '$numero',
                  style: TextStyle(
                    fontFamily: ttkFuenteNumeros,
                    fontWeight:
                        estado == EstadoBolilloTtk.libre
                            ? Peso.normal
                            : Peso.dato,
                    fontFeatures: cifrasTabulares,
                    color: letra,
                    fontSize: interior * (lampara ? 0.5 : 0.42),
                    height: 1,
                  ),
                ),
              ),
    );
    final conAnillo =
        anillo
            ? Container(
              width: diametro,
              height: diametro,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: lampara ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: lampara ? radio : null,
                border: Border.all(color: cs.tertiary, width: lampara ? 3 : 2),
              ),
              child: bola,
            )
            : bola;
    final marcado = estado != EstadoBolilloTtk.libre;
    return Semantics(
      button: alTocar != null,
      label: '${etiqueta ?? numero}${marcado ? ', salió' : ''}',
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder:
                  lampara
                      ? RoundedRectangleBorder(borderRadius: radio)
                      : const CircleBorder(),
              onTap: alTocar,
              child: conAnillo,
            ),
          ),
        ),
      ),
    );
  }
}

/// El bolillo del en vivo: bola del color principal con el disco claro al
/// centro, como los de la máquina. Entra con un leve rebote al cambiar.
class BolilloGrandeTtk extends StatelessWidget {
  const BolilloGrandeTtk({
    super.key,
    required this.numero,
    required this.letra,
    this.diametro = 220,
  });

  final int? numero;
  final String letra;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration:
          sinMovimiento ? Duration.zero : const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder:
          (hijo, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(a),
              child: hijo,
            ),
          ),
      child: _Bola(
        key: ValueKey(numero),
        numero: numero,
        letra: letra,
        diametro: diametro,
      ),
    );
  }
}

class _Bola extends StatelessWidget {
  const _Bola({
    super.key,
    required this.numero,
    required this.letra,
    required this.diametro,
  });

  final int? numero;
  final String letra;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disco = diametro * 0.62;
    return Semantics(
      liveRegion: true,
      label:
          numero == null
              ? 'Aún no salió ningún bolillo'
              : 'Último bolillo: $letra $numero',
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: numero == null ? cs.surfaceContainerHighest : cs.primary,
              ),
            ),
            Container(
              width: disco,
              height: disco,
              alignment: Alignment.center,
              padding: EdgeInsets.all(disco * 0.12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface,
                border: Border.all(
                  color:
                      numero == null
                          ? cs.outlineVariant
                          : cs.onPrimary.withValues(alpha: 0.4),
                  width: math.max(2, diametro * 0.018),
                ),
              ),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (letra.isNotEmpty)
                      Text(
                        letra,
                        style: TextStyle(
                          fontFamily: ttkFuenteNumeros,
                          fontWeight: Peso.dato,
                          color: cs.primary,
                          fontSize: disco * 0.22,
                          height: 1,
                        ),
                      ),
                    Text(
                      numero?.toString() ?? '—',
                      style: TextStyle(
                        fontFamily: ttkFuenteNumeros,
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                        color: cs.onSurface,
                        fontSize: disco * 0.46,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso público de que ya salió un ganador. Genérico: el texto es el
/// `mensaje` del SP y nunca lleva nombres.
class AvisoGanadorTtk extends StatelessWidget {
  const AvisoGanadorTtk({
    super.key,
    required this.mensaje,
    this.grande = false,
  });

  final String mensaje;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: grande ? Esp.xl : Esp.l,
            vertical: grande ? Esp.l : Esp.m,
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: grande ? 48 : 28,
                color: cs.onTertiaryContainer,
              ),
              SizedBox(width: grande ? Esp.l : Esp.m),
              Expanded(
                child: Text(
                  mensaje,
                  style: (grande ? t.headlineMedium : t.titleMedium)?.copyWith(
                    fontWeight: Peso.dato,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLERO
// ═══════════════════════════════════════════════════════════════════════════

/// Cómo se reparte el tablero: diámetro del bolillo, cuántos van por línea y
/// el ancho de la columna de letras.
class MedidaTableroTtk {
  const MedidaTableroTtk(this.diametro, this.porLinea, this.rotulo);

  final double diametro;
  final int porLinea;
  final double rotulo;
}

/// El diámetro más grande con el que el tablero entra en [ancho] × [alto]:
/// prueba cuántos bolillos van por línea y se queda con el que deja la celda
/// mayor. Sin [alto] (dentro de un scroll) manda solo el ancho.
MedidaTableroTtk ttkMedidaTablero({
  required double ancho,
  double? alto,
  required int grupos,
  required int porGrupo,
  double hueco = 6,
  double minimo = 28,
  double maximo = 160,
}) {
  final rotulo = (ancho * 0.045).clamp(18.0, 64.0).toDouble();
  final disponible = ancho - rotulo - Esp.s;
  final g = math.max(grupos, 1);
  final n = math.max(porGrupo, 1);
  MedidaTableroTtk? mejor;
  for (var tope = n; tope >= 1; tope--) {
    // Líneas parejas: 15 en tres líneas van 5 + 5 + 5, no 7 + 7 + 1.
    final k = (n / (n / tope).ceil()).ceil();
    final porAncho = (disponible - (k - 1) * hueco) / k;
    if (alto == null) {
      // Sin alto: la fila más larga que todavía respeta el mínimo.
      if (porAncho >= minimo || tope == 1) {
        return MedidaTableroTtk(
          porAncho.clamp(minimo, maximo).toDouble(),
          k,
          rotulo,
        );
      }
      continue;
    }
    final lineas = g * (n / k).ceil();
    final porAlto = (alto - (lineas - 1) * hueco - (g - 1) * hueco) / lineas;
    final d = math.min(math.min(porAncho, porAlto), maximo);
    if (mejor == null || d > mejor.diametro + 0.5) {
      mejor = MedidaTableroTtk(d, k, rotulo);
    }
  }
  return mejor ?? MedidaTableroTtk(minimo, n, rotulo);
}

/// Todos los bolillos, un grupo por letra. Con [llenar], el diámetro sale del
/// ancho y del alto disponibles para que el tablero ocupe toda el área; si ni
/// así entra con el tamaño mínimo, se desplaza en vertical.
class TableroBolillosTtk extends StatelessWidget {
  const TableroBolillosTtk({
    super.key,
    required this.tablero,
    this.ultimo,
    this.alTocar,
    this.pendientes = const {},
    this.llenar = false,
    this.minCelda = 28,
    this.maxCelda = 160,
    this.lampara = false,
  });

  final List<TtkBingoSorteoEntity> tablero;
  final int? ultimo;
  final ValueChanged<TtkBingoSorteoEntity>? alTocar;
  final Set<int> pendientes;
  final bool llenar;
  final double minCelda;
  final double maxCelda;
  final bool lampara;

  @override
  Widget build(BuildContext context) {
    final grupos = <int, List<TtkBingoSorteoEntity>>{};
    for (final b in tablero) {
      (grupos[b.columna] ??= []).add(b);
    }
    final claves = grupos.keys.toList()..sort();
    final porGrupo = grupos.values.fold<int>(
      0,
      (m, g) => math.max(m, g.length),
    );
    const hueco = 6.0;

    return LayoutBuilder(
      builder: (context, c) {
        if (claves.isEmpty || !c.hasBoundedWidth) {
          return const SizedBox.shrink();
        }
        final conAlto = llenar && c.hasBoundedHeight;
        var m = ttkMedidaTablero(
          ancho: c.maxWidth,
          alto: conAlto ? c.maxHeight : null,
          grupos: claves.length,
          porGrupo: porGrupo,
          hueco: hueco,
          minimo: minCelda,
          maximo: maxCelda,
        );
        final desborda = conAlto && m.diametro < minCelda;
        if (desborda) {
          m = ttkMedidaTablero(
            ancho: c.maxWidth,
            grupos: claves.length,
            porGrupo: porGrupo,
            hueco: hueco,
            minimo: minCelda,
            maximo: maxCelda,
          );
        }
        final cuerpo = _cuerpo(context, grupos, claves, m, hueco);
        if (!conAlto) return cuerpo;
        if (desborda) return SingleChildScrollView(child: cuerpo);
        // El redondeo de la medida no debe dejar ni un píxel de desborde.
        return Center(child: FittedBox(fit: BoxFit.scaleDown, child: cuerpo));
      },
    );
  }

  Widget _cuerpo(
    BuildContext context,
    Map<int, List<TtkBingoSorteoEntity>> grupos,
    List<int> claves,
    MedidaTableroTtk m,
    double hueco,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var gi = 0; gi < claves.length; gi++)
          Padding(
            padding: EdgeInsets.only(top: gi == 0 ? 0 : hueco),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: m.rotulo,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        grupos[claves[gi]]!.first.letra.isEmpty
                            ? '${claves[gi] + 1}'
                            : grupos[claves[gi]]!.first.letra,
                        style: TextStyle(
                          fontFamily: ttkFuenteNumeros,
                          fontWeight: Peso.dato,
                          color: cs.primary,
                          fontSize: math.min(m.rotulo * 0.9, m.diametro * 0.62),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Esp.s),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (li, linea)
                        in _lineas(grupos[claves[gi]]!, m.porLinea).indexed)
                      Padding(
                        padding: EdgeInsets.only(top: li == 0 ? 0 : hueco),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < linea.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  right: i == linea.length - 1 ? 0 : hueco,
                                ),
                                child: _bolillo(linea[i], m.diametro),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Parte un grupo en líneas de [k] bolillos.
  List<List<TtkBingoSorteoEntity>> _lineas(
    List<TtkBingoSorteoEntity> grupo,
    int k,
  ) => [
    for (var i = 0; i < grupo.length; i += k)
      grupo.sublist(i, math.min(i + k, grupo.length)),
  ];

  Widget _bolillo(TtkBingoSorteoEntity b, double d) => BolilloTtk(
    key: ValueKey('ttk-bolillo-${b.nroBolillo}'),
    lampara: lampara,
    numero: b.nroBolillo,
    etiqueta: b.etiqueta,
    diametro: d,
    pendiente: pendientes.contains(b.nroBolillo),
    estado:
        b.nroBolillo == ultimo && b.marcado
            ? EstadoBolilloTtk.ultimo
            : b.marcado
            ? EstadoBolilloTtk.marcado
            : EstadoBolilloTtk.libre,
    alTocar:
        alTocar == null || pendientes.contains(b.nroBolillo)
            ? null
            : () {
              HapticFeedback.selectionClick();
              alTocar!(b);
            },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// FIGURA
// ═══════════════════════════════════════════════════════════════════════════

/// La figura de un juego dibujada en pequeño (solo lectura).
class FiguraTtk extends StatelessWidget {
  const FiguraTtk({
    super.key,
    required this.figura,
    required this.filas,
    required this.columnas,
    this.conComodin = false,
    this.celda = 12,
  });

  final String figura;
  final int filas;
  final int columnas;
  final bool conComodin;
  final double celda;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = ttkMascara(figura, filas * columnas);
    final hueco = math.max(1.0, celda * 0.12);
    return Semantics(
      label: 'Figura del juego',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var f = 0; f < filas; f++)
            Padding(
              padding: EdgeInsets.only(bottom: f == filas - 1 ? 0 : hueco),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < columnas; c++)
                    Builder(
                      builder: (_) {
                        final i = f * columnas + c;
                        final comodin = ttkEsComodin(
                          i,
                          filas,
                          columnas,
                          conComodin,
                        );
                        final enFigura = m[i] == '1';
                        return Container(
                          width: celda,
                          height: celda,
                          margin: EdgeInsets.only(
                            right: c == columnas - 1 ? 0 : hueco,
                          ),
                          decoration: BoxDecoration(
                            color:
                                enFigura
                                    ? (comodin ? cs.tertiary : cs.primary)
                                    : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(celda * 0.22),
                          ),
                          child:
                              comodin && celda >= 14
                                  ? Icon(
                                    Icons.star_rounded,
                                    size: celda * 0.7,
                                    color:
                                        enFigura
                                            ? cs.onTertiary
                                            : cs.onSurfaceVariant,
                                  )
                                  : null,
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Editor de la figura: se toca una casilla para marcarla o desmarcarla. El
/// centro se ve como comodín cuando el bingo lo usa.
class EditorFiguraTtk extends StatelessWidget {
  const EditorFiguraTtk({
    super.key,
    required this.mascara,
    required this.filas,
    required this.columnas,
    required this.alCambiar,
    this.conComodin = false,
    this.letras,
    this.habilitado = true,
  });

  final String mascara;
  final int filas;
  final int columnas;
  final bool conComodin;
  final String? letras;
  final bool habilitado;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = filas * columnas;
    final m = ttkMascara(mascara, n);
    final util = ttkCasillasUtiles(m, filas, columnas, conComodin);
    const hueco = 6.0;

    return LayoutBuilder(
      builder: (context, c) {
        final celda =
            ((math.min(c.maxWidth, 420) - (columnas - 1) * hueco) / columnas)
                .clamp(26.0, 64.0)
                .toDouble();
        final tieneLetras = (letras ?? '').isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tieneLetras)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var col = 0; col < columnas; col++)
                    Container(
                      width: celda,
                      margin: EdgeInsets.only(
                        right: col == columnas - 1 ? 0 : hueco,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ttkLetra(letras, col),
                        style: TextStyle(
                          fontFamily: ttkFuenteNumeros,
                          fontWeight: Peso.dato,
                          color: cs.primary,
                          fontSize: math.min(20, celda * 0.45),
                        ),
                      ),
                    ),
                ],
              ),
            if (tieneLetras) const SizedBox(height: Esp.xs),
            for (var f = 0; f < filas; f++)
              Padding(
                padding: const EdgeInsets.only(bottom: hueco),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var col = 0; col < columnas; col++)
                      _CasillaEditor(
                        key: ValueKey('ttk-figura-${f * columnas + col}'),
                        celda: celda,
                        margenDerecho: col == columnas - 1 ? 0 : hueco,
                        marcada: m[f * columnas + col] == '1',
                        comodin: ttkEsComodin(
                          f * columnas + col,
                          filas,
                          columnas,
                          conComodin,
                        ),
                        alTocar:
                            habilitado
                                ? () {
                                  HapticFeedback.selectionClick();
                                  alCambiar(ttkAlternar(m, f * columnas + col));
                                }
                                : null,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Esp.xs),
            Text(
              '$util casillas en la figura${conComodin ? ' (más el comodín si lo marcas)' : ''}',
              style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
            ),
            if (habilitado) ...[
              const SizedBox(height: Esp.s),
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: [
                  for (final (forma, texto, icono) in const [
                    (FormaRapidaTtk.llena, 'Cartón lleno', Icons.grid_on),
                    (FormaRapidaTtk.marco, 'Marco', Icons.crop_square),
                    (FormaRapidaTtk.equis, 'Equis', Icons.close),
                    (FormaRapidaTtk.invertir, 'Invertir', Icons.flip),
                    (FormaRapidaTtk.vacia, 'Vaciar', Icons.grid_off),
                  ])
                    ActionChip(
                      avatar: Icon(icono, size: 18),
                      label: Text(texto),
                      onPressed:
                          () => alCambiar(
                            ttkFormaRapida(forma, m, filas, columnas),
                          ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CasillaEditor extends StatelessWidget {
  const _CasillaEditor({
    super.key,
    required this.celda,
    required this.margenDerecho,
    required this.marcada,
    required this.comodin,
    required this.alTocar,
  });

  final double celda;
  final double margenDerecho;
  final bool marcada;
  final bool comodin;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo =
        marcada
            ? (comodin ? cs.tertiary : cs.primary)
            : cs.surfaceContainerHighest;
    final icono =
        marcada
            ? (comodin ? cs.onTertiary : cs.onPrimary)
            : cs.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.only(right: margenDerecho),
      child: Semantics(
        button: true,
        toggled: marcada,
        label: comodin ? 'Comodín' : 'Casilla',
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
          child: InkWell(
            borderRadius: BorderRadius.circular(Esquina.chica),
            onTap: alTocar,
            child: SizedBox(
              width: celda,
              height: celda,
              child:
                  comodin
                      ? Icon(
                        Icons.star_rounded,
                        color: icono,
                        size: celda * 0.55,
                      )
                      : marcada
                      ? Icon(
                        Icons.check_rounded,
                        color: icono,
                        size: celda * 0.5,
                      )
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Un juego de un cartón: letras arriba, números, el comodín con estrella,
/// la figura sombreada y el sello en lo que salió (encargado) o en lo que el
/// participante marcó a mano.
class CartonJuegoTtk extends StatelessWidget {
  const CartonJuegoTtk({
    super.key,
    required this.celdas,
    required this.filas,
    required this.columnas,
    this.letras,
    this.maxCelda = 52,
    this.marcas,
    this.alTocar,
  });

  final List<TtkBingoCeldaEntity> celdas;
  final int filas;
  final int columnas;
  final String? letras;
  final double maxCelda;

  /// Posiciones que el participante marcó a mano.
  final Set<int>? marcas;

  /// Con [alTocar], cada casilla con número se marca o desmarca al tocarla.
  final ValueChanged<int>? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final porPosicion = {for (final c in celdas) c.posicion: c};
    const hueco = 4.0;
    return LayoutBuilder(
      builder: (context, c) {
        final celda =
            ((c.maxWidth - (columnas - 1) * hueco) / columnas)
                .clamp(22.0, maxCelda)
                .toDouble();
        final tieneLetras = (letras ?? '').isNotEmpty;
        Widget fila(List<Widget> hijos) =>
            Row(mainAxisSize: MainAxisSize.min, children: hijos);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tieneLetras)
              fila([
                for (var col = 0; col < columnas; col++)
                  Container(
                    width: celda,
                    margin: EdgeInsets.only(
                      right: col == columnas - 1 ? 0 : hueco,
                      bottom: hueco,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(Esquina.chica / 2),
                    ),
                    child: Text(
                      ttkLetra(letras, col),
                      style: TextStyle(
                        fontFamily: ttkFuenteNumeros,
                        fontWeight: Peso.dato,
                        color: cs.onPrimary,
                        fontSize: math.min(18, celda * 0.42),
                      ),
                    ),
                  ),
              ]),
            for (var f = 0; f < filas; f++)
              Padding(
                padding: EdgeInsets.only(bottom: f == filas - 1 ? 0 : hueco),
                child: fila([
                  for (var col = 0; col < columnas; col++)
                    _CasillaCarton(
                      celda: celda,
                      margenDerecho: col == columnas - 1 ? 0 : hueco,
                      dato: porPosicion[f * columnas + col],
                      letra: ttkLetra(letras, col),
                      marcada: marcas?.contains(f * columnas + col) ?? false,
                      alTocar: alTocar,
                    ),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _CasillaCarton extends StatelessWidget {
  const _CasillaCarton({
    required this.celda,
    required this.margenDerecho,
    required this.dato,
    this.letra = '',
    this.marcada = false,
    this.alTocar,
  });

  final double celda;
  final double margenDerecho;
  final TtkBingoCeldaEntity? dato;
  final String letra;
  final bool marcada;
  final ValueChanged<int>? alTocar;

  @override
  Widget build(BuildContext context) {
    final d = dato;
    final sello = d != null && !d.esComodin && (d.marcado || marcada);
    final tocar = alTocar;
    if (tocar == null || d == null || d.esComodin) {
      return _dibujo(context, d, sello);
    }
    return Semantics(
      button: true,
      toggled: sello,
      label: '${letra.isEmpty ? '' : '$letra '}${d.numero}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(right: margenDerecho),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(Esquina.chica / 2),
            onTap: () {
              HapticFeedback.selectionClick();
              tocar(d.posicion);
            },
            child: _dibujo(context, d, sello, conMargen: false),
          ),
        ),
      ),
    );
  }

  Widget _dibujo(
    BuildContext context,
    TtkBingoCeldaEntity? d,
    bool sello, {
    bool conMargen = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final enFigura = d?.enFigura ?? false;
    return Container(
      width: celda,
      height: celda,
      margin: EdgeInsets.only(right: conMargen ? margenDerecho : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enFigura ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(Esquina.chica / 2),
        border: Border.all(color: enFigura ? cs.primary : cs.outlineVariant),
      ),
      child:
          d == null
              ? null
              : d.esComodin
              ? Icon(Icons.star_rounded, size: celda * 0.6, color: cs.tertiary)
              : Container(
                width: celda * 0.82,
                height: celda * 0.82,
                alignment: Alignment.center,
                decoration:
                    sello
                        ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                        )
                        : null,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      '${d.numero}',
                      style: TextStyle(
                        fontFamily: ttkFuenteNumeros,
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                        fontSize: celda * 0.42,
                        color:
                            sello
                                ? cs.onPrimary
                                : enFigura
                                ? cs.onPrimaryContainer
                                : cs.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}

/// Todos los juegos de un cartón, en columnas según el ancho disponible.
class CartonCompletoTtk extends StatelessWidget {
  const CartonCompletoTtk({super.key, required this.celdas, this.letras});

  final List<TtkBingoCeldaEntity> celdas;
  final String? letras;

  @override
  Widget build(BuildContext context) {
    if (celdas.isEmpty) return const SizedBox.shrink();
    final filas = celdas.map((c) => c.fila).reduce(math.max) + 1;
    final columnas = celdas.map((c) => c.columna).reduce(math.max) + 1;
    final juegos = <int, List<TtkBingoCeldaEntity>>{};
    for (final c in celdas) {
      (juegos[c.nroJuego] ??= []).add(c);
    }
    final orden = juegos.keys.toList()..sort();
    return LayoutBuilder(
      builder: (context, c) {
        final porFila = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 520 ? 2 : 1);
        final ancho = (c.maxWidth - (porFila - 1) * Esp.m) / porFila;
        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final j in orden)
              SizedBox(
                width: ancho,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Juego $j · ${juegos[j]!.first.nombreJuego}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tituloSeccion(),
                    ),
                    const SizedBox(height: Esp.xs),
                    CartonJuegoTtk(
                      celdas: juegos[j]!,
                      filas: filas,
                      columnas: columnas,
                      letras: letras,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
