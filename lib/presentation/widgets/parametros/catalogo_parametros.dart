/// Piezas comunes de las pantallas de parámetros (tipos de teléfono, niveles
/// jerárquicos, ubicaciones, funciones por módulo): cabecera con acciones,
/// estados de carga, listado con búsqueda y paginación, formulario y baja.
///
/// Siguen el molde de Bancos: tabla en escritorio y tarjetas en móvil según el
/// ancho del contenedor; los textos de éxito y error los redacta el SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Ancho del contenedor desde el cual el listado es una tabla.
const double anchoMinimoTablaCatalogo = 720;

/// Ancho mínimo de una tarjeta en móvil; decide cuántas caben por fila.
const double _anchoMinimoTarjeta = 320;

const double _anchoIconoAccion = 40;

// ═══════════════════════════════════════════════════════════════════════════
// DEFINICIÓN DEL LISTADO
// ═══════════════════════════════════════════════════════════════════════════

/// Una columna de la tabla. Con [ancho] es fija; sin él reparte el sobrante
/// según [flex].
class ColumnaCatalogo<T> {
  const ColumnaCatalogo({
    required this.titulo,
    required this.celda,
    this.ancho,
    this.flex = 1,
    this.alineacion = Alignment.centerLeft,
  });

  final String titulo;
  final Widget Function(BuildContext context, T item) celda;
  final double? ancho;
  final int flex;
  final Alignment alineacion;
}

/// Una acción por fila. Quien arma la lista ya filtró por permisos; [visible]
/// decide fila por fila (por ejemplo, solo la escala vigente se edita).
class AccionCatalogo<T> {
  const AccionCatalogo({
    required this.etiqueta,
    required this.icono,
    required this.alElegir,
    this.visible,
  });

  final String etiqueta;
  final IconData icono;
  final void Function(T item) alElegir;
  final bool Function(T item)? visible;

  bool aplicaA(T item) => visible?.call(item) ?? true;
}

// ═══════════════════════════════════════════════════════════════════════════
// COLOR CON SIGNIFICADO
// ═══════════════════════════════════════════════════════════════════════════

/// Familias de color que se distinguen con cualquiera de las nueve semillas
/// del tema (ver `colorDeEstado` en tokens_bosque): principal, terciaria y
/// neutra. `error` solo para lo que de verdad es un problema.
enum TonoDato { principal, terciario, neutro, error }

