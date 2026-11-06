/// Listado del módulo Horas Extras: tabla en el ancho (de lado si no entra),
/// tarjetas en el angosto (con scroll propio o dentro del de la pantalla), la
/// paginación del servidor y los filtros compactos.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_haptica.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_pagina.dart';

/// Ancho mínimo por columna cuando la pantalla no fija el de la tabla.
const double _anchoPorColumna = 96;

/// Tabla solo si la lista tiene el ancho mínimo de SU tabla (y al menos
/// [hexAnchoTabla]); por debajo, tarjetas. La usan el listado y la pantalla
/// que arma su estructura, para decidir con la misma regla.
bool usaTablaHex(double anchoLista, double? anchoMinimoTabla) =>
    anchoLista >= math.max(hexAnchoTabla, anchoMinimoTabla ?? 0);

/// Medidas de la tabla del listado: las usan `_TablaHex` y [altoTablaHex].
const double _altoEncabezadoTabla = 48;
const double _altoMinimoFila = 52;

/// Al estimar un alto: cada fila con holgura (celdas de dos líneas), lo que
/// ocupa el paginador y el mínimo de la caja (para el vacío o la espera).
const double _altoFilaEstimado = _altoMinimoFila + Esp.m;
const double _altoPaginador = 64;
const double _altoMinimoCaja = 280;

/// Alto de la caja de una tabla corta dentro del desplazamiento de la
/// pantalla: lo que piden sus [filas] (a [porFila]), entre el mínimo de la
/// caja y [maximo]; si no entran, la tabla se desplaza dentro.
double altoTablaHex(
  int filas, {
  required double maximo,
  bool conPaginador = false,
  double porFila = _altoFilaEstimado,
}) {
  final pedido =
      _altoEncabezadoTabla +
      1 +
      filas * porFila +
      (conPaginador ? _altoPaginador : 0) +
      Esp.s;
  return math.min(maximo, math.max(_altoMinimoCaja, pedido));
}

/// Un listado corto dentro del scroll de la pantalla: con [tabla], en una
/// caja de [altoTablaHex]; si no, [lista] tal cual (tarjetas sin caja).
/// [porFila]: alto de una fila cuando sus celdas son más altas que lo usual.
Widget cajaTablaHex({
  required bool tabla,
  required int filas,
  required double maximo,
  required Widget lista,
  bool conPaginador = false,
  double? porFila,
}) {
  if (!tabla) return lista;
  return SizedBox(
    height: altoTablaHex(
      filas,
      maximo: maximo,
      conPaginador: conPaginador,
      porFila: porFila ?? _altoFilaEstimado,
    ),
    child: lista,
  );
}

/// Cuántos grupos tiene una lista agrupada por [clave]: filas seguidas con
/// la misma clave forman uno (cada uno lleva su cabecera).
int gruposHex<T>(List<T> filas, Object? Function(T) clave) {
  var n = 0;
  for (var i = 0; i < filas.length; i++) {
    if (i == 0 || clave(filas[i]) != clave(filas[i - 1])) n++;
  }
  return n;
}

/// Para `ListadoHex.cabeceraAntesDe`: [cabecera] antes de cada fila donde
/// cambia [clave] (y antes de la primera).
Widget? Function(int i) cabeceraPorGrupoHex<T>(
  List<T> filas,
  Object? Function(T) clave,
  Widget Function(T) cabecera,
) =>
    (i) =>
        i == 0 || clave(filas[i]) != clave(filas[i - 1])
            ? cabecera(filas[i])
            : null;

/// Listado con paginación del servidor ([total] filas de a [tamano]). Con
/// tabla ([usaTablaHex]): filtros a la vista, tabla y paginador. Si no:
/// filtros plegados, tarjetas y paginador si hay más de una página.
class ListadoHex<T> extends StatelessWidget {
  const ListadoHex({
    super.key,
    required this.filas,
    required this.columnas,
    required this.tarjeta,
    this.filtros,
    this.pagina = 1,
    this.total = 0,
    this.tamano = 20,
    this.alCambiarPagina,
    this.vacio,
    this.alTocarFila,
    this.anchoMinimoTabla,
    this.desplazamientoExterno = false,
    this.cabeceraAntesDe,
  });

  final List<T> filas;
  final List<BosqueColumn<T>> columnas;
  final Widget Function(T fila) tarjeta;
  final Widget? filtros;
  final int pagina;
  final int total;
  final int tamano;

