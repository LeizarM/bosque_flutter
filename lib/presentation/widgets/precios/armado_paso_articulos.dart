/// Paso 2 del asistente (propuesta por artículos): elegir familias, marcar sus
/// artículos y agregarlos de una vez, en una transacción. Reemplaza a `dlgProd`
/// + `dlgArtD` (un viaje por artículo; el primero creaba la propuesta).
///
/// La actualización desde SAP es un botón: trae a `tpr_articulo` la mercadería
/// recién creada en SAP y puede tardar minutos; el sistema anterior la corría en
/// cada "Nueva Propuesta". Se corre cuando falta un artículo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';

const FiltroFamilias _soloActivas = FiltroFamilias(estado: 1);

/// La UTM de un articulo es chica -0,0025 toneladas por resma-: con dos
/// decimales todas salen 0.
final NumberFormat _fmtUtm = NumberFormat('#,##0.####', 'es');

/// Que se esta mirando. En escritorio las familias van siempre a la izquierda
/// y esto elige el panel de la derecha; en el telefono elige el unico panel.
enum _Panel { familias, articulos, enPropuesta }

class ArmadoPasoArticulos extends ConsumerStatefulWidget {
  const ArmadoPasoArticulos({super.key, required this.aire});

  final Aire aire;

  @override
  ConsumerState<ArmadoPasoArticulos> createState() =>
      _ArmadoPasoArticulosState();
}

class _ArmadoPasoArticulosState extends ConsumerState<ArmadoPasoArticulos> {
  final Set<int> _familias = {};
  final Set<String> _elegidos = {};
  String _buscarFamilia = '';
  String _buscarArticulo = '';
  _Panel _panel = _Panel.familias;

  bool get _anchoDoble => widget.aire == Aire.amplio;

  @override
  void initState() {
    super.initState();
    // En escritorio las familias estan siempre a la vista: el panel derecho
    // arranca en los articulos.
    if (widget.aire == Aire.amplio) _panel = _Panel.articulos;
  }

  @override
  void didUpdateWidget(ArmadoPasoArticulos anterior) {
    super.didUpdateWidget(anterior);
    if (_anchoDoble && _panel == _Panel.familias) _panel = _Panel.articulos;
  }

  void _alternarFamilia(int codigo) => setState(() {
    if (!_familias.remove(codigo)) _familias.add(codigo);
    // Los articulos de una familia que se quito ya no estan en la lista: si
    // quedaran marcados, se agregarian sin que nadie los vea.
    _elegidos.clear();
  });

  Future<void> _agregar() async {
    final codigos = _elegidos.toList()..sort();
    final r = await ref.read(armadoProvider.notifier).agregarArticulos(codigos);
    if (!mounted) return;
    if (!r.salio) {
      avisar(context, r.error!, esError: true);
      return;
    }
    final res = r.valor!;
    setState(() => _elegidos.clear());
    avisar(
      context,
      '${res.articulos} '
      '${res.articulos == 1 ? 'artículo agregado' : 'artículos agregados'} '
      'a la propuesta N.º ${res.idPropuesta}'
      '${res.omitidos > 0 ? ' (${res.omitidos} ya estaban)' : ''}.',
    );
  }

  Future<void> _quitar(ArticuloPropuestoEntity articulo) async {
    final seguir = await confirmar(
      context,
      titulo: 'Quitar el artículo ${articulo.codArticulo}',
      detalle:
          '${articulo.datoArticulo.trim().isEmpty ? 'El artículo' : '«${articulo.datoArticulo.trim()}»'} '
          'sale de la propuesta. Se puede volver a agregar mientras siga '
          'pendiente.',
      textoConfirmar: 'Quitar',
      destructiva: true,
    );
    if (!seguir || !mounted) return;
    final r = await ref.read(armadoProvider.notifier).quitarArticulo(articulo);
    if (!mounted) return;
    avisar(
      context,
      r.salio ? 'Artículo ${articulo.codArticulo} quitado.' : r.error!,
      esError: !r.salio,
    );
  }

