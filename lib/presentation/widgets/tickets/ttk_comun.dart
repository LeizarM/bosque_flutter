/// Piezas compartidas del módulo Tickets / Bingo: encabezado, listado que es
/// tabla en el ancho y tarjetas en el angosto, acciones con permiso por botón
/// y la ejecución de una escritura que muestra el mensaje del SP.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Cifras de ancho fijo para números de cartón, bolillos y vales.
const String ttkFuenteNumeros = 'JetBrainsMono';

/// Por debajo de este ancho de contenedor el listado pasa a tarjetas.
const double ttkAnchoTabla = 720;

/// `#RRGGBB` de la base a color; null si no hay o no es válido.
Color? ttkColorHex(String? hex) {
  final t = (hex ?? '').replaceFirst('#', '').trim();
  if (t.length != 6) return null;
  final v = int.tryParse(t, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// El texto o un guion: nunca «null» en pantalla.
String ttkOGuion(String? t) => (t == null || t.trim().isEmpty) ? '—' : t;

/// Tono de la etiqueta según el código de estado (evento, bingo o juego).
TonoEtiqueta ttkTonoEstado(String? estado) => switch (estado) {
  'EMITIDO' || 'EN_JUEGO' || 'EN_CURSO' => TonoEtiqueta.exito,
  'GENERADO' || 'ELECCION' => TonoEtiqueta.aviso,
  _ => TonoEtiqueta.neutro,
};

/// Ejecuta una escritura y muestra el `message` del SP. Devuelve si salió bien.
Future<bool> ejecutarTtk(
  BuildContext context,
  Future<TtkRespuesta> Function() accion,
) async {
  try {
    final r = await accion();
    if (context.mounted && r.mensaje.isNotEmpty) {
      mostrarAviso(context, r.mensaje);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      HapticFeedback.lightImpact();
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
    return false;
  }
}

/// Encabezado de pantalla: ceja del módulo, título, detalle y acciones.
class EncabezadoTtk extends StatelessWidget {
  const EncabezadoTtk({
    super.key,
    required this.ceja,
    required this.titulo,
    this.detalle,
    this.acciones = const [],
    this.compacto = false,
    this.alVolver,
  });

  final String ceja;
  final String titulo;
  final String? detalle;
  final List<Widget> acciones;
  final bool compacto;
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ceja,
          style: t.labelLarge?.copyWith(
            fontWeight: Peso.titulo,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: Esp.xs),
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: (compacto ? t.titleLarge : t.headlineSmall)?.copyWith(
              fontWeight: Peso.titulo,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (detalle != null && detalle!.isNotEmpty) ...[
          const SizedBox(height: Esp.xs),
          Text(
            detalle!,
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
    // En el teléfono los iconos (actualizar) van junto al título y el resto debajo.
    final iconos =
        compacto ? acciones.whereType<IconButton>().toList() : const <Widget>[];
    final otras =
        compacto ? acciones.where((w) => w is! IconButton).toList() : acciones;
    final cabeza = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (alVolver != null)
          Padding(
            padding: const EdgeInsets.only(right: Esp.s),
            child: IconButton(
              tooltip: 'Volver',
              onPressed: alVolver,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        Expanded(flex: 3, child: textos),
        ...iconos,
        if (!compacto && acciones.isNotEmpty) ...[
          const SizedBox(width: Esp.l),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.topRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Esp.s,
                runSpacing: Esp.s,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: acciones,
              ),
            ),
          ),
        ],
      ],
    );
    if (!compacto || otras.isEmpty) return cabeza;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cabeza,
        const SizedBox(height: Esp.m),
        Wrap(spacing: Esp.s, runSpacing: Esp.s, children: otras),
      ],
    );
  }
}

/// Superficie con título que agrupa un bloque de la pantalla.
class SeccionTtk extends StatelessWidget {
  const SeccionTtk({
    super.key,
    required this.titulo,
    required this.child,
    this.accion,
    this.relleno = const EdgeInsets.all(Esp.l),
  });

