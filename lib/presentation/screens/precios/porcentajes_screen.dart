/// Porcentajes por familia y lista de precios (`tpr_porcentaje`): el margen sobre
/// el costo que arma cada precio de venta. Sin porcentaje, la familia no tiene
/// precio en esa lista. Reemplaza a dlgPorcen (*Por familia*) y dlgPorcGrupo
/// (*Por grupo SAP*, edición masiva) de `Autorizacion.xhtml`.
///
/// El sistema anterior decía validar porcentajes ascendentes por sucursal, pero
/// `validaPorcentaje()` devolvía siempre 0 (hay datos viejos con choques). Aquí
/// `validarPorcentajesAscendentes` los muestra mientras se escribe y bloquea el
/// guardado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/aviso_listas_inactivas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/selector_familia_porcentaje.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_familias_grupo.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_porcentajes.dart';

// Estado local de la pantalla: vive aquí y no en `precios_provider.dart` porque es
// de ESTA pantalla. Todos son autoDispose: una familia elegida no reaparece en la
// siguiente visita.

/// La familia que se esta editando en la primera pestania.
final _familiaProvider = StateProvider.autoDispose<int?>((ref) => null);

/// El grupo de familia SAP de la edicion masiva.
final _grupoProvider = StateProvider.autoDispose<BigInt?>((ref) => null);

/// El catálogo de familias, convertido y ordenado por código. Se pide sin filtro:
/// el buscador trabaja del lado del cliente (por código y descripción) y el
/// procedimiento solo filtra por igualdad exacta de código o id de catálogo.
final _catalogoFamiliasProvider =
    FutureProvider.autoDispose<List<FamiliaVista>>((ref) async {
      final crudas = await ref.watch(
        familiasProvider(const FiltroFamilias()).future,
      );
      return crudas.map(FamiliaVista.deMapa).toList()
        ..sort((a, b) => a.codigoFamilia.compareTo(b.codigoFamilia));
    });

/// La grilla de una familia: una fila por sucursal y lista de precios.
final _filasFamiliaProvider = FutureProvider.autoDispose
    .family<List<FilaPorcentaje>, int>((ref, codigoFamilia) async {
      final crudas = await ref.watch(
        porcentajesPorFamiliaProvider(codigoFamilia).future,
      );
      return crudas.map(FilaPorcentaje.deMapa).toList()
        ..sort(FilaPorcentaje.comparar);
    });

/// Los destinos de la edición masiva: las listas de precios activas, con el
/// margen en cero. El backend NO ordena esta rama; el orden lo pone
/// [FilaPorcentaje.comparar].
final _destinosGrupoProvider = FutureProvider.autoDispose
    .family<List<FilaPorcentaje>, BigInt>((ref, idGrpFamiliaSap) async {
      final crudas = await ref.watch(
        destinosPorcentajeGrupoProvider(idGrpFamiliaSap).future,
      );
      return crudas.map(FilaPorcentaje.deMapa).toList()
        ..sort(FilaPorcentaje.comparar);
    });

/// La tabla `tpr_porcentaje` entera, indexada de dos formas. La rama 'I' del alta
/// inserta siempre (no es un upsert): sin el idPorcen de cada par (familia,
/// lista), que la grilla de destinos no trae, la edición masiva dejaría DOS filas
/// por lista. Se lee UNA vez sin filtros (7.836 filas) en vez de una consulta por
/// familia, y solo con un grupo elegido: es la lectura más cara del módulo.
final _tablaPorcentajesProvider = FutureProvider.autoDispose<_TablaPorcentajes>(
  (ref) async {
    final filas = await ref.watch(
      porcentajesProvider(const FiltroPorcentajes()).future,
    );

    final ids = <String, BigInt>{};
    final valores = <String, double>{};
    final porFamilia = <int, List<double>>{};
    for (final p in filas) {
      final clave = _clave(p.codigoFamilia, p.idClasificacion);
      ids[clave] = p.idPorcen;
      valores[clave] = p.porcen;
      (porFamilia[p.codigoFamilia] ??= <double>[]).add(p.porcen);
    }
    return _TablaPorcentajes(
      ids: ids,
      valores: valores,
      porFamilia: porFamilia,
    );
  },
);

/// Las familias de un grupo, con lo que hoy tienen cargado.
final _familiasGrupoProvider = FutureProvider.autoDispose
    .family<List<FamiliaGrupoVista>, BigInt>((ref, idGrpFamiliaSap) async {
      final crudas = await ref.watch(
        familiasPorGrupoProvider(idGrpFamiliaSap).future,
      );
      final tabla = await ref.watch(_tablaPorcentajesProvider.future);

      final familias = [
        for (final f in crudas)
          FamiliaGrupoVista(
            codigoFamilia: entero(f['codigoFamilia']),
            proveedor: texto(f['proveedorExtSap']),
            grupo: texto(f['grpFam']),
            porcentajesActuales:
                tabla.porFamilia[entero(f['codigoFamilia'])] ??
                const <double>[],
          ),
      ];
      familias.sort((a, b) => a.codigoFamilia.compareTo(b.codigoFamilia));
      return familias;
    });

/// Lo que devuelve [_tablaPorcentajesProvider].
@immutable
class _TablaPorcentajes {
  const _TablaPorcentajes({
    required this.ids,
    required this.valores,
    required this.porFamilia,
  });

  /// idPorcen por par (familia, lista). Ausente = todavia no existe la fila.
  final Map<String, BigInt> ids;

  /// El margen de hoy por par (familia, lista), para "copiar de una familia".
  final Map<String, double> valores;

  /// Los margenes que cada familia tiene hoy, sin ordenar.
  final Map<int, List<double>> porFamilia;

  /// El idPorcen de un par, o cero cuando la fila no existe: cero es
  /// exactamente lo que el procedimiento interpreta como alta.
  BigInt idDe(int codigoFamilia, BigInt idClasificacion) =>
      ids[_clave(codigoFamilia, idClasificacion)] ?? BigInt.zero;

  /// El margen que la familia tiene hoy en esa lista; null si no tiene fila.
  double? valorDe(int codigoFamilia, BigInt idClasificacion) =>
      valores[_clave(codigoFamilia, idClasificacion)];
}