  /// Sin él no hay paginador: no se dibujan botones que no hacen nada.
  final ValueChanged<int>? alCambiarPagina;
  final Widget? vacio;

  /// Abrir una fila de la tabla (en el teléfono, cada tarjeta trae el suyo).
  final ValueChanged<T>? alTocarFila;

  /// Por debajo de este ancho hay tarjetas. Sin él, la tabla sale desde
  /// [hexAnchoTabla] y, si no le alcanzan 96 px por columna, se desplaza de
  /// lado (red de seguridad).
  final double? anchoMinimoTabla;

  /// Solo con tarjetas: filtros, tarjetas y paginador sin scroll propio, para
  /// ir dentro del de la pantalla (una página trae hasta 100 filas). Con tabla
  /// no cambia: la tabla sigue necesitando un alto acotado.
  final bool desplazamientoExterno;

  /// Una cabecera a todo el ancho antes de la fila `i` (nula: ninguna), para
  /// agrupar filas seguidas; en las tarjetas va sobre la tarjeta.
  final Widget? Function(int i)? cabeceraAntesDe;

  int get _paginas => math.max(1, (total / math.max(1, tamano)).ceil());

  /// La tarjeta de la fila [i] con su cabecera encima, si la tiene.
  Widget _tarjetaDe(int i) {
    final hijo = tarjeta(filas[i]);
    final cabecera = cabeceraAntesDe?.call(i);
    if (cabecera == null) return hijo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [cabecera, hijo],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final paginas = _paginas;
      final actual = pagina.clamp(1, paginas);
      final primera = filas.isEmpty ? 0 : (actual - 1) * tamano + 1;
      final cambiar = alCambiarPagina;
      final paginador =
          cambiar == null
              ? null
              : BosquePaginator(
                currentPage: actual,
                totalPages: paginas,
                firstRow: primera,
                lastRow: filas.isEmpty ? 0 : primera + filas.length - 1,
                onPageChanged: cambiar,
              );
      final sinFilas =
          vacio ??
          const MensajeVacio(
            icono: Icons.inbox_outlined,
            titulo: 'No hay registros',
            detalle: 'Cambia los filtros o el rango de fechas.',
          );
      // La clave por página arma una lista nueva: vuelve al inicio.
      final clave = ValueKey<int>(actual);

      if (usaTablaHex(c.maxWidth, anchoMinimoTabla)) {
        final minimo = anchoMinimoTabla ?? columnas.length * _anchoPorColumna;
        final tabla = _TablaHex<T>(
          clave: clave,
          filas: filas,
          columnas: columnas,
          vacio: sinFilas,
          alTocarFila: alTocarFila,
          cabeceraAntesDe: cabeceraAntesDe,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (filtros != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.m),
                child: filtros,
              ),
            Expanded(
              child:
                  c.maxWidth >= minimo
                      ? tabla
                      : _DesplazamientoLateralHex(
                        ancho: minimo,
                        sangria: SangriaHex.de(context),
                        child: tabla,
                      ),
            ),
            if (paginador != null) paginador,
          ],
        );
      }
      final plegables =
          filtros == null
              ? null
              : Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune, size: 20),
                  title: const Text('Filtros'),
                  childrenPadding: const EdgeInsets.only(bottom: Esp.s),
                  expandedAlignment: Alignment.centerLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [filtros!],
                ),
              );
      if (desplazamientoExterno) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plegables != null) plegables,
            if (filas.isEmpty)
              SizedBox(height: hexAltoEstado, child: sinFilas)
            else
              Padding(
                padding: const EdgeInsets.only(top: Esp.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < filas.length; i++) _tarjetaDe(i),
                  ],
                ),
              ),
            if (paginas > 1 && paginador != null) paginador,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plegables != null) plegables,
          Expanded(
            child:
                filas.isEmpty
                    ? sinFilas
                    : _ListaConBarraHex(
                      key: clave,
                      cantidad: filas.length,
                      item: (_, i) => _tarjetaDe(i),
                      // Sin paginador abajo, la última tarjeta no queda bajo
                      // la barra de navegación del sistema.
                      relleno: EdgeInsets.only(
                        top: Esp.s,
                        bottom:
                            Esp.s +
                            (paginas > 1 && cambiar != null
                                ? 0
                                : MediaQuery.viewPaddingOf(context).bottom),
                      ),
                    ),
          ),
          if (paginas > 1 && paginador != null) paginador,
        ],
      );
    },
  );
}

