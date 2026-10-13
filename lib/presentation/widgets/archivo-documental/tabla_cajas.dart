/// Las cajas en escritorio: la etiqueta de la caja (su número o su foto) en el
/// color de su archivo, columnas con `flex`, acciones en la fila y paginación.
/// En el teléfono, la misma información en tarjetas. Tocar abre la caja.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/imagen_foto.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

enum AccionCaja { abrir, editar, eliminar }

const double _altoCabecera = 40;
const double _altoFila = 68;
const double _anchoEtiqueta = 72;
const double _anchoAcciones = 104;
const List<int> _tamaniosPagina = [15, 25, 50, 100];

class TablaCajas extends StatefulWidget {
  const TablaCajas({
    super.key,
    required this.filas,
    required this.onAccion,
    required this.codigosArchivo,
    this.enCurso = const <int>{},
  });

  final List<ResultadoCaja> filas;
  final void Function(ResultadoCaja fila, AccionCaja accion) onAccion;

  /// Los ids de todos los archivos: el color de cada caja sale de aquí.
  final List<int> codigosArchivo;

  /// Cajas con una escritura viajando: sus botones quedan apagados.
  final Set<int> enCurso;

  @override
  State<TablaCajas> createState() => _TablaCajasState();
}

class _TablaCajasState extends State<TablaCajas> {
  final _scroll = ScrollController();
  int _pagina = 1;
  int _porPagina = _tamaniosPagina.first;

  @override
  void didUpdateWidget(TablaCajas anterior) {
    super.didUpdateWidget(anterior);
    // Otro filtro, otro listado: volver a la primera página.
    if (anterior.filas.length != widget.filas.length) {
      _pagina = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = widget.filas.length;
    final paginas = math.max(1, (total / _porPagina).ceil());
    final pagina = _pagina.clamp(1, paginas);
    final desde = (pagina - 1) * _porPagina;
    final hasta = math.min(desde + _porPagina, total);
    final visibles = widget.filas.sublist(desde, hasta);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _cabecera(context),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    itemExtent: _altoFila,
                    itemCount: visibles.length,
                    itemBuilder: (context, i) => _fila(context, visibles[i], i),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Esp.s),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Esp.l,
            runSpacing: Esp.s,
            children: [
              Text(
                total == 0 ? 'Sin cajas para mostrar' : 'Mostrando ${desde + 1}-$hasta de $total cajas',
                style: context.apagado(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Filas', style: context.apagado()),
                  const SizedBox(width: Esp.s),
                  DropdownButton<int>(
                    value: _porPagina,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final n in _tamaniosPagina) DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (n) {
                      if (n != null) {
                        setState(() {
                          _porPagina = n;
                          _pagina = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: Esp.m),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Página anterior',
                    visualDensity: VisualDensity.compact,
                    onPressed: pagina > 1 ? () => setState(() => _pagina = pagina - 1) : null,
                  ),
                  Text('$pagina de $paginas', style: context.numero(fuerte: true)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Página siguiente',
                    visualDensity: VisualDensity.compact,
                    onPressed: pagina < paginas ? () => setState(() => _pagina = pagina + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _columnas = <(String, int, Alignment)>[
    ('ARCHIVO', 3, Alignment.centerLeft),
    ('UBICACIÓN', 3, Alignment.centerLeft),
    ('CONTENIDO', 8, Alignment.centerLeft),
    ('GESTIÓN', 2, Alignment.centerLeft),
    ('FOTOS', 1, Alignment.center),
  ];

  Widget _cabecera(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: Peso.titulo,
      letterSpacing: 0.6,
    );
    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(width: _anchoEtiqueta, child: Center(child: Text('CAJA', style: estilo))),
          for (final (rotulo, flex, alinear) in _columnas)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                child: Align(
                  alignment: alinear,
                  child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo),
                ),
              ),
            ),
          SizedBox(width: _anchoAcciones, child: Center(child: Text('ACCIONES', style: estilo))),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, ResultadoCaja r, int indice) {
    final cs = Theme.of(context).colorScheme;
    final c = r.caja;
    final ocupado = widget.enCurso.contains(c.codCaja);
    final semilla = semillaDeArchivo(c.codArchivo, widget.codigosArchivo);

    Widget celda(int i, Widget hijo) => Expanded(
      flex: _columnas[i].$2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s),
        child: Align(alignment: _columnas[i].$3, child: hijo),
      ),
    );

    return InkWell(
      onTap: () => widget.onAccion(r, AccionCaja.abrir),
      hoverColor: tonoDe(context, semilla).fondo.withValues(alpha: 0.35),
      child: Container(
        decoration: BoxDecoration(
          color: indice.isEven ? Colors.transparent : cs.surfaceContainerLow,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _anchoEtiqueta,
              child: Center(child: EtiquetaCaja(caja: c, semilla: semilla, lado: 52)),
            ),
            celda(
              0,
              ChipTono(texto: oGuion(c.nombreArchivo), semilla: semilla, icono: Icons.warehouse_outlined),
            ),
            celda(
              1,
              DatoTono(
                icono: Icons.place_outlined,
                semilla: TonosArchivo.ubicacion,
                rotulo: 'Ubicación',
                valor: ubicacionLegible(c),
                apagado: !c.tieneUbicacion,
              ),
            ),
            celda(2, _Contenido(fila: r)),
            celda(
              3,
              c.anioDesde == null
                  ? Text('--', style: context.apagado())
                  : ChipTono(
                    texto: rangoAnios(c.anioDesde, c.anioHasta),
                    semilla: TonosArchivo.gestion,
                    icono: Icons.event_outlined,
                  ),
            ),
            celda(
              4,
              c.fotos == 0
                  ? Text('--', style: context.apagado())
                  : DatoTono(
                    icono: Icons.photo_camera_outlined,
                    semilla: TonosArchivo.fotos,
                    rotulo: 'Fotos',
                    valor: '${c.fotos}',
                  ),
            ),
            SizedBox(
              width: _anchoAcciones,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    style: estiloIconoTonal(context, TonosArchivo.documentos),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Editar la ${tituloCaja(c).toLowerCase()}',
                    visualDensity: VisualDensity.compact,
                    onPressed: ocupado ? null : () => widget.onAccion(r, AccionCaja.editar),
                  ),
                  const SizedBox(width: Esp.xs),
                  IconButton.filledTonal(
                    style: estiloIconoTonal(context, TonosArchivo.peligro),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Eliminar la ${tituloCaja(c).toLowerCase()}',
                    visualDensity: VisualDensity.compact,
                    onPressed: ocupado ? null : () => widget.onAccion(r, AccionCaja.eliminar),
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

/// Lo que guarda la caja: con una búsqueda puesta, el primer documento que
/// coincide y cuántos; sin búsqueda, sus tipos principales como chips azules.
class _Contenido extends StatelessWidget {
  const _Contenido({required this.fila});

  final ResultadoCaja fila;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = fila;
    if (r.filtrada && r.coincidencias.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.coincidencias.first.detalle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
          const SizedBox(height: 2),
          ChipTono(
            texto: '${r.coincidencias.length} de ${documentosLegible(r.lineas.length)} coinciden',
            semilla: TonosArchivo.ubicacion,
            icono: Icons.check_circle_outline,
          ),
        ],
      );
    }
    if (r.lineas.isEmpty) {
      return Text('Caja vacía', style: tt.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant));
    }
    final tipos = tiposPorFrecuencia(r.lineas);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final t in tipos.take(2))
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: Esp.xs),
                  child: ChipTono(texto: t, semilla: TonosArchivo.documentos),
                ),
              ),
            if (tipos.length > 2)
              Text('+${tipos.length - 2}', style: context.numero(fuerte: true)),
          ],
        ),
        const SizedBox(height: 2),
        Text(documentosLegible(r.lineas.length), style: context.apagado()),
      ],
    );
  }
}