String _clave(int codigoFamilia, BigInt idClasificacion) =>
    '$codigoFamilia|$idClasificacion';

// La pantalla

class PorcentajesScreen extends ConsumerWidget {
  const PorcentajesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho del CAJON, no el de la ventana.
        final aire = Aire.de(cajon.maxWidth);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Encabezado(aire: aire),
                  Builder(
                    builder:
                        (context) => _SelectorModo(
                          controlador: DefaultTabController.of(context),
                          aire: aire,
                        ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PanelFamilia(aire: aire),
                        _PanelGrupo(aire: aire),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final compacto = aire.esChico;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compacto ? Esp.m : Esp.xl,
        Esp.l,
        compacto ? Esp.m : Esp.xl,
        Esp.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porcentajes',
            style: tt.titleLarge?.copyWith(
              fontWeight: Peso.dato,
              letterSpacing: -0.4,
            ),
          ),
          // En el telefono la bajada se come un tercio del alto util de la
          // primera pantalla; en escritorio explica de que se trata.
          if (!compacto)
            Text(
              'El margen sobre el costo de cada familia en cada lista de '
              'precio. Dentro de una sucursal, el porcentaje no puede bajar al '
              'subir el número de lista.',
              style: context.apagado(),
            ),
        ],
      ),
    );
  }
}

/// Los dos modos de la pantalla, con lo que hace cada uno.
const _modos = [
  (
    titulo: 'Por familia',
    detalle:
        'Una familia: vea y cambie el porcentaje de cada una de sus listas.',
    icono: Icons.inventory_2_outlined,
  ),
  (
    titulo: 'Por grupo SAP',
    detalle:
        'Varias familias de un grupo: póngales los mismos porcentajes a las '
        'que elija.',
    icono: Icons.account_tree_outlined,
  ),
];