  Future<void> _sincronizar() async {
    final seguir = await confirmar(
      context,
      titulo: 'Actualizar artículos desde SAP',
      detalle:
          'Trae los artículos nuevos de SAP y actualiza el stock y la UTM de '
          'los que ya están. Puede tardar varios minutos; mientras tanto no '
          'se puede agregar nada.\n\nÚselo cuando falta un artículo recién '
          'creado en SAP.',
      textoConfirmar: 'Actualizar',
    );
    if (!seguir || !mounted) return;
    final r = await ref.read(armadoProvider.notifier).sincronizarArticulosSap();
    if (!mounted) return;
    avisar(
      context,
      r.salio ? 'Artículos actualizados desde SAP.' : r.error!,
      esError: !r.salio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(armadoProvider);
    final enPropuesta =
        estado.existe
            ? ref.watch(articulosArmadosProvider(estado.idPropuesta!))
            : const AsyncValue<List<ArticuloPropuestoEntity>>.data([]);
    final yaEstan = {
      for (final a
          in enPropuesta.valueOrNull ?? const <ArticuloPropuestoEntity>[])
        a.codArticulo.trim().toUpperCase(),
    };
    final cantidadEnPropuesta = enPropuesta.valueOrNull?.length ?? 0;

    final margen = widget.aire.esChico ? Esp.m : Esp.xl;

    final selector = SegmentedButton<_Panel>(
      showSelectedIcon: false,
      segments: [
        if (!_anchoDoble)
          ButtonSegment(
            value: _Panel.familias,
            label: Text('Familias (${_familias.length})'),
          ),
        const ButtonSegment(
          value: _Panel.articulos,
          label: Text('Para agregar'),
        ),
        ButtonSegment(
          value: _Panel.enPropuesta,
          label: Text('En la propuesta ($cantidadEnPropuesta)'),
        ),
      ],
      selected: {_panel},
      onSelectionChanged: (s) => setState(() => _panel = s.first),
    );

    final cabecera = Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.s),
      child: Wrap(
        spacing: Esp.m,
        runSpacing: Esp.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: selector,
          ),
          OutlinedButton.icon(
            onPressed: estado.ocupado ? null : _sincronizar,
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Actualizar desde SAP'),
          ),
        ],
      ),
    );

    final panelDerecho = switch (_panel) {
      _Panel.familias => _PanelFamilias(
        seleccion: _familias,
        busqueda: _buscarFamilia,
        onBuscar: (t) => setState(() => _buscarFamilia = t),
        onAlternar: _alternarFamilia,
      ),
      _Panel.articulos => _PanelArticulos(
        familias: _familias,
        elegidos: _elegidos,
        yaEstan: yaEstan,
        busqueda: _buscarArticulo,
        compacto: widget.aire.esChico,
        ocupado: estado.ocupado,
        onBuscar: (t) => setState(() => _buscarArticulo = t),
        onAlternar:
            (c) => setState(() {
              if (!_elegidos.remove(c)) _elegidos.add(c);
            }),
        onTodos:
            (codigos, marcar) => setState(() {
              marcar ? _elegidos.addAll(codigos) : _elegidos.removeAll(codigos);
            }),
        onAgregar: _agregar,
        onIrAFamilias:
            _anchoDoble ? null : () => setState(() => _panel = _Panel.familias),
      ),
      _Panel.enPropuesta => _PanelEnPropuesta(
        articulos: enPropuesta,
        ocupado: estado.ocupado,
        onQuitar: _quitar,
      ),
    };

    // Con el teclado abierto en el telefono la cabecera no deja lugar a la
    // lista: CabezaYLista la acota.
    return CabezaYLista(
      cabeza: [cabecera],
      lista: Padding(
        padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
        child:
            _anchoDoble
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: _PanelFamilias(
                        seleccion: _familias,
                        busqueda: _buscarFamilia,
                        onBuscar: (t) => setState(() => _buscarFamilia = t),
                        onAlternar: _alternarFamilia,
                      ),
                    ),
                    const SizedBox(width: Esp.l),
                    Expanded(child: panelDerecho),
                  ],
                )
                : panelDerecho,
      ),
    );
  }
}

/// Un recuadro con borde, para que los paneles se lean como tales.
class _Recuadro extends StatelessWidget {
  const _Recuadro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// Familias

class _PanelFamilias extends ConsumerWidget {
  const _PanelFamilias({
    required this.seleccion,
    required this.busqueda,
    required this.onBuscar,
    required this.onAlternar,
  });

  final Set<int> seleccion;
  final String busqueda;
  final ValueChanged<String> onBuscar;
  final ValueChanged<int> onAlternar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familias = ref.watch(familiasProvider(_soloActivas));