  final String titulo;
  final Widget child;
  final Widget? accion;
  final EdgeInsets relleno;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: relleno,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(titulo, style: context.tituloSeccion())),
                if (accion != null) accion!,
              ],
            ),
            const SizedBox(height: Esp.m),
            child,
          ],
        ),
      ),
    );
  }
}

/// Un dato que se compara: cifra grande con su rótulo.
class CifraTtk extends StatelessWidget {
  const CifraTtk({super.key, required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: t.headlineSmall?.copyWith(
            fontFamily: ttkFuenteNumeros,
            fontWeight: Peso.dato,
            fontFeatures: cifrasTabulares,
          ),
        ),
        Text(rotulo, style: context.apagado()),
      ],
    );
  }
}

/// Una acción de fila o tarjeta. Con [boton], solo aparece si el usuario
/// tiene ese permiso (`tb_vistaBtn`).
class AccionTtk {
  const AccionTtk(
    this.etiqueta,
    this.icono,
    this.alTocar, {
    this.boton,
    this.destructiva = false,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alTocar;
  final String? boton;
  final bool destructiva;
}

/// Las acciones que el usuario puede ver (sin botón o con su permiso).
List<AccionTtk> accionesPermitidasTtk(
  WidgetRef ref,
  List<AccionTtk> acciones,
) => [
  for (final a in acciones)
    if (a.boton == null || tienePermisoDeBoton(ref, a.boton!)) a,
];

/// Acciones en línea (iconos con su ayuda), para la tabla del escritorio.
class AccionesEnLineaTtk extends ConsumerWidget {
  const AccionesEnLineaTtk({super.key, required this.acciones});

  final List<AccionTtk> acciones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visibles = accionesPermitidasTtk(ref, acciones);
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 0,
      children: [
        for (final a in visibles)
          IconButton(
            tooltip: a.etiqueta,
            visualDensity: VisualDensity.compact,
            onPressed: a.alTocar,
            icon: Icon(
              a.icono,
              size: 20,
              color: a.destructiva ? cs.error : null,
            ),
          ),
      ],
    );
  }
}

/// Las mismas acciones en un menú contextual, para tarjetas del teléfono.
class MenuAccionesTtk extends ConsumerWidget {
  const MenuAccionesTtk({super.key, required this.acciones});

  final List<AccionTtk> acciones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visibles = accionesPermitidasTtk(ref, acciones);
    if (visibles.isEmpty) return const SizedBox(width: 48);
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_vert),
      onSelected: (i) => visibles[i].alTocar(),
      itemBuilder:
          (_) => [
            for (var i = 0; i < visibles.length; i++)
              PopupMenuItem(
                value: i,
                child: Row(
                  children: [
                    Icon(
                      visibles[i].icono,
                      size: 20,
                      color: visibles[i].destructiva ? cs.error : null,
                    ),
                    const SizedBox(width: Esp.m),
                    Flexible(child: Text(visibles[i].etiqueta)),
                  ],
                ),
              ),
          ],
    );
  }
}

/// Tarjeta de un registro en el teléfono: título, línea de apoyo, etiquetas y
/// menú de acciones. Se toca entera para abrir.
class TarjetaTtk extends StatelessWidget {
  const TarjetaTtk({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.etiquetas = const [],
    this.pie,
    this.acciones = const [],
    this.alTocar,
    this.inicio,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> etiquetas;
  final Widget? pie;
  final List<AccionTtk> acciones;
  final VoidCallback? alTocar;
  final Widget? inicio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.xs, Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inicio != null) ...[inicio!, const SizedBox(width: Esp.m)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    ),
                    if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitulo!, style: context.apagado()),
                    ],
                    if (etiquetas.isNotEmpty) ...[
                      const SizedBox(height: Esp.s),
                      Wrap(
                        spacing: Esp.xs,
                        runSpacing: Esp.xs,
                        children: etiquetas,
                      ),
                    ],
                    if (pie != null) ...[const SizedBox(height: Esp.s), pie!],
                  ],
                ),
              ),
              if (acciones.isNotEmpty) MenuAccionesTtk(acciones: acciones),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selección múltiple de un listado: qué claves están marcadas y cómo cambian.