/// Reemplaza a la barra de pestanias: dos tarjetas que dicen para que sirve
/// cada modo. En el telefono, dos segmentos y la explicacion del elegido.
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({required this.controlador, required this.aire});

  final TabController controlador;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final margen = aire.esChico ? Esp.m : Esp.xl;
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) {
        final actual = controlador.index;
        if (aire.esChico) {
          return Padding(
            padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final (i, m) in _modos.indexed)
                      ButtonSegment(
                        value: i,
                        icon: Icon(m.icono, size: 18),
                        label: Text(m.titulo),
                      ),
                  ],
                  selected: {actual},
                  onSelectionChanged: (s) => controlador.animateTo(s.first),
                ),
                const SizedBox(height: Esp.xs),
                Text(_modos[actual].detalle, style: context.apagado()),
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
          child: Row(
            children: [
              for (final (i, m) in _modos.indexed) ...[
                if (i > 0) const SizedBox(width: Esp.m),
                Expanded(
                  child: _TarjetaModo(
                    titulo: m.titulo,
                    detalle: m.detalle,
                    icono: m.icono,
                    elegido: i == actual,
                    onTap: () => controlador.animateTo(i),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaModo extends StatelessWidget {
  const _TarjetaModo({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.elegido,
    required this.onTap,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: elegido ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(
          color: elegido ? cs.primary : cs.outlineVariant,
          width: elegido ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: elegido ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  size: 20,
                  color: elegido ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: Peso.dato,
                        color: elegido ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    Text(
                      detalle,
                      style: tt.bodySmall?.copyWith(
                        color:
                            elegido
                                ? cs.onPrimaryContainer.withValues(alpha: 0.85)
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (elegido)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// El numero de un paso, en un circulo del color principal.
class _NumeroPaso extends StatelessWidget {
  const _NumeroPaso(this.numero);

  final int numero;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      child: Text(
        '$numero',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.onPrimary,
          fontWeight: Peso.dato,
        ),
      ),
    );
  }
}

// Pestaña 1: por familia (dlgPorcen)

class _PanelFamilia extends ConsumerStatefulWidget {
  const _PanelFamilia({required this.aire});

  final Aire aire;

  @override
  ConsumerState<_PanelFamilia> createState() => _PanelFamiliaState();
}

class _PanelFamiliaState extends ConsumerState<_PanelFamilia>
    with AutomaticKeepAliveClientMixin {
  /// Lo escrito en cada campo, por idClasificacion. Ausente = sin tocar; null =
  /// lo escrito no es un numero.
  final Map<BigInt, double?> _editado = {};

  bool _guardando = false;

  /// El panel se mantiene vivo al cambiar de pestania: sin esto, ir a la
  /// edicion masiva y volver borraria lo que se estaba editando sin avisar.
  @override
  bool get wantKeepAlive => true;

  double? _valorDe(FilaPorcentaje fila) =>
      _editado.containsKey(fila.idClasificacion)
          ? _editado[fila.idClasificacion]
          : fila.porcen;

  List<FilaPorcentaje> _cambiadas(List<FilaPorcentaje> filas) => [
    for (final f in filas)
      if (_valorDe(f) != null && !mismoPorcentaje(_valorDe(f)!, f.porcen)) f,
  ];

  Future<void> _elegirFamilia() async {
    final asyncCatalogo = ref.read(_catalogoFamiliasProvider);
    if (asyncCatalogo.hasError && !asyncCatalogo.isLoading) {
      // Vuelve a pedirlo: sin esto el boton no tenia como reintentar.
      ref.invalidate(familiasProvider(const FiltroFamilias()));
      mostrarAviso(
        context,
        'No se pudo cargar el catálogo de familias. Se vuelve a pedir: '
        'intente de nuevo en unos segundos.',
        tono: TonoAviso.error,
      );
      return;
    }
    final catalogo = asyncCatalogo.valueOrNull;
    if (catalogo == null || catalogo.isEmpty) {
      mostrarAviso(
        context,
        'El catálogo de familias todavía se está cargando.',
        tono: TonoAviso.aviso,
      );
      return;
    }

    final elegida = await elegirFamiliaPorcentaje(
      context,
      familias: catalogo,
      compacto: widget.aire.esChico,
      seleccionada: ref.read(_familiaProvider),
    );
    if (elegida == null || !mounted) return;
    ref.read(_familiaProvider.notifier).state = elegida.codigoFamilia;
  }

  Future<void> _guardar(int codigoFamilia, List<FilaPorcentaje> filas) async {
    final cambiadas = _cambiadas(filas);
    if (cambiadas.isEmpty) {
      mostrarAviso(
        context,
        'No hay cambios para guardar.',
        tono: TonoAviso.aviso,
      );
      return;
    }

    // Se valida sobre la grilla COMPLETA y no sobre lo que cambió: la regla compara
    // cada lista con la anterior de su sucursal, que puede ser una fila que nadie tocó.
    final conflictos = validarPorcentajesAscendentes([
      for (final f in filas)
        if (_valorDe(f) != null) f.aMapa(_valorDe(f)!),
    ]);
    if (conflictos.isNotEmpty) {
      mostrarAviso(
        context,
        'Los porcentajes tienen que ser ascendentes por sucursal. '
        'No se guardó ninguna fila.',
        tono: TonoAviso.error,
      );
      return;
    }

    setState(() => _guardando = true);
    final ok = await ref
        .read(porcentajesNotifierProvider.notifier)
        .guardarGrilla(
          codigoFamilia: codigoFamilia,
          filas: [for (final f in cambiadas) f.aMapa(_valorDe(f)!)],
        );
    if (!mounted) return;

    final estado = ref.read(porcentajesNotifierProvider);
    setState(() {
      _guardando = false;
      // Solo se limpia si entró todo: con un guardado a medias, lo escrito ya viene en
      // la lectura refrescada y el resto sigue en pantalla para reintentar.
      if (ok) _editado.clear();
    });

    if (ok) {
      mostrarAviso(
        context,
        estado.filasEscritas == 1
            ? 'Se guardó 1 porcentaje.'
            : 'Se guardaron ${estado.filasEscritas} porcentajes.',
      );
      return;
    }

    // El backend no tiene escritura masiva: cada fila viaja sola y un fallo a mitad
    // deja las anteriores guardadas. Decir "error" a secas haría creer que no se
    // escribió nada.
    final parcial =
        estado.guardadoParcial
            ? 'Se guardaron ${estado.filasEscritas} de '
                '${estado.filasPedidas} filas. '
            : '';
    mostrarAviso(
      context,
      '$parcial${estado.error ?? 'No se pudieron guardar los porcentajes.'}',
      tono: TonoAviso.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Cambiar de familia descarta lo escrito: es de la familia anterior y aplicarlo
    // a otra escribiría márgenes en el producto equivocado.
    ref.listen<int?>(_familiaProvider, (_, __) => _editado.clear());

    final codigoFamilia = ref.watch(_familiaProvider);
    final catalogo = ref.watch(_catalogoFamiliasProvider);
    final margen = widget.aire.esChico ? Esp.m : Esp.xl;

    final familia = _buscarFamilia(catalogo.valueOrNull, codigoFamilia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BarraFamilia(
          aire: widget.aire,
          margen: margen,
          familia: familia,
          codigoFamilia: codigoFamilia,
          cargandoCatalogo: catalogo.isLoading,
          onElegir: _guardando ? null : _elegirFamilia,
          onRefrescar:
              codigoFamilia == null
                  ? null
                  : () {
                    _editado.clear();
                    ref.invalidate(porcentajesPorFamiliaProvider);
                  },
        ),
        const Divider(height: 1),
        Expanded(
          child:
              codigoFamilia == null
                  ? MensajeVacio(
                    icono: Icons.percent,
                    titulo: 'Elija una familia',
                    detalle:
                        catalogo.hasError
                            ? 'El catálogo de familias no se pudo cargar: '
                                'vuelva a intentarlo desde el botón Elegir '
                                'familia.'
                            : 'Va a ver su margen en cada sucursal y lista de '
                                'precio, y va a poder editarlos todos juntos.',
                  )
                  : _GrillaFamilia(
                    codigoFamilia: codigoFamilia,
                    aire: widget.aire,
                    margen: margen,
                    valorDe: _valorDe,
                    editado: _editado,
                    guardando: _guardando,
                    onCambio:
                        (id, valor) => setState(() => _editado[id] = valor),
                    onGuardar: (filas) => _guardar(codigoFamilia, filas),
                    cambiadas: _cambiadas,
                  ),
        ),
      ],
    );
  }

  /// La familia elegida dentro del catalogo ya traido. Null cuando todavia no
  /// se eligio ninguna o el catalogo no llego.
  static FamiliaVista? _buscarFamilia(
    List<FamiliaVista>? catalogo,
    int? codigoFamilia,
  ) {
    if (catalogo == null || codigoFamilia == null) return null;
    for (final f in catalogo) {
      if (f.codigoFamilia == codigoFamilia) return f;
    }
    return null;
  }
}

/// La barra de la primera pestania: que familia se esta editando y con que
/// botones se cambia.
class _BarraFamilia extends StatelessWidget {
  const _BarraFamilia({
    required this.aire,
    required this.margen,
    required this.familia,
    required this.codigoFamilia,
    required this.cargandoCatalogo,
    required this.onElegir,
    required this.onRefrescar,
  });

  final Aire aire;
  final double margen;
  final FamiliaVista? familia;
  final int? codigoFamilia;
  final bool cargandoCatalogo;
  final VoidCallback? onElegir;
  final VoidCallback? onRefrescar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final titulo =
        familia != null
            ? 'Familia ${familia!.codigoLegible}'
            : codigoFamilia != null
            ? 'Familia $codigoFamilia'
            : 'Ninguna familia elegida';
    final detalle =
        familia?.descripcion ??
        (cargandoCatalogo
            ? 'Cargando el catálogo de familias…'
            : 'Elija una para ver sus porcentajes.');

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                ),
                Text(
                  detalle,
                  style: context.apagado(),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRefrescar != null)
            IconButton(
              tooltip: 'Actualizar',
              onPressed: onRefrescar,
              icon: const Icon(Icons.refresh),
            ),
          const SizedBox(width: Esp.xs),
          // En el telefono el boton es solo el icono: el rotulo se come el
          // ancho que necesita el nombre de la familia.
          if (aire.esChico)
            IconButton.filled(
              tooltip: 'Elegir familia',
              onPressed: onElegir,
              icon: const Icon(Icons.search),
            )
          else
            FilledButton.icon(
              onPressed: onElegir,
              icon: const Icon(Icons.search),
              label: const Text('Elegir familia'),
            ),
        ],
      ),
    );
  }
}

/// La grilla de una familia, con su validacion en vivo y el boton de guardar.
class _GrillaFamilia extends ConsumerWidget {
  const _GrillaFamilia({
    required this.codigoFamilia,
    required this.aire,
    required this.margen,
    required this.valorDe,
    required this.editado,
    required this.guardando,
    required this.onCambio,
    required this.onGuardar,
    required this.cambiadas,
  });

  final int codigoFamilia;
  final Aire aire;
  final double margen;
  final double? Function(FilaPorcentaje) valorDe;
  final Map<BigInt, double?> editado;
  final bool guardando;
  final void Function(BigInt, double?) onCambio;
  final void Function(List<FilaPorcentaje>) onGuardar;
  final List<FilaPorcentaje> Function(List<FilaPorcentaje>) cambiadas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFilas = ref.watch(_filasFamiliaProvider(codigoFamilia));

    return asyncFilas.when(
      loading: () => const EsqueletoLista(filas: 6, altoFila: 56),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(porcentajesPorFamiliaProvider),
          ),
      data: (filas) {
        if (filas.isEmpty) {
          return const MensajeVacio(
            icono: Icons.price_change_outlined,
            titulo: 'Esta familia no tiene listas de precio',
            detalle:
                'El listado de porcentajes sale del cruce con los precios '
                'cargados: una familia sin precios en ninguna lista todavía '
                'no tiene dónde aplicar un margen.',
          );
        }

        final hayInvalidos = filas.any((f) => valorDe(f) == null);
        final pendientes = filas.where((f) => f.esAlta).length;
        final cambios = cambiadas(filas);

        // La validación corre en cada tecla, no solo al guardar: enterarse tarde de que
        // la serie quedó mal obliga a rehacer el razonamiento.
        final conflictos =
            hayInvalidos
                ? const <ConflictoPorcentaje>[]
                : validarPorcentajesAscendentes([
                  for (final f in filas) f.aMapa(valorDe(f)!),
                ]);
        final clavesEnConflicto = {
          for (final c in conflictos)
            FilaPorcentaje.claveDeConflicto(
              c.codSucursal.toInt(),
              c.nombrePrecio,
            ),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumenFamilia(
                      total: filas.length,
                      pendientes: pendientes,
                      cambios: cambios.length,
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      'Escriba el porcentaje nuevo en cada lista: lo cambiado '
                      'se marca en color, con el valor de antes debajo. '
                      'Guardar escribe solo lo cambiado.',
                      style: context.apagado(),
                    ),
                    const AvisoListasInactivas(),
                    if (conflictos.isNotEmpty)
                      NotaDelDato(
                        tono: TonoNota.error,
                        texto:
                            'El porcentaje no puede bajar al subir el número '
                            'de lista dentro de una misma sucursal. '
                            '${conflictos.length == 1 ? 'Hay 1 caso' : 'Hay ${conflictos.length} casos'}:\n'
                            '${conflictos.map((c) => '• ${c.mensaje}').join('\n')}',
                      ),
                    if (hayInvalidos)
                      const NotaDelDato(
                        tono: TonoNota.aviso,
                        texto:
                            'Hay un campo que no es un número. Corríjalo para '
                            'poder guardar.',
                      ),
                    const SizedBox(height: Esp.m),
                    TablaPorcentajes(
                      filas: filas,
                      valores: editado,
                      habilitado: !guardando,
                      clavesEnConflicto: clavesEnConflicto,
                      onCambio: onCambio,
                    ),
                  ],
                ),
              ),
            ),
            _BarraGuardar(
              margen: margen,
              children: [
                if (cambios.isNotEmpty)
                  Text(
                    cambios.length == 1
                        ? '1 cambio sin guardar'
                        : '${cambios.length} cambios sin guardar',
                    style: context.apagado(),
                  ),
                const Spacer(),
                BotonAccion(
                  etiqueta:
                      cambios.isEmpty ? 'Guardar' : 'Guardar ${cambios.length}',
                  etiquetaOcupado: 'Guardando…',
                  icono: Icons.save_outlined,
                  ocupado: guardando,
                  onPressed:
                      cambios.isEmpty || hayInvalidos || conflictos.isNotEmpty
                          ? null
                          : () => onGuardar(filas),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ResumenFamilia extends StatelessWidget {
  const _ResumenFamilia({
    required this.total,
    required this.pendientes,
    required this.cambios,
  });

  final int total;
  final int pendientes;
  final int cambios;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      children: [
        Etiqueta(texto: '$total listas de precio'),
        if (pendientes > 0)
          Etiqueta(
            texto:
                pendientes == 1
                    ? '1 sin porcentaje cargado'
                    : '$pendientes sin porcentaje cargado',
            tono: TonoEtiqueta.aviso,
          ),
        if (cambios > 0)
          Etiqueta(
            texto: cambios == 1 ? '1 cambio' : '$cambios cambios',
            tono: TonoEtiqueta.exito,
          ),
      ],
    );
  }
}

/// La barra fija de abajo con la acción que escribe. Va pegada al borde inferior
/// y no al final del scroll: con doce listas la grilla no entra en un teléfono y
/// un botón de guardar que hay que ir a buscar no se usa.
class _BarraGuardar extends StatelessWidget {
  const _BarraGuardar({required this.margen, required this.children});

  final double margen;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.s),
      child: SafeArea(top: false, child: Row(children: children)),
    );
  }
}