    return _Recuadro(
      // Con el teclado abierto en el telefono, el titulo y el buscador no
      // dejan lugar a la lista.
      child: CabezaYLista(
        altoCompacto: 300,
        cabeza: [
          Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Elija las familias de los artículos',
                  style: context.tituloSeccion(),
                ),
                const SizedBox(height: Esp.s),
                BuscadorPropuesta(
                  texto: busqueda,
                  pista: 'Código, grupo o proveedor',
                  alCambiar: onBuscar,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        lista: familias.when(
          loading: () => const EsqueletoLista(altoFila: 48),
          error:
              (e, _) => MensajeError(
                error: e,
                onReintentar:
                    () => ref.invalidate(familiasProvider(_soloActivas)),
              ),
          data: (crudas) {
            final texto = busqueda.trim().toLowerCase();
            final lista =
                crudas
                    .map(FamiliaVista.deMapa)
                    .where(
                      (f) => texto.isEmpty || f.textoBuscable.contains(texto),
                    )
                    .toList()
                  // Las elegidas arriba: son las que se estan usando.
                  ..sort((a, b) {
                    final ea = seleccion.contains(a.codigoFamilia) ? 0 : 1;
                    final eb = seleccion.contains(b.codigoFamilia) ? 0 : 1;
                    return ea != eb
                        ? ea - eb
                        : a.codigoFamilia.compareTo(b.codigoFamilia);
                  });
            if (lista.isEmpty) {
              return const MensajeVacio(
                icono: Icons.search_off,
                titulo: 'Ninguna familia coincide',
                detalle: 'Pruebe con otro código o texto.',
              );
            }
            return ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final f = lista[i];
                return CheckboxListTile(
                  dense: true,
                  value: seleccion.contains(f.codigoFamilia),
                  onChanged: (_) => onAlternar(f.codigoFamilia),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Familia ${f.codigoFamilia}',
                    style: context.numero(fuerte: true),
                  ),
                  subtitle: Text(
                    f.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Artículos para agregar

class _PanelArticulos extends ConsumerWidget {
  const _PanelArticulos({
    required this.familias,
    required this.elegidos,
    required this.yaEstan,
    required this.busqueda,
    required this.compacto,
    required this.ocupado,
    required this.onBuscar,
    required this.onAlternar,
    required this.onTodos,
    required this.onAgregar,
    required this.onIrAFamilias,
  });

  final Set<int> familias;
  final Set<String> elegidos;

  /// Codigos en mayusculas de los que ya estan en la propuesta.
  final Set<String> yaEstan;
  final String busqueda;
  final bool compacto;
  final bool ocupado;
  final ValueChanged<String> onBuscar;
  final ValueChanged<String> onAlternar;
  final void Function(Iterable<String> codigos, bool marcar) onTodos;
  final VoidCallback onAgregar;

  /// Null en escritorio, donde las familias ya estan a la vista.
  final VoidCallback? onIrAFamilias;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (familias.isEmpty) {
      return _Recuadro(
        child: Column(
          children: [
            const Expanded(
              child: MensajeVacio(
                icono: Icons.checklist,
                titulo: 'Elija primero una o más familias',
                detalle:
                    'Los artículos se buscan dentro de las familias elegidas.',
              ),
            ),
            if (onIrAFamilias != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.l),
                child: FilledButton.tonalIcon(
                  onPressed: onIrAFamilias,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Elegir familias'),
                ),
              ),
          ],
        ),
      );
    }

    final articulos = ref.watch(
      articulosPorFamiliasProvider(ClaveFamilias(familias.toList())),
    );

    return _Recuadro(
      child: articulos.when(
        loading: () => const EsqueletoLista(altoFila: 56),
        error:
            (e, _) => MensajeError(
              error: e,
              onReintentar: () => ref.invalidate(articulosPorFamiliasProvider),
            ),
        data: (todos) {
          final texto = busqueda.trim().toLowerCase();
          final visibles = [
            for (final a in todos)
              if (texto.isEmpty ||
                  '${a.codArticulo} ${a.datoArt} ${a.codigoFamilia}'
                      .toLowerCase()
                      .contains(texto))
                a,
          ];
          final disponibles = [
            for (final a in visibles)
              if (!yaEstan.contains(a.codArticulo.trim().toUpperCase()))
                a.codArticulo,
          ];
          final todosMarcados =
              disponibles.isNotEmpty && disponibles.every(elegidos.contains);

          return CabezaYLista(
            altoCompacto: 300,
            cabeza: [
              Padding(
                padding: const EdgeInsets.all(Esp.m),
                child: Row(
                  children: [
                    Expanded(
                      child: BuscadorPropuesta(
                        texto: busqueda,
                        pista: 'Código o descripción',
                        alCambiar: onBuscar,
                      ),
                    ),
                    const SizedBox(width: Esp.s),
                    Tooltip(
                      message:
                          todosMarcados
                              ? 'Desmarcar los visibles'
                              : 'Marcar los visibles',
                      child: Checkbox(
                        value: todosMarcados,
                        onChanged:
                            disponibles.isEmpty
                                ? null
                                : (_) => onTodos(disponibles, !todosMarcados),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            lista:
                visibles.isEmpty
                    ? MensajeVacio(
                      icono: Icons.search_off,
                      titulo:
                          todos.isEmpty
                              ? 'Esas familias no tienen artículos'
                              : 'Ningún artículo coincide',
                      detalle:
                          todos.isEmpty
                              ? 'Si el artículo se creó hace poco en SAP, '
                                  'use "Actualizar desde SAP".'
                              : 'Hay ${todos.length} artículos en las '
                                  'familias elegidas.',
                    )
                    : ListView.builder(
                      itemCount: visibles.length,
                      itemBuilder:
                          (context, i) => _FilaArticulo(
                            articulo: visibles[i],
                            yaEsta: yaEstan.contains(
                              visibles[i].codArticulo.trim().toUpperCase(),
                            ),
                            elegido: elegidos.contains(visibles[i].codArticulo),
                            onAlternar:
                                () => onAlternar(visibles[i].codArticulo),
                          ),
                    ),
            pie: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(Esp.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${visibles.length} de ${todos.length} artículos · '
                          '${elegidos.length} '
                          '${elegidos.length == 1 ? 'marcado' : 'marcados'}',
                          style: context.apagado(),
                        ),
                      ),
                      BotonAccion(
                        etiqueta:
                            elegidos.isEmpty
                                ? 'Agregar'
                                : 'Agregar ${elegidos.length}',
                        etiquetaOcupado: 'Agregando',
                        icono: Icons.playlist_add,
                        ocupado: ocupado,
                        onPressed: elegidos.isEmpty ? null : onAgregar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilaArticulo extends StatelessWidget {
  const _FilaArticulo({
    required this.articulo,
    required this.yaEsta,
    required this.elegido,
    required this.onAlternar,
  });

  final ArticuloPrecioEntity articulo;
  final bool yaEsta;
  final bool elegido;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context) {
    final detalle = [
      'Familia ${articulo.codigoFamilia}',
      'Stock ${fmtCantidad.format(articulo.stock)}',
      'UTM ${_fmtUtm.format(articulo.utm)}',
    ].join(' · ');

    return CheckboxListTile(
      dense: true,
      value: yaEsta || elegido,
      onChanged: yaEsta ? null : (_) => onAlternar(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(articulo.codArticulo, style: context.numero(fuerte: true)),
      subtitle: Text(
        '${articulo.datoArt.trim().isEmpty ? 'Sin descripción' : articulo.datoArt.trim()}\n$detalle',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      secondary:
          yaEsta
              ? const Etiqueta(texto: 'Ya está', tono: TonoEtiqueta.exito)
              : null,
    );
  }
}

// Artículos ya en la propuesta

class _PanelEnPropuesta extends StatelessWidget {
  const _PanelEnPropuesta({
    required this.articulos,
    required this.ocupado,
    required this.onQuitar,
  });

  final AsyncValue<List<ArticuloPropuestoEntity>> articulos;
  final bool ocupado;
  final ValueChanged<ArticuloPropuestoEntity> onQuitar;

  @override
  Widget build(BuildContext context) {
    return _Recuadro(
      child: articulos.when(
        loading: () => const EsqueletoLista(altoFila: 56),
        error: (e, _) => MensajeError(error: e),
        data: (lista) {
          if (lista.isEmpty) {
            return const MensajeVacio(
              icono: Icons.inventory_2_outlined,
              titulo: 'Todavía no hay artículos en la propuesta',
              detalle:
                  'Marque artículos en "Para agregar". La propuesta se crea '
                  'con el primero que se agrega.',
            );
          }
          final ordenados = [...lista]
            ..sort((a, b) => a.codArticulo.compareTo(b.codArticulo));
          return ListView.separated(
            itemCount: ordenados.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = ordenados[i];
              return ListTile(
                dense: true,
                title: Text(a.codArticulo, style: context.numero(fuerte: true)),
                subtitle: Text(
                  '${a.datoArticulo.trim().isEmpty ? 'Sin descripción' : a.datoArticulo.trim()}'
                  ' · Familia ${a.codigoFamilia}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Quitar de la propuesta',
                  onPressed: ocupado ? null : () => onQuitar(a),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