/// La tabla conserva [ancho] y se desplaza de lado con una barra visible. El
/// borde que sigue se desvanece, y con [sangria] llega hasta el borde de la
/// pantalla en lugar de cortarse en el relleno de la página.
class _DesplazamientoLateralHex extends StatefulWidget {
  const _DesplazamientoLateralHex({
    required this.ancho,
    required this.child,
    this.sangria = 0,
  });

  final double ancho;
  final Widget child;
  final double sangria;

  @override
  State<_DesplazamientoLateralHex> createState() =>
      _DesplazamientoLateralHexState();
}

class _DesplazamientoLateralHexState extends State<_DesplazamientoLateralHex> {
  /// Lo que dura el desvanecido en cada borde.
  static const double _anchoDesvanecido = 32;

  final ScrollController _lateral = ScrollController();

  @override
  void dispose() {
    _lateral.dispose();
    super.dispose();
  }

  /// Hay tabla escondida a la izquierda (ya se desplazó).
  bool get _hayAntes => _lateral.hasClients && _lateral.offset > 1;

  /// Hay tabla escondida a la derecha; antes del primer cuadro se da por hecho
  /// (esta pieza solo existe cuando la tabla no entra).
  bool get _hayDespues =>
      !_lateral.hasClients ||
      !_lateral.position.hasContentDimensions ||
      _lateral.offset < _lateral.position.maxScrollExtent - 1;

  Shader _desvanecido(Rect r, {required bool antes, required bool despues}) {
    const blanco = Color(0xFFFFFFFF);
    const nada = Color(0x00FFFFFF);
    final f = math.min(_anchoDesvanecido / math.max(r.width, 1), 0.2);
    return LinearGradient(
      colors: [antes ? nada : blanco, blanco, blanco, despues ? nada : blanco],
      stops: [0, f, 1 - f, 1],
    ).createShader(r);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final margen = widget.sangria;
    final barra = ScrollbarTheme(
      data: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(10),
        radius: const Radius.circular(5),
        thumbColor: WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.6)),
        trackColor: WidgetStatePropertyAll(
          cs.outlineVariant.withValues(alpha: 0.5),
        ),
        trackVisibility: const WidgetStatePropertyAll(true),
      ),
      child: Scrollbar(
        controller: _lateral,
        thumbVisibility: true,
        child: ListenableBuilder(
          listenable: _lateral,
          builder:
              (context, hijo) => ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback:
                    (r) =>
                        _desvanecido(r, antes: _hayAntes, despues: _hayDespues),
                child: hijo,
              ),
          child: SingleChildScrollView(
            controller: _lateral,
            scrollDirection: Axis.horizontal,
            // Un margen bajo la tabla: la barra va en su propia franja.
            child: Padding(
              padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.l),
              child: SizedBox(width: widget.ancho, child: widget.child),
            ),
          ),
        ),
      ),
    );
    if (margen <= 0) return barra;
    // Se ensancha sobre el relleno de la página: los bordes de la tabla pasan
    // bajo él y salen por el borde de la pantalla.
    return LayoutBuilder(
      builder:
          (context, c) => OverflowBox(
            minWidth: c.maxWidth + 2 * margen,
            maxWidth: c.maxWidth + 2 * margen,
            child: barra,
          ),
    );
  }
}

/// Tabla con los colores del tema: borde sobre la página, encabezado en una
/// superficie más alta y filas alternadas que se pueden tocar.
class _TablaHex<T> extends StatelessWidget {
  const _TablaHex({
    required this.clave,
    required this.filas,
    required this.columnas,
    required this.vacio,
    this.alTocarFila,
    this.cabeceraAntesDe,
  });