// Pestaña 2: por grupo de familia SAP (dlgPorcGrupo)

class _PanelGrupo extends ConsumerStatefulWidget {
  const _PanelGrupo({required this.aire});

  final Aire aire;

  @override
  ConsumerState<_PanelGrupo> createState() => _PanelGrupoState();
}

class _PanelGrupoState extends ConsumerState<_PanelGrupo>
    with AutomaticKeepAliveClientMixin {
  /// El margen a aplicar en cada lista de precios. Ausente = el que trajo la
  /// grilla (cero); null = lo escrito no es un numero.
  final Map<BigInt, double?> _valores = {};

  /// Las familias que NO se van a tocar: el tilde de la tabla incluye y este
  /// conjunto guarda las desmarcadas.
  final Set<int> _excluidas = {};

  String _busqueda = '';
  bool _aplicando = false;
  bool _cancelar = false;

  /// Cuantas familias se escribieron ya en la aplicacion en curso.
  int _hechas = 0;
  int _aHacer = 0;

  @override
  bool get wantKeepAlive => true;

  /// Salir de la pantalla corta la aplicacion en curso: sin esto el bucle
  /// seguia escribiendo familias que ya nadie estaba mirando.
  @override
  void dispose() {
    _cancelar = true;
    super.dispose();
  }

  double? _valorDe(FilaPorcentaje fila) =>
      _valores.containsKey(fila.idClasificacion)
          ? _valores[fila.idClasificacion]
          : fila.porcen;

  /// Pone el mismo margen en todas las listas. El caso real es "a todo el grupo,
  /// 15 %" y cargarlo lista por lista en doce filas es donde se equivoca la mano.
  Future<void> _igualarTodas(List<FilaPorcentaje> destinos) async {
    final valor = await _pedirValor();
    if (valor == null || !mounted) return;
    setState(() {
      for (final d in destinos) {
        _valores[d.idClasificacion] = valor;
      }
    });
  }

  /// Llena la grilla con los márgenes que hoy tiene una familia del grupo: el caso
  /// común es "que todas queden como la 12601".
  void _copiarDe(
    FamiliaGrupoVista familia,
    List<FilaPorcentaje> destinos,
    _TablaPorcentajes tabla,
  ) {
    var copiadas = 0;
    setState(() {
      for (final d in destinos) {
        final v = tabla.valorDe(familia.codigoFamilia, d.idClasificacion);
        if (v == null) continue;
        _valores[d.idClasificacion] = v;
        copiadas++;
      }
    });
    final faltan = destinos.length - copiadas;
    mostrarAviso(
      context,
      copiadas == 0
          ? 'La familia ${familia.codigoLegible} no tiene porcentajes cargados: '
              'no hay nada que copiar.'
          : 'Se copiaron los porcentajes de la familia ${familia.codigoLegible}'
              '${faltan == 0 ? '' : '; ${faltan == 1 ? '1 lista quedó' : '$faltan listas quedaron'} como estaba${faltan == 1 ? '' : 'n'} porque la familia no tiene porcentaje ahí'}.',
      tono: copiadas == 0 ? TonoAviso.aviso : TonoAviso.exito,
    );
  }

  Future<double?> _pedirValor() => showDialog<double>(
    context: context,
    builder: (_) => const _DialogoIgualar(),
  );

  /// Escribe el margen de la grilla en todas las familias no excluidas.
  ///
  /// No usa `PorcentajesNotifier.guardarGrilla`: invalida la tabla entera y por
  /// familia releería 7.836 filas; aquí se invalida UNA vez al final. No es
  /// atómico: el backend no tiene escritura masiva, así que si una falla las
  /// anteriores ya quedaron guardadas: se corta en la primera y se informa
  /// cuántas familias entraron.
  Future<void> _aplicar({
    required BigInt idGrupo,
    required String nombreGrupo,
    required List<FilaPorcentaje> destinos,
    required List<FamiliaGrupoVista> familias,
    required _TablaPorcentajes tabla,
  }) async {
    final alcanzadas = [
      for (final f in familias)
        if (!_excluidas.contains(f.codigoFamilia)) f,
    ];

    if (alcanzadas.isEmpty) {
      mostrarAviso(
        context,
        'Todas las familias del grupo están excluidas: no hay nada que '
        'aplicar.',
        tono: TonoAviso.aviso,
      );
      return;
    }

    final conflictos = validarPorcentajesAscendentes([
      for (final d in destinos)
        if (_valorDe(d) != null) d.aMapa(_valorDe(d)!),
    ]);
    if (conflictos.isNotEmpty) {
      mostrarAviso(
        context,
        'Los porcentajes tienen que ser ascendentes por sucursal. '
        'No se escribió ninguna fila.',
        tono: TonoAviso.error,
      );
      return;
    }

    final escrituras = alcanzadas.length * destinos.length;
    var altas = 0;
    for (final f in alcanzadas) {
      for (final d in destinos) {
        if (tabla.idDe(f.codigoFamilia, d.idClasificacion) == BigInt.zero) {
          altas++;
        }
      }
    }

    final confirmado = await confirmar(
      context,
      titulo: 'Aplicar a todo el grupo',
      detalle:
          'Grupo: $nombreGrupo\n\n'
          '• ${alcanzadas.length} familia(s) afectada(s)\n'
          '• ${_excluidas.length} familia(s) excluida(s)\n'
          '• ${destinos.length} lista(s) de precio por familia\n'
          '• $escrituras escritura(s): $altas alta(s) y '
          '${escrituras - altas} modificación(es)\n\n'
          'Los precios de venta de todas esas familias se recalculan con el '
          'margen nuevo. El servidor no tiene escritura masiva: cada fila se '
          'escribe por separado, así que si algo falla a mitad de camino lo '
          'anterior queda guardado.',
      textoConfirmar: 'Aplicar',
      destructiva: true,
    );
    if (!confirmado || !mounted) return;

    // Se anota antes de empezar: al terminar bien las exclusiones se limpian,
    // y el aviso tiene que poder decir cuantas familias quedaron afuera.
    final excluidasAntes = _excluidas.length;

    setState(() {
      _aplicando = true;
      _cancelar = false;
      _hechas = 0;
      _aHacer = alcanzadas.length;
    });

    // El contenedor y no `ref`: si la pantalla se desmonta a mitad, `ref` lanza
    // y las invalidaciones de abajo se perdian.
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final repo = contenedor.read(preciosRepositoryProvider);
    String? error;
    var hechas = 0;
    // Filas escritas, no familias: si la primera falla a mitad, lo que ya entró debe
    // invalidar la tabla o un reintento lo daría de alta otra vez (el alta inserta
    // siempre).
    var filas = 0;

    for (final familia in alcanzadas) {
      if (_cancelar) break;
      try {
        for (final destino in destinos) {
          final valor = _valorDe(destino);
          if (valor == null) continue;
          await repo.registrarPorcentaje(
            porcentajeDesdeFila(
              destino.aMapa(
                valor,
                idPorcenForzado: tabla.idDe(
                  familia.codigoFamilia,
                  destino.idClasificacion,
                ),
              ),
              codigoFamilia: familia.codigoFamilia,
            ),
          );
          filas++;
        }
        hechas++;
        if (mounted) setState(() => _hechas = hechas);
      } catch (e) {
        error =
            'Familia ${familia.codigoLegible}: '
            '${e.toString().replaceFirst('Exception: ', '')}';
        break;
      }
    }

    // Lo escrito ya esta en la base: las lecturas del modulo que lo muestran
    // quedaron viejas aunque el bucle se haya cortado.
    if (filas > 0) {
      contenedor.invalidate(porcentajesPorFamiliaProvider);
      contenedor.invalidate(porcentajesFaltantesProvider);
      contenedor.invalidate(porcentajesProvider);
      contenedor.invalidate(preciosTonPorFamiliaProvider);
    }

    if (!mounted) return;
    final cancelado = _cancelar;
    setState(() {
      _aplicando = false;
      _cancelar = false;
      if (error == null && !cancelado) _excluidas.clear();
    });

    if (error != null) {
      mostrarAviso(
        context,
        'Se aplicó a $hechas de ${alcanzadas.length} familias y se cortó. '
        '$error',
        tono: TonoAviso.error,
      );
    } else if (cancelado) {
      mostrarAviso(
        context,
        'Cancelado. Quedaron aplicadas $hechas de ${alcanzadas.length} '
        'familias; las que ya se escribieron no se deshacen.',
        tono: TonoAviso.aviso,
      );
    } else {
      mostrarAviso(
        context,
        'Porcentajes aplicados a $hechas familia'
        '${hechas == 1 ? '' : 's'}'
        '${excluidasAntes == 0 ? '' : ', con $excluidasAntes excluida${excluidasAntes == 1 ? '' : 's'}'}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Cambiar de grupo descarta la grilla y las exclusiones: son de otro grupo.
    ref.listen<BigInt?>(_grupoProvider, (_, __) {
      _valores.clear();
      _excluidas.clear();
      _busqueda = '';
    });

    final idGrupo = ref.watch(_grupoProvider);
    final asyncGrupos = ref.watch(gruposFamiliaSapProvider);
    final margen = widget.aire.esChico ? Esp.m : Esp.xl;

    final combo = asyncGrupos.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(gruposFamiliaSapProvider),
          ),
      data:
          (grupos) => _ComboGrupo(
            grupos: grupos,
            valor: idGrupo,
            habilitado: !_aplicando,
            onElegir: (id) => ref.read(_grupoProvider.notifier).state = id,
          ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.m),
          child:
              widget.aire.esChico
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TituloPaso(
                        numero: 1,
                        titulo: 'Elija el grupo de familia SAP',
                      ),
                      const SizedBox(height: Esp.s),
                      combo,
                    ],
                  )
                  : Row(
                    children: [
                      const _TituloPaso(
                        numero: 1,
                        titulo: 'Elija el grupo de familia SAP',
                      ),
                      const SizedBox(width: Esp.l),
                      Expanded(child: combo),
                    ],
                  ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              idGrupo == null
                  ? const MensajeVacio(
                    icono: Icons.account_tree_outlined,
                    titulo: 'Elija un grupo de familia SAP',
                    detalle:
                        'Va a ver todas sus familias con el porcentaje que '
                        'tienen hoy, va a cargar el porcentaje nuevo por '
                        'lista de precio y va a poder dejar familias afuera '
                        'antes de aplicar.',
                  )
                  : _CuerpoGrupo(
                    idGrupo: idGrupo,
                    nombreGrupo: _nombreDe(asyncGrupos.valueOrNull, idGrupo),
                    aire: widget.aire,
                    margen: margen,
                    valores: _valores,
                    excluidas: _excluidas,
                    busqueda: _busqueda,
                    aplicando: _aplicando,
                    hechas: _hechas,
                    aHacer: _aHacer,
                    valorDe: _valorDe,
                    onCambio:
                        (id, valor) => setState(() => _valores[id] = valor),
                    onBusqueda: (t) => setState(() => _busqueda = t),
                    onAlternar:
                        (cod) => setState(() {
                          if (!_excluidas.remove(cod)) _excluidas.add(cod);
                        }),
                    onExcluirTodas:
                        (familias) => setState(() {
                          _excluidas
                            ..clear()
                            ..addAll(familias.map((f) => f.codigoFamilia));
                        }),
                    onIncluirTodas: () => setState(_excluidas.clear),
                    onIgualar: _igualarTodas,
                    onCopiar: _copiarDe,
                    onAplicar: _aplicar,
                    onCancelar: () => setState(() => _cancelar = true),
                  ),
        ),
      ],
    );
  }

  static String _nombreDe(List<GrupoFamiliaSapEntity>? grupos, BigInt idGrupo) {
    for (final g in grupos ?? const <GrupoFamiliaSapEntity>[]) {
      if (g.idGrpFamiliaSap == idGrupo) return g.nombreVisible;
    }
    return 'Grupo $idGrupo';
  }
}