class SeleccionTtk<T> {
  const SeleccionTtk({
    required this.claves,
    required this.clave,
    required this.alCambiar,
  });

  final Set<Object> claves;
  final Object Function(T fila) clave;
  final ValueChanged<Set<Object>> alCambiar;

  bool marcada(T fila) => claves.contains(clave(fila));

  void alternar(T fila) {
    final k = clave(fila);
    alCambiar(claves.contains(k) ? ({...claves}..remove(k)) : ({...claves, k}));
  }

  /// Estado de «todo» sobre [filas]: true, false o null si hay de los dos.
  bool? todas(List<T> filas) {
    if (filas.isEmpty) return false;
    final n = filas.where(marcada).length;
    if (n == 0) return false;
    return n == filas.length ? true : null;
  }

  /// Marca todo lo filtrado o, si ya estaba todo, lo desmarca.
  void alternarTodas(List<T> filas) {
    final ks = filas.map(clave).toSet();
    alCambiar(
      todas(filas) == true
          ? ({...claves}..removeAll(ks))
          : ({...claves, ...ks}),
    );
  }
}

/// Tabla del módulo con los colores del tema: contenedor con borde sobre la
/// página, encabezado en una superficie más alta y filas separadas por línea.
class TablaTtk<T> extends StatelessWidget {
  const TablaTtk({
    super.key,
    required this.filas,
    required this.columnas,
    this.seleccion,
    this.filtradas = const [],
  });

  /// Las filas de la página visible.
  final List<T> filas;
  final List<BosqueColumn<T>> columnas;
  final SeleccionTtk<T>? seleccion;