  /// Cambia con la página: el cuerpo vuelve arriba.
  final Key clave;
  final List<T> filas;
  final List<BosqueColumn<T>> columnas;
  final Widget vacio;
  final ValueChanged<T>? alTocarFila;
  final Widget? Function(int i)? cabeceraAntesDe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget celda(BosqueColumn<T> c, Widget hijo) => Expanded(
      flex: c.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s),
        child: Align(alignment: c.alignment, child: hijo),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Esquina.media - 1),
        child: Column(
          children: [
            Container(
              color: cs.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(
                horizontal: Esp.m,
                vertical: Esp.s,
              ),
              constraints: const BoxConstraints(
                minHeight: _altoEncabezadoTabla,
              ),
              child: Row(
                children: [
                  for (final c in columnas)
                    celda(
                      c,
                      Text(
                        c.label,
                        style: t.labelLarge?.copyWith(
                          fontWeight: Peso.titulo,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            Expanded(
              child:
                  filas.isEmpty
                      ? vacio
                      : _ListaConBarraHex(
                        key: clave,
                        cantidad: filas.length,
                        separador:
                            (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: cs.outlineVariant,
                            ),
                        item: (context, i) {
                          final f = filas[i];
                          final fila = Material(
                            color:
                                i.isOdd
                                    ? cs.surfaceContainerLow
                                    : cs.surfaceContainerLowest,
                            child: InkWell(
                              onTap:
                                  alTocarFila == null
                                      ? null
                                      : () => alTocarFila!(f),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: _altoMinimoFila,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Esp.m,
                                  vertical: Esp.s,
                                ),
                                child: Row(
                                  children: [
                                    for (final c in columnas)
                                      celda(c, c.cellBuilder(f)),
                                  ],
                                ),
                              ),
                            ),
                          );
                          final cabecera = cabeceraAntesDe?.call(i);
                          if (cabecera == null) return fila;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              cabecera,
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: cs.outlineVariant,
                              ),
                              fila,
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista con barra de desplazamiento y su propio controlador: no comparte el
/// controlador primario con otras listas de la misma pantalla.
class _ListaConBarraHex extends StatefulWidget {
  const _ListaConBarraHex({
    super.key,
    required this.cantidad,
    required this.item,
    this.separador,
    this.relleno,
  });

  final int cantidad;
  final IndexedWidgetBuilder item;
  final IndexedWidgetBuilder? separador;
  final EdgeInsets? relleno;

  @override
  State<_ListaConBarraHex> createState() => _ListaConBarraHexState();
}

class _ListaConBarraHexState extends State<_ListaConBarraHex> {
  final ScrollController _control = ScrollController();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _control,
    child: ListView.separated(
      controller: _control,
      padding: widget.relleno,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: widget.cantidad,
      itemBuilder: widget.item,
      separatorBuilder: widget.separador ?? (_, __) => const SizedBox.shrink(),
    ),
  );
}

/// Un filtro de opciones fijas, compacto como los de Tickets.
class MenuFiltroHex extends StatelessWidget {
  const MenuFiltroHex({
    super.key,
    required this.valor,
    required this.opciones,
    required this.alElegir,
  });

  final String? valor;
  final Map<String?, String> opciones;
  final ValueChanged<String?> alElegir;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<String?>(
      value: valor,
      borderRadius: BorderRadius.circular(Esquina.chica),
      // El campo que se escribía no vuelve a abrir el teclado al cerrar.
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      items: [
        for (final MapEntry(key: v, value: texto) in opciones.entries)
          DropdownMenuItem<String?>(value: v, child: Text(texto)),
      ],
      onChanged: (v) {
        HapticaHex.seleccion();
        alElegir(v);
      },
    ),
  );
}

/// Ficha del rango de fechas de un filtro (jornadas, por defecto): abre el
/// selector y se quita con su «x» (nulo = todas). [explicacion] dice qué se
/// filtra; [titulo], el del selector.
class FiltroRangoHex extends StatelessWidget {
  const FiltroRangoHex({
    super.key,
    required this.desde,
    required this.hasta,
    required this.explicacion,
    required this.alCambiar,
    this.titulo = 'Jornadas a mostrar',
  });

  final DateTime? desde;
  final DateTime? hasta;
  final String explicacion;
  final void Function(DateTime? desde, DateTime? hasta) alCambiar;
  final String titulo;

  Future<void> _elegir(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final r = await pedirRangoDeFechas(
      context,
      titulo: titulo,
      explicacion: explicacion,
      desde: desde,
      hasta: hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.check,
    );
    if (r != null && context.mounted) alCambiar(r.desde, r.hasta);
  }

  @override
  Widget build(BuildContext context) => InputChip(
    avatar: const Icon(Icons.date_range_outlined, size: 18),
    label: Text(
      desde == null
          ? 'Todas las fechas'
          : '${fechaHex(desde)} – ${fechaHex(hasta)}',
    ),
    onPressed: () => _elegir(context),
    onDeleted: desde == null ? null : () => alCambiar(null, null),
    deleteButtonTooltipMessage: 'Quitar el rango',
  );
}