/// Pide el margen para "Igualar todas". El controlador es del diálogo y no de
/// quien lo abre: el futuro de `showDialog` se completa al cerrar, no al terminar
/// la animación de salida, y liberarlo afuera dejaba al diálogo dibujándose con
/// un controlador liberado (errores en cascada).
class _DialogoIgualar extends StatefulWidget {
  const _DialogoIgualar();

  @override
  State<_DialogoIgualar> createState() => _DialogoIgualarState();
}

class _DialogoIgualarState extends State<_DialogoIgualar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Mismo porcentaje en todas las listas'),
    content: SizedBox(
      width: 280,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Porcentaje',
          suffixText: '%',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (t) => Navigator.pop(context, porcenDesdeTexto(t)),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, porcenDesdeTexto(_ctrl.text)),
        child: const Text('Aplicar a la grilla'),
      ),
    ],
  );
}

class _ComboGrupo extends StatelessWidget {
  const _ComboGrupo({
    required this.grupos,
    required this.valor,
    required this.habilitado,
    required this.onElegir,
  });

  final List<GrupoFamiliaSapEntity> grupos;
  final BigInt? valor;
  final bool habilitado;
  final ValueChanged<BigInt?> onElegir;

  @override
  Widget build(BuildContext context) {
    final ordenados = List<GrupoFamiliaSapEntity>.of(grupos)
      ..sort((a, b) => a.nombreVisible.compareTo(b.nombreVisible));

    return ComboBuscable<BigInt>(
      etiqueta: 'Grupo de familia SAP',
      valor: valor,
      pista: 'Escriba para buscar…',
      opciones: [
        for (final g in ordenados)
          DropdownMenuEntry<BigInt>(
            value: g.idGrpFamiliaSap,
            label: g.nombreVisible,
            enabled: habilitado,
          ),
      ],
      onElegir: onElegir,
    );
  }
}