/// La caja vista desde un teléfono: su etiqueta a la izquierda, el archivo y
/// lo que guarda, y las acciones en un menú para no competir con el scroll.
class TarjetaCaja extends StatelessWidget {
  const TarjetaCaja({
    super.key,
    required this.fila,
    required this.onAccion,
    required this.codigosArchivo,
    this.ocupado = false,
  });

  final ResultadoCaja fila;
  final ValueChanged<AccionCaja> onAccion;
  final List<int> codigosArchivo;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = fila.caja;
    final coincide = fila.filtrada && fila.coincidencias.isNotEmpty;
    final semilla = semillaDeArchivo(c.codArchivo, codigosArchivo);

    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onAccion(AccionCaja.abrir),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EtiquetaCaja(caja: c, semilla: semilla, lado: 64),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChipTono(
                      texto: oGuion(c.nombreArchivo),
                      semilla: semilla,
                      icono: Icons.warehouse_outlined,
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      coincide ? fila.coincidencias.first.detalle : resumenTipos(fila.lineas),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                    ),
                    if (coincide) ...[
                      const SizedBox(height: Esp.xs),
                      ChipTono(
                        texto: '${fila.coincidencias.length} de ${documentosLegible(fila.lineas.length)} coinciden',
                        semilla: TonosArchivo.ubicacion,
                        icono: Icons.check_circle_outline,
                      ),
                    ],
                    const SizedBox(height: Esp.s),
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.xs,
                      children: [
                        DatoTono(
                          icono: Icons.place_outlined,
                          semilla: TonosArchivo.ubicacion,
                          rotulo: 'Ubicación',
                          valor: ubicacionLegible(c),
                          apagado: !c.tieneUbicacion,
                        ),
                        DatoTono(
                          icono: Icons.event_outlined,
                          semilla: TonosArchivo.gestion,
                          rotulo: 'Gestión',
                          valor: rangoAnios(c.anioDesde, c.anioHasta),
                          apagado: c.anioDesde == null,
                        ),
                        DatoTono(
                          icono: Icons.description_outlined,
                          semilla: TonosArchivo.documentos,
                          rotulo: 'Contenido',
                          valor: documentosLegible(fila.lineas.length),
                        ),
                        if (c.fotos > 0)
                          DatoTono(
                            icono: Icons.photo_camera_outlined,
                            semilla: TonosArchivo.fotos,
                            rotulo: 'Fotos',
                            valor: '${c.fotos}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AccionCaja>(
                enabled: !ocupado,
                icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                tooltip: 'Acciones de la ${tituloCaja(c).toLowerCase()}',
                onSelected: onAccion,
                itemBuilder:
                    (_) => [
                      PopupMenuItem(
                        value: AccionCaja.abrir,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(Icons.inventory_2_outlined, semilla, lado: 28),
                          title: const Text('Abrir'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: AccionCaja.editar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(Icons.edit_outlined, TonosArchivo.documentos, lado: 28),
                          title: Text('Editar caja'),
                        ),
                      ),
                      PopupMenuItem(
                        value: AccionCaja.eliminar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const IconoTono(Icons.delete_outline, TonosArchivo.peligro, lado: 28),
                          title: Text('Eliminar caja', style: TextStyle(color: cs.error)),
                        ),
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