/// Fondo, texto y trazo de un [TonoDato] según el tema activo.
(Color fondo, Color texto, Color trazo) coloresDeTono(
  ColorScheme cs,
  TonoDato tono,
) => switch (tono) {
  TonoDato.principal => (cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
  TonoDato.terciario => (
    cs.tertiaryContainer,
    cs.onTertiaryContainer,
    cs.tertiary,
  ),
  TonoDato.neutro => (
    cs.surfaceContainerHighest,
    cs.onSurfaceVariant,
    cs.outline,
  ),
  TonoDato.error => (cs.errorContainer, cs.onErrorContainer, cs.error),
};

/// Una pastilla con ícono para un dato categórico (módulo, estado, uso).
class PildoraDato extends StatelessWidget {
  const PildoraDato(
    this.texto, {
    super.key,
    this.icono,
    this.tono = TonoDato.neutro,
  });

  final String texto;
  final IconData? icono;
  final TonoDato tono;

  @override
  Widget build(BuildContext context) {
    final (fondo, letra, _) = coloresDeTono(Theme.of(context).colorScheme, tono);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: letra),
            const SizedBox(width: Esp.xs),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: letra,
                fontWeight: Peso.titulo,
                fontFeatures: cifrasTabulares,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un indicador del resumen de la pantalla: cuántos hay, cuántos activos...
class DatoResumen {
  const DatoResumen(
    this.etiqueta,
    this.valor, {
    required this.icono,
    this.tono = TonoDato.principal,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final TonoDato tono;
}

/// Una barra del ranking del panel lateral (p. ej. asignaciones por función).
class BarraResumen {
  const BarraResumen(this.etiqueta, this.valor);

  final String etiqueta;
  final num valor;
}

/// Quita acentos y pasa a minúsculas para que «telefono» encuentre «TELÉFONO».
String normalizarBusqueda(String t) {
  const con = 'áàäâéèëêíìïîóòöôúùüûñ';
  const sin = 'aaaaeeeeiiiioooouuuun';
  final b = StringBuffer();
  for (final r in t.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = con.indexOf(c);
    b.write(i < 0 ? c : sin[i]);
  }
  return b.toString();
}

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA
// ═══════════════════════════════════════════════════════════════════════════

/// Esqueleto de una pantalla de parámetros: cabecera, barra de espera y el
/// cuerpo según el estado de [lectura]. El botón «Nuevo» se dibuja solo si el
/// usuario tiene [botonNuevo] en su ACL.
class PantallaCatalogo<T> extends StatelessWidget {
  const PantallaCatalogo({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.lectura,
    required this.onRecargar,
    required this.vacio,
    required this.contenido,
    this.ocupado = false,
    this.botonNuevo,
    this.etiquetaNuevo = 'Nuevo',
    this.onNuevo,
    this.encabezadoCuerpo,
    this.anchoMaximo = double.infinity,
    this.icono = Icons.tune,
    this.resumen,
    this.tituloRanking,
    this.ranking,
  });

  /// El ícono del módulo en la cabecera.
  final IconData icono;

  /// Indicadores calculados sobre la lista: en pantallas anchas van en el
  /// panel lateral; en las angostas, arriba del listado.
  final List<DatoResumen> Function(List<T> items)? resumen;

  /// Ranking con barras del panel lateral (solo en pantallas anchas).
  final String? tituloRanking;
  final List<BarraResumen> Function(List<T> items)? ranking;

  final String titulo;
  final String subtitulo;
  final AsyncValue<List<T>> lectura;
  final VoidCallback onRecargar;

  /// Lo que se ve cuando no hay ningún registro.
  final MensajeVacio vacio;
  final Widget Function(List<T> items) contenido;
  final bool ocupado;
  final String? botonNuevo;
  final String etiquetaNuevo;
  final VoidCallback? onNuevo;

  /// Algo fijo arriba del listado (un selector de país, una nota).
  final Widget? encabezadoCuerpo;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    final cargandoConDatos = lectura.isLoading && lectura.hasValue;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final chico = Aire.de(restricciones.maxWidth).esChico;
          final margen = chico ? Esp.m : Esp.xl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CabeceraCatalogo(
                titulo: titulo,
                subtitulo: subtitulo,
                icono: icono,
                chico: chico,
                onRecargar: onRecargar,
                botonNuevo: botonNuevo,
                etiquetaNuevo: etiquetaNuevo,
                onNuevo: onNuevo,
              ),
              SizedBox(
                height: 2,
                child:
                    (cargandoConDatos || ocupado)
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: anchoMaximo),
                      child: _distribucion(
                        restricciones.maxWidth - 2 * margen,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Listado con el resumen al costado (ancho) o arriba (angosto).
  Widget _distribucion(double ancho) {
    final items = lectura.valueOrNull;
    final hay = items != null && items.isNotEmpty;
    return DistribucionResumen(
      ancho: ancho,
      datos: hay ? resumen?.call(items) : null,
      tituloRanking: tituloRanking,
      barras: hay ? ranking?.call(items) : null,
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (encabezadoCuerpo != null) ...[
            encabezadoCuerpo!,
            const SizedBox(height: Esp.l),
          ],
          _cuerpo(),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (lectura.hasError && !lectura.isLoading) {
      return SizedBox(
        height: 320,
        child: MensajeError(error: lectura.error, onReintentar: onRecargar),
      );
    }
    final items = lectura.valueOrNull;
    // EsqueletoLista es un ListView: dentro del scroll necesita su alto exacto.
    if (items == null) {
      return const SizedBox(
        height: 6 * (56 + Esp.s) + 2 * Esp.m,
        child: EsqueletoLista(filas: 6, altoFila: 56),
      );
    }
    if (items.isEmpty) return SizedBox(height: 320, child: vacio);
    return contenido(items);
  }
}

class _CabeceraCatalogo extends StatelessWidget {
  const _CabeceraCatalogo({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.chico,
    required this.onRecargar,
    required this.botonNuevo,
    required this.etiquetaNuevo,
    required this.onNuevo,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool chico;
  final VoidCallback onRecargar;
  final String? botonNuevo;
  final String etiquetaNuevo;
  final VoidCallback? onNuevo;

  @override
  Widget build(BuildContext context) {
    final mosaico = MosaicoModulo(icono, chico: chico);

    // Sin nombre de botón (vistas que no tienen ACL), «Nuevo» lo ve quien
    // tiene la pantalla, como en el legacy.
    Widget? nuevo;
    if (onNuevo != null) {
      final boton =
            chico
                ? IconButton.filled(
                  onPressed: onNuevo,
                  icon: const Icon(Icons.add),
                  tooltip: etiquetaNuevo,
                )
                : Padding(
                  padding: const EdgeInsets.only(left: Esp.s),
                  child: FilledButton.icon(
                    onPressed: onNuevo,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(etiquetaNuevo),
                  ),
                );
      nuevo =
          botonNuevo == null
              ? boton
              : PermissionWidget(buttonName: botonNuevo!, child: boton);
    }

    return Container(
      width: double.infinity,
      decoration: decoracionCabeceraModulo(Theme.of(context).colorScheme),
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.l,
        chico ? Esp.s : Esp.xl,
        Esp.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          mosaico,
          SizedBox(width: chico ? Esp.m : Esp.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
                ),
                const SizedBox(height: Esp.xs),
                Text(subtitulo, style: context.apagado()),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          IconButton(
            onPressed: onRecargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          if (nuevo != null) nuevo,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMEN
// ═══════════════════════════════════════════════════════════════════════════

/// Desde este ancho útil el resumen va en un panel a la derecha.
const double anchoConPanelResumen = 1180;

/// El fondo de la cabecera de un módulo: un degradado tenue del color principal.
BoxDecoration decoracionCabeceraModulo(ColorScheme cs) => BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Color.alphaBlend(
        cs.primaryContainer.withValues(alpha: 0.35),
        cs.surfaceContainerLow,
      ),
      cs.surfaceContainerLow,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  border: Border(bottom: BorderSide(color: cs.outlineVariant)),
);

/// El ícono del módulo en su mosaico de color, al lado del título.
class MosaicoModulo extends StatelessWidget {
  const MosaicoModulo(this.icono, {super.key, this.chico = false});

  final IconData icono;
  final bool chico;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: chico ? 40 : 48,
      height: chico ? 40 : 48,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Icon(icono, color: cs.onPrimaryContainer, size: chico ? 22 : 26),
    );
  }
}

/// El listado con su resumen: al costado desde [anchoConPanelResumen] de
/// [ancho] útil, arriba (solo los indicadores) en pantallas más angostas.
class DistribucionResumen extends StatelessWidget {
  const DistribucionResumen({
    super.key,
    required this.ancho,
    required this.principal,
    this.datos,
    this.tituloRanking,
    this.barras,
  });

  final double ancho;
  final Widget principal;
  final List<DatoResumen>? datos;
  final String? tituloRanking;
  final List<BarraResumen>? barras;

  @override
  Widget build(BuildContext context) {
    if (ancho >= anchoConPanelResumen && (datos != null || barras != null)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: principal),
          const SizedBox(width: Esp.xl),
          SizedBox(
            width: 300,
            child: _PanelResumen(
              datos: datos ?? const [],
              tituloRanking: tituloRanking,
              barras: barras ?? const [],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (datos != null && datos!.isNotEmpty) ...[
          _TilesResumen(datos: datos!),
          const SizedBox(height: Esp.l),
        ],
        principal,
      ],
    );
  }
}

/// Un indicador: ícono en su color, el número grande y qué cuenta.
class _TileResumen extends StatelessWidget {
  const _TileResumen(this.dato);

  final DatoResumen dato;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra, _) = coloresDeTono(cs, dato.tono);
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(Esquina.chica),
            ),
            child: Icon(dato.icono, size: 20, color: letra),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dato.valor,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: Peso.dato,
                    fontFeatures: cifrasTabulares,
                    height: 1.1,
                  ),
                ),
                Text(
                  dato.etiqueta,
                  style: context.apagado(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Los indicadores en fila, para pantallas angostas: bajan de línea solos.
class _TilesResumen extends StatelessWidget {
  const _TilesResumen({required this.datos});

  final List<DatoResumen> datos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = (c.maxWidth / 220).floor().clamp(1, datos.length);
        final ancho =
            ((c.maxWidth - Esp.m * (columnas - 1)) / columnas).floorToDouble();
        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final d in datos) SizedBox(width: ancho, child: _TileResumen(d)),
          ],
        );
      },
    );
  }
}

/// El panel derecho de las pantallas anchas: indicadores y un ranking con
/// barras proporcionales al mayor valor.
class _PanelResumen extends StatelessWidget {
  const _PanelResumen({
    required this.datos,
    required this.tituloRanking,
    required this.barras,
  });

  final List<DatoResumen> datos;
  final String? tituloRanking;
  final List<BarraResumen> barras;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    // Una barra en cero no informa nada: el ranking solo muestra lo que hay.
    final ordenadas = [...barras.where((b) => b.valor > 0)]
      ..sort((a, b) => b.valor.compareTo(a.valor));
    final visibles = ordenadas.take(8).toList();
    final maximo =
        visibles.isEmpty
            ? 1
            : visibles.map((b) => b.valor).reduce((a, b) => a > b ? a : b);

    return Column(
      key: const ValueKey('panel-resumen'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in datos) ...[_TileResumen(d), const SizedBox(height: Esp.s)],
        if (visibles.isNotEmpty && tituloRanking != null) ...[
          const SizedBox(height: Esp.s),
          Container(
            padding: const EdgeInsets.all(Esp.l),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Esquina.media),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: Esp.s),
                    Expanded(
                      child: Text(
                        tituloRanking!,
                        style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                for (final b in visibles) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.etiqueta,
                          style: t.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${b.valor}',
                        style: context.numero(fuerte: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: Esp.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                    child: LinearProgressIndicator(
                      value: maximo == 0 ? 0 : b.valor / maximo,
                      minHeight: 6,
                      color: cs.primary,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: Esp.m),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO CON BÚSQUEDA Y PAGINACIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Tabla (escritorio) o tarjetas (móvil) según el ancho del contenedor, con
/// buscador visible y paginación local. No conoce el estado: las acciones
/// llegan ya filtradas por permisos.
class ListaCatalogo<T> extends StatefulWidget {
  const ListaCatalogo({
    super.key,
    required this.items,
    required this.columnas,
    required this.acciones,
    required this.clave,
    required this.tituloTarjeta,
    required this.textoBusqueda,
    required this.unidad,
    this.detalleTarjeta,
    this.pieTarjeta,
    this.alTocar,
    this.pistaBusqueda = 'Buscar…',
    this.filtros = const [],
    this.tamPagina = 10,
    this.acento,
  });

  /// El color de la franja izquierda de cada fila: su estado de un vistazo.
  final TonoDato Function(T item)? acento;

  final List<T> items;
  final List<ColumnaCatalogo<T>> columnas;
  final List<AccionCatalogo<T>> acciones;
  final String Function(T item) clave;
  final String Function(T item) tituloTarjeta;
  final String Function(T item) textoBusqueda;

  /// Singular y plural para el pie: («tipo», «tipos»).
  final (String, String) unidad;
  final String? Function(T item)? detalleTarjeta;
  final Widget? Function(BuildContext context, T item)? pieTarjeta;
  final void Function(T item)? alTocar;
  final String pistaBusqueda;

  /// Filtros extra junto al buscador (combos, chips).
  final List<Widget> filtros;
  final int tamPagina;

  @override
  State<ListaCatalogo<T>> createState() => _ListaCatalogoState<T>();
}

class _ListaCatalogoState<T> extends State<ListaCatalogo<T>> {
  final _buscar = TextEditingController();
  String _consulta = '';
  int _pagina = 1;
  late int _tamPagina = widget.tamPagina;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<T> get _filtrados {
    if (_consulta.isEmpty) return widget.items;
    return widget.items
        .where(
          (i) =>
              normalizarBusqueda(widget.textoBusqueda(i)).contains(_consulta),
        )
        .toList();
  }

  String _cantidad(int n) =>
      '$n ${n == 1 ? widget.unidad.$1 : widget.unidad.$2}';

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final totalPaginas =
        filtrados.isEmpty ? 1 : ((filtrados.length - 1) ~/ _tamPagina) + 1;
    final pagina = _pagina.clamp(1, totalPaginas);
    final desde = (pagina - 1) * _tamPagina;
    final hasta = (desde + _tamPagina).clamp(0, filtrados.length);
    final visibles = filtrados.sublist(desde, hasta);

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final tabla = ancho >= anchoMinimoTablaCatalogo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _barraBusqueda(tabla),
            const SizedBox(height: Esp.m),
            if (filtrados.isEmpty)
              SizedBox(
                height: 240,
                child: MensajeVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin resultados',
                  detalle:
                      'Nada coincide con «${_buscar.text.trim()}». '
                      'Prueba con otra palabra o borra la búsqueda.',
                ),
              )
            else if (tabla)
              _TablaCatalogo<T>(lista: widget, visibles: visibles)
            else
              _TarjetasCatalogo<T>(
                lista: widget,
                visibles: visibles,
                ancho: ancho,
              ),
            const SizedBox(height: Esp.m),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Esp.m,
              runSpacing: Esp.s,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                  child: Text(
                    _consulta.isEmpty
                        ? _cantidad(widget.items.length)
                        : '${_cantidad(filtrados.length)} de ${widget.items.length}',
                    style: context.apagado()?.copyWith(
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                ),
                if (filtrados.length > widget.tamPagina)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: BosquePaginator(
                      currentPage: pagina,
                      totalPages: totalPaginas,
                      firstRow: desde + 1,
                      lastRow: hasta,
                      onPageChanged: (p) => setState(() => _pagina = p),
                      currentPageSize: tabla ? _tamPagina : null,
                      onPageSizeChanged:
                          tabla
                              ? (t) => setState(() {
                                _tamPagina = t;
                                _pagina = 1;
                              })
                              : null,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _barraBusqueda(bool ancha) {
    final buscador = TextField(
      controller: _buscar,
      onChanged:
          (t) => setState(() {
            _consulta = normalizarBusqueda(t.trim());
            _pagina = 1;
          }),
      decoration: InputDecoration(
        hintText: widget.pistaBusqueda,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon:
            _buscar.text.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed:
                      () => setState(() {
                        _buscar.clear();
                        _consulta = '';
                        _pagina = 1;
                      }),
                ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
      ),
    );

    if (ancha) {
      // Los filtros toman el ancho que sobra y bajan de línea si no entran.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: buscador),
          if (widget.filtros.isNotEmpty) ...[
            const SizedBox(width: Esp.m),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Esp.s,
                  runSpacing: Esp.s,
                  children: widget.filtros,
                ),
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buscador,
        if (widget.filtros.isNotEmpty) ...[
          const SizedBox(height: Esp.s),
          Wrap(spacing: Esp.s, runSpacing: Esp.s, children: widget.filtros),
        ],
      ],
    );
  }
}

class _TablaCatalogo<T> extends StatelessWidget {
  const _TablaCatalogo({required this.lista, required this.visibles});

  final ListaCatalogo<T> lista;
  final List<T> visibles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fondoFila = cs.surfaceContainerLow;
    final fondoCabecera = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: 0.55),
      fondoFila,
    );
    final estiloCabecera = t.labelLarge?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onPrimaryContainer,
    );
    // Filas alternadas apenas distintas: guían el ojo sin pintar de más.
    final fondoAlterno = Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.025),
      fondoFila,
    );
    final anchoAcciones = lista.acciones.length * (_anchoIconoAccion + 4.0);

    Widget celda(ColumnaCatalogo<T> c, Widget hijo) {
      final alineado = Align(alignment: c.alineacion, child: hijo);
      return c.ancho != null
          ? SizedBox(width: c.ancho, child: alineado)
          : Expanded(flex: c.flex, child: alineado);
    }

    Widget fila(List<Widget> celdas, Widget acciones) => Row(
      children: [
        for (var i = 0; i < celdas.length; i++) ...[
          if (i > 0) const SizedBox(width: Esp.m),
          celdas[i],
        ],
        if (lista.acciones.isNotEmpty) ...[
          const SizedBox(width: Esp.s),
          SizedBox(width: anchoAcciones, child: acciones),
        ],
      ],
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: fondoFila,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: fondoCabecera,
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: fila(
              [
                for (final c in lista.columnas)
                  celda(
                    c,
                    Text(
                      c.titulo,
                      style: estiloCabecera,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Acciones', style: estiloCabecera),
                ),
              ),
            ),
          ),
          for (final (i, item) in visibles.indexed) ...[
            Divider(height: 1, color: cs.outlineVariant),
            InkWell(
              key: ValueKey('fila-${lista.clave(item)}'),
              onTap: lista.alTocar == null ? null : () => lista.alTocar!(item),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  color: i.isOdd ? fondoAlterno : null,
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color:
                          lista.acento == null
                              ? Colors.transparent
                              : coloresDeTono(cs, lista.acento!(item)).$3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Esp.l,
                  vertical: Esp.s,
                ),
                child: fila(
                  [
                    for (final c in lista.columnas)
                      celda(c, c.celda(context, item)),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final a in lista.acciones)
                        if (a.aplicaA(item))
                        IconButton(
                          tooltip: a.etiqueta,
                          onPressed: () => a.alElegir(item),
                          icon: Icon(a.icono, size: 20),
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(_anchoIconoAccion),
                            maximumSize: const Size.square(_anchoIconoAccion),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetasCatalogo<T> extends StatelessWidget {
  const _TarjetasCatalogo({
    required this.lista,
    required this.visibles,
    required this.ancho,
  });

  final ListaCatalogo<T> lista;
  final List<T> visibles;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final columnas = ((ancho + Esp.m) / (_anchoMinimoTarjeta + Esp.m))
        .floor()
        .clamp(1, 3);
    // Hacia abajo: la suma nunca pasa del ancho por un redondeo.
    final anchoTarjeta =
        ((ancho - Esp.m * (columnas - 1)) / columnas).floorToDouble();

    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.m,
      children: [
        for (final item in visibles)
          SizedBox(
            key: ValueKey('tarjeta-${lista.clave(item)}'),
            width: anchoTarjeta,
            child: _TarjetaCatalogo<T>(lista: lista, item: item),
          ),
      ],
    );
  }
}

class _TarjetaCatalogo<T> extends StatelessWidget {
  const _TarjetaCatalogo({required this.lista, required this.item});

  final ListaCatalogo<T> lista;
  final T item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final detalle = lista.detalleTarjeta?.call(item);
    final pie = lista.pieTarjeta?.call(context, item);
    final acciones = [
      for (final a in lista.acciones)
        if (a.aplicaA(item)) a,
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: InkWell(
        onTap: lista.alTocar == null ? null : () => lista.alTocar!(item),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 4,
                color:
                    lista.acento == null
                        ? Colors.transparent
                        : coloresDeTono(cs, lista.acento!(item)).$3,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            Esp.l,
            Esp.m,
            acciones.isEmpty ? Esp.l : Esp.xs,
            Esp.m,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textoODash(lista.tituloTarjeta(item)),
                      style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (detalle != null && detalle.isNotEmpty) ...[
                      const SizedBox(height: Esp.xs),
                      Text(
                        detalle,
                        style: context.apagado()?.copyWith(
                          fontFeatures: cifrasTabulares,
                        ),
                      ),
                    ],
                    if (pie != null) ...[const SizedBox(height: Esp.s), pie],
                  ],
                ),
              ),
              if (acciones.isNotEmpty)
                MenuAccionesCheque(
                  opciones: [
                    for (final a in acciones)
                      OpcionMenuCheque(
                        a.etiqueta,
                        a.icono,
                        () => a.alElegir(item),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FORMULARIO Y BAJA
// ═══════════════════════════════════════════════════════════════════════════

/// Abre un formulario de parámetros: diálogo en pantallas anchas y pantalla
/// completa en el teléfono (el contenedor de Bancos, sin el tema de Cheques).
Future<R?> abrirFormularioParametro<R>(
  BuildContext context, {
  required WidgetBuilder contenido,
  double anchoMaximo = 520,
}) => abrirPanelCheque<R>(
  context,
  anchoMaximo: anchoMaximo,
  temaDelModulo: false,
  contenido: contenido,
);

/// El marco de un formulario: título, error del servidor arriba de los campos
/// y los botones Cancelar / Guardar con su estado de «en curso».
class PanelParametro extends StatelessWidget {
  const PanelParametro({
    super.key,
    required this.titulo,
    required this.campos,
    required this.ocupado,
    required this.onGuardar,
    this.subtitulo,
    this.errorServidor,
    this.etiquetaGuardar = 'Guardar',
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> campos;
  final bool ocupado;
  final VoidCallback onGuardar;
  final String? errorServidor;
  final String etiquetaGuardar;

  @override
  Widget build(BuildContext context) {
    return MarcoPanelCheque(
      titulo: titulo,
      subtitulo: subtitulo,
      onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorServidor != null) ...[
            ErrorServidorCheque(errorServidor!),
            const SizedBox(height: Esp.l),
          ],
          for (var i = 0; i < campos.length; i++) ...[
            if (i > 0) const SizedBox(height: Esp.l),
            campos[i],
          ],
        ],
      ),
      acciones: [
        TextButton(
          onPressed: ocupado ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardarCheque(
          etiqueta: etiquetaGuardar,
          ocupado: ocupado,
          onPressed: ocupado ? null : onGuardar,
        ),
      ],
    );
  }
}

/// Pide confirmación y ejecuta la baja. Si el servidor la rechaza, su texto se
/// muestra completo en un diálogo que se queda hasta que se lee; si sale bien,
/// el aviso dice lo que redactó el procedimiento.
Future<void> eliminarDeCatalogo(
  BuildContext context, {
  required String titulo,
  required String detalle,
  required String textoConfirmar,
  required OperacionesCatalogoNotifier operaciones,
  required String? Function() errorActual,
  required Future<ResultadoEscrituraEntity> Function() eliminar,
}) async {
  final seguro = await confirmar(
    context,
    titulo: titulo,
    detalle: detalle,
    textoConfirmar: textoConfirmar,
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final r = await operaciones.ejecutar(eliminar);
  if (!context.mounted) return;
  if (r == null) {
    final texto = errorActual() ?? 'No se pudo eliminar.';
    operaciones.limpiarError();
    await mostrarErrorParametro(context, 'No se pudo eliminar', texto);
    return;
  }
  avisar(context, r.mensaje.isEmpty ? 'Eliminado.' : r.mensaje);
}

/// Un rechazo del servidor que hay que leer entero: diálogo con «Entendido».
Future<void> mostrarErrorParametro(
  BuildContext context,
  String titulo,
  String texto,
) {
  return showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          icon: Icon(
            Icons.error_outline,
            color: Theme.of(ctx).colorScheme.error,
          ),
          title: Text(titulo),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in lineasDeError(texto))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Esp.xs),
                      child: Text(l),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
  );
}