/// El cuerpo de la edicion masiva: la grilla de destinos, la lista de familias
/// con sus exclusiones y el resumen de lo que se va a escribir.
class _CuerpoGrupo extends ConsumerWidget {
  const _CuerpoGrupo({
    required this.idGrupo,
    required this.nombreGrupo,
    required this.aire,
    required this.margen,
    required this.valores,
    required this.excluidas,
    required this.busqueda,
    required this.aplicando,
    required this.hechas,
    required this.aHacer,
    required this.valorDe,
    required this.onCambio,
    required this.onBusqueda,
    required this.onAlternar,
    required this.onExcluirTodas,
    required this.onIncluirTodas,
    required this.onIgualar,
    required this.onCopiar,
    required this.onAplicar,
    required this.onCancelar,
  });

  final BigInt idGrupo;
  final String nombreGrupo;
  final Aire aire;
  final double margen;
  final Map<BigInt, double?> valores;
  final Set<int> excluidas;
  final String busqueda;
  final bool aplicando;
  final int hechas;
  final int aHacer;
  final double? Function(FilaPorcentaje) valorDe;
  final void Function(BigInt, double?) onCambio;
  final ValueChanged<String> onBusqueda;
  final void Function(int codigoFamilia) onAlternar;
  final void Function(List<FamiliaGrupoVista>) onExcluirTodas;
  final VoidCallback onIncluirTodas;
  final Future<void> Function(List<FilaPorcentaje>) onIgualar;
  final void Function(
    FamiliaGrupoVista familia,
    List<FilaPorcentaje> destinos,
    _TablaPorcentajes tabla,
  )
  onCopiar;
  final Future<void> Function({
    required BigInt idGrupo,
    required String nombreGrupo,
    required List<FilaPorcentaje> destinos,
    required List<FamiliaGrupoVista> familias,
    required _TablaPorcentajes tabla,
  })
  onAplicar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDestinos = ref.watch(_destinosGrupoProvider(idGrupo));
    final asyncFamilias = ref.watch(_familiasGrupoProvider(idGrupo));
    final asyncTabla = ref.watch(_tablaPorcentajesProvider);