  /// Todo lo filtrado: es lo que marca la casilla del encabezado.
  final List<T> filtradas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final sel = seleccion;
    const casilla = 44.0;
    Widget celdas(List<Widget> hijos) => Row(children: hijos);

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
              constraints: const BoxConstraints(minHeight: 48),
              child: celdas([
                if (sel != null)
                  SizedBox(
                    width: casilla,
                    child: Checkbox(
                      tristate: true,
                      value: sel.todas(filtradas),
                      onChanged: (_) => sel.alternarTodas(filtradas),
                      semanticLabel: 'Seleccionar todo lo filtrado',
                    ),
                  ),
                for (final c in columnas)
                  Expanded(
                    flex: c.flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                      child: Align(
                        alignment: c.alignment,
                        child: Text(
                          c.label,
                          style: t.labelLarge?.copyWith(
                            fontWeight: Peso.titulo,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            Expanded(
              child:
                  filas.isEmpty
                      ? const MensajeVacio(
                        icono: Icons.search_off,
                        titulo: 'Sin resultados',
                        detalle: 'Cambia la búsqueda o los filtros.',
                      )
                      : Scrollbar(
                        child: ListView.separated(
                          itemCount: filas.length,
                          separatorBuilder:
                              (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: cs.outlineVariant,
                              ),
                          itemBuilder: (context, i) {
                            final f = filas[i];
                            final marcada = sel?.marcada(f) ?? false;
                            return ColoredBox(
                              color:
                                  marcada
                                      ? cs.secondaryContainer
                                      : (i.isOdd
                                          ? cs.surfaceContainerLow
                                          : cs.surfaceContainerLowest),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Esp.m,
                                  vertical: Esp.s,
                                ),
                                child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color:
                                        marcada
                                            ? cs.onSecondaryContainer
                                            : cs.onSurface,
                                  ),
                                  child: celdas([
                                    if (sel != null)
                                      SizedBox(
                                        width: casilla,
                                        child: Checkbox(
                                          value: marcada,
                                          onChanged: (_) => sel.alternar(f),
                                        ),
                                      ),
                                    for (final c in columnas)
                                      Expanded(
                                        flex: c.flex,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Esp.s,
                                          ),
                                          child: Align(
                                            alignment: c.alignment,
                                            child: c.cellBuilder(f),
                                          ),
                                        ),
                                      ),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listado del módulo: en un contenedor ancho, la tabla con filtros a la
/// vista y paginación; en uno angosto, tarjetas con filtros plegados. Con
/// [seleccion], casillas en la tabla y en las tarjetas.
class ListadoTtk<T> extends StatefulWidget {
  const ListadoTtk({
    super.key,
    required this.filas,
    required this.columnas,
    required this.tarjeta,
    this.buscador,
    this.alBuscar,
    this.pistaBuscar = 'Buscar…',
    this.filtros = const [],
    this.cargando = false,
    this.porPagina = 15,
    this.seleccion,
  });

  final List<T> filas;
  final List<BosqueColumn<T>> columnas;
  final Widget Function(T fila) tarjeta;
  final TextEditingController? buscador;
  final ValueChanged<String>? alBuscar;
  final String pistaBuscar;
  final List<Widget> filtros;
  final bool cargando;
  final int porPagina;
  final SeleccionTtk<T>? seleccion;

  @override
  State<ListadoTtk<T>> createState() => _ListadoTtkState<T>();
}

class _ListadoTtkState<T> extends State<ListadoTtk<T>> {
  late int _tam = widget.porPagina;
  int _pagina = 1;

  int get _paginas => math.max(1, (widget.filas.length / _tam).ceil());

  List<T> get _visibles {
    final pagina = _pagina.clamp(1, _paginas);
    final desde = (pagina - 1) * _tam;
    return widget.filas.sublist(
      math.min(desde, widget.filas.length),
      math.min(desde + _tam, widget.filas.length),
    );
  }

  void _irA(int p) => setState(() => _pagina = p);

  void _cambiarTam(int n) => setState(() {
    _tam = n;
    _pagina = 1;
  });

  @override
  void didUpdateWidget(covariant ListadoTtk<T> viejo) {
    super.didUpdateWidget(viejo);
    if (_pagina > _paginas) _pagina = _paginas;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pagina = _pagina.clamp(1, _paginas);
        final primera = widget.filas.isEmpty ? 0 : (pagina - 1) * _tam + 1;
        final ultima = math.min(pagina * _tam, widget.filas.length);
        if (c.maxWidth >= ttkAnchoTabla) {
          return _ListaAncha<T>(
            estado: this,
            pagina: pagina,
            primera: primera,
            ultima: ultima,
          );
        }
        return _ListaAngosta<T>(
          estado: this,
          pagina: pagina,
          primera: primera,
          ultima: ultima,
        );
      },
    );
  }
}

class _ListaAncha<T> extends StatelessWidget {
  const _ListaAncha({
    required this.estado,
    required this.pagina,
    required this.primera,
    required this.ultima,
  });

  final _ListadoTtkState<T> estado;
  final int pagina;
  final int primera;
  final int ultima;

  @override
  Widget build(BuildContext context) {
    final w = estado.widget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Esp.s),
          child: Wrap(
            spacing: Esp.l,
            runSpacing: Esp.s,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (w.alBuscar != null)
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: w.buscador,
                    onChanged: w.alBuscar,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: w.pistaBuscar,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              if (w.filtros.isNotEmpty)
                Wrap(
                  spacing: Esp.m,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: w.filtros,
                ),
            ],
          ),
        ),
        Expanded(
          child:
              w.cargando
                  ? const EsqueletoListaTtk()
                  : TablaTtk<T>(
                    filas: estado._visibles,
                    columnas: w.columnas,
                    seleccion: w.seleccion,
                    filtradas: w.filas,
                  ),
        ),
        BosquePaginator(
          currentPage: pagina,
          totalPages: estado._paginas,
          firstRow: primera,
          lastRow: ultima,
          onPageChanged: estado._irA,
          currentPageSize: estado._tam,
          onPageSizeChanged: (n) => estado._cambiarTam(n),
        ),
      ],
    );
  }
}

class _ListaAngosta<T> extends StatelessWidget {
  const _ListaAngosta({
    required this.estado,
    required this.pagina,
    required this.primera,
    required this.ultima,
  });

  final _ListadoTtkState<T> estado;
  final int pagina;
  final int primera;
  final int ultima;

  @override
  Widget build(BuildContext context) {
    final w = estado.widget;
    final visibles = estado._visibles;
    final sel = w.seleccion;
    return Column(
      children: [
        if (w.alBuscar != null)
          Padding(
            padding: const EdgeInsets.only(top: Esp.s),
            child: TextField(
              controller: w.buscador,
              onChanged: w.alBuscar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: w.pistaBuscar,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        if (w.filtros.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: Esp.s),
              leading: const Icon(Icons.tune, size: 20),
              title: const Text('Filtros'),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: Esp.s, runSpacing: Esp.s, children: w.filtros),
              ],
            ),
          ),
        if (sel != null && w.filas.isNotEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            tristate: true,
            value: sel.todas(w.filas),
            onChanged: (_) => sel.alternarTodas(w.filas),
            title: Text('Seleccionar todo (${w.filas.length})'),
          ),
        Expanded(
          child:
              w.cargando
                  ? const EsqueletoListaTtk()
                  : visibles.isEmpty
                  ? const MensajeVacio(
                    icono: Icons.search_off,
                    titulo: 'Sin resultados',
                    detalle: 'Cambia la búsqueda o los filtros.',
                  )
                  : Scrollbar(
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: Esp.s),
                      itemCount: visibles.length,
                      itemBuilder:
                          (_, i) =>
                              sel == null
                                  ? w.tarjeta(visibles[i])
                                  : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: Esp.s,
                                        ),
                                        child: Checkbox(
                                          value: sel.marcada(visibles[i]),
                                          onChanged:
                                              (_) => sel.alternar(visibles[i]),
                                        ),
                                      ),
                                      Expanded(child: w.tarjeta(visibles[i])),
                                    ],
                                  ),
                    ),
                  ),
        ),
        if (estado._paginas > 1)
          BosquePaginator(
            currentPage: pagina,
            totalPages: estado._paginas,
            firstRow: primera,
            lastRow: ultima,
            onPageChanged: estado._irA,
          ),
      ],
    );
  }
}

/// Esqueleto de carga del kit con la altura de una tarjeta del módulo.
class EsqueletoListaTtk extends StatelessWidget {
  const EsqueletoListaTtk({super.key});

  @override
  Widget build(BuildContext context) => const EsqueletoLista(altoFila: 84);
}

/// Diálogo con ancho máximo que en el teléfono usa casi toda la pantalla.
Future<R?> mostrarDialogoTtk<R>(
  BuildContext context, {
  required String titulo,
  required Widget Function(BuildContext ctx) contenido,
  List<Widget> Function(BuildContext ctx)? acciones,
  double anchoMaximo = 560,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<R>(
    context: context,
    builder: (ctx) {
      final angosto = MediaQuery.sizeOf(ctx).width < 600;
      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: angosto ? Esp.m : Esp.xl,
          vertical: Esp.xl,
        ),
        title: Text(titulo),
        content: SizedBox(
          width: anchoMaximo,
          child: SingleChildScrollView(child: contenido(ctx)),
        ),
        actions: acciones?.call(ctx),
      );
    },
  );
}

/// Fecha corta del kit (dd/mm/aaaa).
String ttkFechaCorta(DateTime? f) => fechaCorta(f);