    if (asyncDestinos.hasError) {
      return MensajeError(
        error: asyncDestinos.error,
        onReintentar: () => ref.invalidate(destinosPorcentajeGrupoProvider),
      );
    }
    if (asyncFamilias.hasError) {
      return MensajeError(
        error: asyncFamilias.error,
        onReintentar: () {
          ref.invalidate(familiasPorGrupoProvider);
          ref.invalidate(porcentajesProvider);
        },
      );
    }

    if (asyncTabla.hasError) {
      return MensajeError(
        error: asyncTabla.error,
        onReintentar: () => ref.invalidate(porcentajesProvider),
      );
    }

    final destinos = asyncDestinos.valueOrNull;
    final familias = asyncFamilias.valueOrNull;
    final tabla = asyncTabla.valueOrNull;
    if (destinos == null || familias == null || tabla == null) {
      return const EsqueletoLista(filas: 7, altoFila: 56);
    }

    if (familias.isEmpty) {
      return const MensajeVacio(
        icono: Icons.inventory_2_outlined,
        titulo: 'El grupo no tiene familias',
        detalle:
            'Sin familias no hay a qué aplicarle un porcentaje. Revise el '
            'grupo en el catálogo de grupos de familia SAP.',
      );
    }
    if (destinos.isEmpty) {
      return const MensajeVacio(
        icono: Icons.price_change_outlined,
        titulo: 'No hay listas de precio activas',
        detalle:
            'La edición masiva escribe una fila por lista de precio activa. '
            'Sin listas activas no hay nada que escribir.',
      );
    }

    final hayInvalidos = destinos.any((d) => valorDe(d) == null);
    final conflictos =
        hayInvalidos
            ? const <ConflictoPorcentaje>[]
            : validarPorcentajesAscendentes([
              for (final d in destinos) d.aMapa(valorDe(d)!),
            ]);
    final clavesEnConflicto = {
      for (final c in conflictos)
        FilaPorcentaje.claveDeConflicto(c.codSucursal.toInt(), c.nombrePrecio),
    };

    final alcanzadas =
        familias.where((f) => !excluidas.contains(f.codigoFamilia)).length;
    final escrituras = alcanzadas * destinos.length;

    final visibles = [
      for (final f in familias)
        if (busqueda.trim().isEmpty ||
            f.textoBuscable.contains(busqueda.trim().toLowerCase()))
          f,
    ];

    final panelDestinos = _Seccion(
      numero: 3,
      titulo: 'Escriba los porcentajes nuevos',
      subtitulo:
          'El mismo valor, lista por lista, para todas las familias '
          'marcadas. Puede empezar copiando los de una familia.',
      accion: Wrap(
        spacing: Esp.xs,
        children: [
          PopupMenuButton<FamiliaGrupoVista>(
            enabled: !aplicando,
            tooltip:
                'Llenar la grilla con los porcentajes de hoy de una familia',
            onSelected: (f) => onCopiar(f, destinos, tabla),
            itemBuilder:
                (_) => [
                  for (final f in familias)
                    PopupMenuItem(
                      value: f,
                      enabled: !f.sinPorcentajes,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Familia ${f.codigoLegible}'),
                        subtitle: Text(f.resumenActual),
                      ),
                    ),
                ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Esp.s,
                vertical: Esp.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_copy_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Esp.xs),
                  Text(
                    'Copiar de una familia',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: Peso.titulo,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: aplicando ? null : () => onIgualar(destinos),
            icon: const Icon(Icons.format_line_spacing, size: 18),
            label: const Text('Igualar todas'),
          ),
        ],
      ),
      hijo: TablaPorcentajes(
        filas: destinos,
        valores: valores,
        habilitado: !aplicando,
        clavesEnConflicto: clavesEnConflicto,
        // En esta grilla el idPorcen no es de nadie: cada familia tiene el suyo y se
        // resuelve al escribir. Marcar "sin cargar" aquí mentiría.
        mostrarPendientes: false,
        // Y no hay "lo guardado" contra que comparar: la grilla nace en cero.
        resaltarCambios: false,
        onCambio: onCambio,
      ),
    );

    final panelFamilias = _Seccion(
      numero: 2,
      titulo: 'Elija las familias',
      subtitulo:
          '$alcanzadas de ${familias.length} marcadas. Se aplica a las '
          'marcadas; las desmarcadas no se tocan.',
      accion: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: aplicando || excluidas.isEmpty ? null : onIncluirTodas,
            child: const Text('Todas'),
          ),
          TextButton(
            onPressed:
                aplicando || excluidas.length == familias.length
                    ? null
                    : () => onExcluirTodas(familias),
            child: const Text('Ninguna'),
          ),
        ],
      ),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (familias.length > 8)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: TextField(
                enabled: !aplicando,
                decoration: const InputDecoration(
                  hintText: 'Buscar familia por código o proveedor…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onBusqueda,
              ),
            ),
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.l),
              child: Text(
                'Ninguna de las ${familias.length} familias del grupo '
                'coincide con "$busqueda".',
                style: context.apagado(),
              ),
            )
          else
            TablaFamiliasGrupo(
              familias: visibles,
              excluidas: excluidas,
              aire: aire,
              habilitado: !aplicando,
              onAlternar: onAlternar,
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AvisoListasInactivas(),
                if (conflictos.isNotEmpty)
                  NotaDelDato(
                    tono: TonoNota.error,
                    texto:
                        'El porcentaje no puede bajar al subir el número de '
                        'lista dentro de una misma sucursal. Esto se aplicaría '
                        'a TODAS las familias del grupo:\n'
                        '${conflictos.map((c) => '• ${c.mensaje}').join('\n')}',
                  ),
                if (hayInvalidos)
                  const NotaDelDato(
                    tono: TonoNota.aviso,
                    texto:
                        'Hay un campo que no es un número. Corríjalo para '
                        'poder aplicar.',
                  ),
                const SizedBox(height: Esp.s),
                // Escritorio: las dos grillas lado a lado, como en el diálogo anterior (se elige el
                // porcentaje mirando a quién le cae); si el cajón no da, se apilan, familias primero.
                if (aire == Aire.amplio)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: panelFamilias),
                      const SizedBox(width: Esp.l),
                      Expanded(flex: 5, child: panelDestinos),
                    ],
                  )
                else ...[
                  panelFamilias,
                  const SizedBox(height: Esp.l),
                  panelDestinos,
                ],
              ],
            ),
          ),
        ),
        _BarraGuardar(
          margen: margen,
          children: [
            Expanded(
              child:
                  aplicando
                      ? _Progreso(hechas: hechas, total: aHacer)
                      : _ResumenGrupo(
                        alcanzadas: alcanzadas,
                        excluidas: excluidas.length,
                        listas: destinos.length,
                        escrituras: escrituras,
                      ),
            ),
            const SizedBox(width: Esp.s),
            if (aplicando)
              TextButton(onPressed: onCancelar, child: const Text('Cancelar'))
            else
              BotonAccion(
                etiqueta:
                    alcanzadas == 1
                        ? 'Aplicar a 1 familia'
                        : 'Aplicar a $alcanzadas familias',
                etiquetaOcupado: 'Aplicando…',
                icono: Icons.percent,
                destructiva: true,
                onPressed:
                    alcanzadas == 0 || hayInvalidos || conflictos.isNotEmpty
                        ? null
                        : () => onAplicar(
                          idGrupo: idGrupo,
                          nombreGrupo: nombreGrupo,
                          destinos: destinos,
                          familias: familias,
                          tabla: tabla,
                        ),
              ),
          ],
        ),
      ],
    );
  }
}

/// El resumen de lo que va a pasar, ANTES de tocar el botón: cuántas familias se
/// tocan, cuántas quedan afuera y cuántas filas se escriben.
class _ResumenGrupo extends StatelessWidget {
  const _ResumenGrupo({
    required this.alcanzadas,
    required this.excluidas,
    required this.listas,
    required this.escrituras,
  });

  final int alcanzadas;
  final int excluidas;
  final int listas;
  final int escrituras;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Etiqueta(
          texto:
              alcanzadas == 1
                  ? 'Se aplica a 1 familia'
                  : 'Se aplica a $alcanzadas familias',
          tono: alcanzadas == 0 ? TonoEtiqueta.error : TonoEtiqueta.exito,
        ),
        if (excluidas > 0)
          Etiqueta(
            texto: excluidas == 1 ? '1 no se toca' : '$excluidas no se tocan',
          ),
        Etiqueta(texto: '$listas listas'),
        Etiqueta(
          texto:
              escrituras == 1
                  ? '1 fila a escribir'
                  : '$escrituras filas a escribir',
        ),
      ],
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.hechas, required this.total});

  final int hechas;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Escribiendo familia $hechas de $total…',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.xs),
        LinearProgressIndicator(
          value: total == 0 ? null : hechas / total,
          minHeight: 4,
        ),
      ],
    );
  }
}

/// El titulo de un paso de la edicion por grupo, con su numero.
class _TituloPaso extends StatelessWidget {
  const _TituloPaso({required this.numero, required this.titulo});

  final int numero;
  final String titulo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _NumeroPaso(numero),
      const SizedBox(width: Esp.s),
      Text(titulo, style: context.tituloSeccion()),
    ],
  );
}

/// Un paso con numero, titulo, explicacion y sus acciones.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.numero,
    required this.titulo,
    required this.subtitulo,
    required this.hijo,
    this.accion,
  });

  final int numero;
  final String titulo;
  final String subtitulo;
  final Widget hijo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TituloPaso(numero: numero, titulo: titulo),
              if (accion != null) accion!,
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text(subtitulo, style: context.apagado()),
          const SizedBox(height: Esp.m),
          hijo,
        ],
      ),
    );
  }
}
