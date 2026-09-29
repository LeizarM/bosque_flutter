/// Precios vigentes: que vale hoy una familia de producto en cada sucursal y
/// en cada lista de precios.
///
/// Reemplaza a los dialogos `dlgPreA` y `dlgVista` del sistema anterior, que
/// mostraban lo mismo partido en dos ventanas modales encimadas —una para
/// elegir la familia y otra para ver la grilla— y obligaban a cerrar y volver a
/// abrir para cambiar de familia.
///
/// Lo que cambia respecto de aquella pantalla:
///
/// - **El precio en cero dice "Sin precio".** Un cuarto de tpr_precio esta en
///   cero, y ese cero significa que la lista no tiene precio cargado, no que el
///   producto se venda a cero. Antes se mostraba `0.00` junto a los precios de
///   verdad.
/// - **La familia se elige buscando.** Son setecientas: el desplegable viejo
///   las listaba en el orden en que salieron de la base.
/// - **Los filtros se acumulan.** Se puede mirar una sola sucursal, una sola
///   lista, o esconder las listas sin precio.
/// - **El costo y los impuestos con los que se armo el precio estan a la
///   vista**, arriba, una sola vez: en el resultset del backend el IVA y el IT
///   son subconsultas escalares, iguales en todas las filas.
///
/// **Es una pantalla de consulta: no escribe nada.** Quien reprecia usa la
/// pantalla de propuestas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/aviso_listas_inactivas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/ficha_familia_precio.dart';
import 'package:bosque_flutter/presentation/widgets/precios/precios_vigentes_datos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_precios_vigentes.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tarjetas_precios_vigentes.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DE LA PANTALLA
//
// Vive aca y no en `precios_provider.dart` a proposito: son los filtros de ESTA
// consulta y no tienen por que sobrevivir a la salida ni aparecer en la
// pantalla de propuestas, que tiene su propia idea de "la familia elegida" —la
// que se esta repreciando— y la usa para otra cosa. Todos son autoDispose: al
// salir del modulo quedan como estaban al entrar.
// ═══════════════════════════════════════════════════════════════════════════

/// La familia que se esta consultando. Null mientras no se eligio ninguna.
final _familiaConsultadaProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);

/// Sucursal por la que se filtra la grilla. Null = todas.
final _filtroSucursalProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Lista de precios por la que se filtra la grilla. Null = todas.
final _filtroListaProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Esconde las listas sin precio cargado. Arranca apagado: que una lista no
/// tenga precio es justamente una de las cosas que se vienen a mirar.
final _soloConPrecioProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Si el selector muestra tambien las familias dadas de baja. De las 704 de la
/// base, la mitad estan inactivas: por defecto no se ofrecen, pero se pueden
/// consultar, porque siguen teniendo precios cargados.
final _incluirInactivasProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Cuanta informacion muestra la tabla del escritorio.
final _vistaProvider = StateProvider.autoDispose<VistaPrecios>(
  (ref) => VistaPrecios.completa,
);

/// Las familias que alimentan el selector, ya tipadas y ordenadas por codigo.
///
/// Se pide una sola vez por estado —con y sin inactivas son dos claves
/// distintas de la misma consulta— y Riverpod se queda con las dos.
final _familiasDelSelectorProvider =
    FutureProvider.autoDispose<List<FamiliaPrecio>>((ref) async {
      final incluirInactivas = ref.watch(_incluirInactivasProvider);
      final crudas = await ref.watch(
        // Ojo con el estado: mandar 0 filtraria por "inactivas". El null es el
        // unico valor que significa "no filtres".
        familiasProvider(
          FiltroFamilias(estado: incluirInactivas ? null : 1),
        ).future,
      );

      final familias =
          crudas.map(FamiliaPrecio.desdeMapa).toList()
            ..sort((a, b) => a.codigoFamilia.compareTo(b.codigoFamilia));
      return familias;
    });

/// Las filas de precio de una familia, tipadas y agrupadas por sucursal.
final _filasProvider = FutureProvider.autoDispose
    .family<List<FilaPrecioVigente>, int>((ref, codigoFamilia) async {
      final crudas = await ref.watch(
        preciosTonPorFamiliaProvider(codigoFamilia).future,
      );
      return ordenadasPorSucursal(
        crudas.map(FilaPrecioVigente.desdeMapa).toList(),
      );
    });

/// La ficha de la familia consultada.
///
/// Se pide aparte del selector y no se busca dentro de su lista: si alguien
/// apaga "incluir inactivas" despues de elegir una familia de baja, la lista
/// deja de tenerla y la ficha desapareceria de la pantalla como si fuera un
/// error. Es una consulta de una sola fila.
final _familiaConsultadaDetalleProvider = FutureProvider.autoDispose
    .family<FamiliaPrecio?, int>((ref, codigoFamilia) async {
      final cruda = await ref.watch(familiaProvider(codigoFamilia).future);
      return cruda == null ? null : FamiliaPrecio.desdeMapa(cruda);
    });

/// Vuelve a pedir todo lo que se esta mostrando.
void _recargar(WidgetRef ref) {
  final codigo = ref.read(_familiaConsultadaProvider);
  ref.invalidate(familiasProvider);
  if (codigo != null) {
    ref.invalidate(preciosTonPorFamiliaProvider(codigo));
    ref.invalidate(familiaProvider(codigo));
  }
}

/// Deja los filtros de la grilla como al entrar. Se llama al cambiar de familia
/// —las listas de una familia no son las de otra— y desde el estado vacio.
void _limpiarFiltros(WidgetRef ref) {
  ref.read(_filtroSucursalProvider.notifier).state = null;
  ref.read(_filtroListaProvider.notifier).state = null;
  ref.read(_soloConPrecioProvider.notifier).state = false;
}

// ═══════════════════════════════════════════════════════════════════════════
// LA PANTALLA
// ═══════════════════════════════════════════════════════════════════════════

class PreciosScreen extends ConsumerWidget {
  const PreciosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    // El ancho que importa es el del CAJON, no el de la ventana: adentro del
    // dashboard el menu lateral se come 260 px y MediaQuery seguiria contando
    // una pantalla de escritorio mientras a la tabla le quedan 700.
    body: LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);
        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titulo y filtros son una sola franja fija: lo que esta debajo
            // del borde es lo que se recorre con el scroll.
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_Cabecera(aire: aire), _BarraFiltros(aire: aire)],
              ),
            ),
            Expanded(child: _Cuerpo(aire: aire)),
          ],
        );
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends ConsumerWidget {
  const _Cabecera({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precios vigentes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
                ),
                // En un telefono la bajada cuesta un tercio del alto util y no
                // dice nada que no se vea en el propio selector.
                if (!aire.esChico) ...[
                  SizedBox(height: Esp.xs),
                  Text(
                    'Precio por tonelada de una familia en cada sucursal y '
                    'lista de precio.',
                    style: context.apagado(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _recargar(ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
//
// En escritorio los tres filtros estan a la vista y en una sola linea. En
// telefono solo queda arriba el selector de familia —sin el no hay nada que
// mostrar— y los demas se pliegan, porque ocupaban la mitad de la pantalla
// para afinar una lista de doce tarjetas.
// ═══════════════════════════════════════════════════════════════════════════

class _BarraFiltros extends ConsumerWidget {
  const _BarraFiltros({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codigo = ref.watch(_familiaConsultadaProvider);

    // Las opciones de sucursal y de lista salen de las filas que ya se
    // trajeron, no de una consulta aparte: asi no se ofrece una lista que esta
    // familia no tiene, que era la forma de llegar a una grilla vacia sin
    // entender por que.
    final filas =
        codigo == null
            ? const <FilaPrecioVigente>[]
            : ref
                .watch(_filasProvider(codigo))
                .maybeWhen(
                  data: (filas) => filas,
                  orElse: () => const <FilaPrecioVigente>[],
                );

    final padding = EdgeInsets.fromLTRB(
      aire.esChico ? Esp.m : Esp.xl,
      0,
      aire.esChico ? Esp.m : Esp.xl,
      Esp.m,
    );

    if (aire.esChico) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelectorFamilia(aire: aire),
            if (filas.isNotEmpty) _FiltrosPlegados(filas: filas),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _SelectorFamilia(aire: aire)),
              SizedBox(width: Esp.m),
              Expanded(flex: 2, child: _FiltroSucursal(filas: filas)),
              SizedBox(width: Esp.m),
              Expanded(flex: 2, child: _FiltroLista(filas: filas)),
            ],
          ),
          SizedBox(height: Esp.s),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.s,
                  children: const [_ChipSoloConPrecio(), _ChipInactivas()],
                ),
              ),
              // El conmutador de vista solo tiene sentido donde hay tabla.
              if (aire == Aire.amplio) const _ConmutadorVista(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Los filtros secundarios del telefono, plegados detras de un solo renglon.
class _FiltrosPlegados extends ConsumerWidget {
  const _FiltrosPlegados({required this.filas});

  final List<FilaPrecioVigente> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activos =
        [
          if (ref.watch(_filtroSucursalProvider) != null) 1,
          if (ref.watch(_filtroListaProvider) != null) 1,
          if (ref.watch(_soloConPrecioProvider)) 1,
        ].length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          activos == 0 ? 'Filtros' : 'Filtros ($activos)',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        leading: const Icon(Icons.filter_alt_outlined, size: 20),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: Esp.s),
        children: [
          _FiltroSucursal(filas: filas),
          SizedBox(height: Esp.s),
          _FiltroLista(filas: filas),
          SizedBox(height: Esp.s),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              children: const [_ChipSoloConPrecio(), _ChipInactivas()],
            ),
          ),
        ],
      ),
    );
  }
}

/// El selector de familia. Es el unico control imprescindible de la pantalla:
/// sin familia no hay precios que mostrar.
class _SelectorFamilia extends ConsumerWidget {
  const _SelectorFamilia({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegida = ref.watch(_familiaConsultadaProvider);

    return ref
        .watch(_familiasDelSelectorProvider)
        .when(
          loading: () => const _ComboCargando(etiqueta: 'Familia de producto'),
          error:
              (e, _) => _ComboEnError(
                etiqueta: 'Familia de producto',
                onReintentar: () => ref.invalidate(familiasProvider),
              ),
          data:
              (familias) => ComboBuscable<int>(
                etiqueta: 'Familia de producto',
                valor: elegida,
                pista: 'Código, grupo SAP, proveedor o color',
                ayuda:
                    aire.esChico
                        ? null
                        : '${familias.length} familias. Escriba para buscar.',
                opciones: [
                  for (final f in familias)
                    DropdownMenuEntry<int>(
                      value: f.codigoFamilia,
                      // La baja se dice en la etiqueta y no con un color: el
                      // desplegable filtra por texto, asi que asi tambien se puede
                      // buscar.
                      label: f.activa ? f.etiqueta : '${f.etiqueta} · inactiva',
                    ),
                ],
                onElegir: (codigo) {
                  if (codigo == null) return;
                  // Los filtros son de la familia anterior: sus listas y sucursales
                  // no tienen por que existir en la nueva.
                  _limpiarFiltros(ref);
                  ref.read(_familiaConsultadaProvider.notifier).state = codigo;
                },
              ),
        );
  }
}

class _FiltroSucursal extends ConsumerWidget {
  const _FiltroSucursal({required this.filas});

  final List<FilaPrecioVigente> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opciones = <int, String>{};
    for (final f in filas) {
      opciones[f.codSucursal] = f.sucursalLegible;
    }

    final elegida = ref.watch(_filtroSucursalProvider);

    return DropdownButtonFormField<int?>(
      // Un valor que ya no esta entre las opciones —al cambiar de familia—
      // hace reventar al DropdownButton con un assert, asi que se cae a
      // "todas" antes de llegar a el.
      value: opciones.containsKey(elegida) ? elegida : null,
      // Sin esto el boton mide lo que su opcion mas larga y en el ancho medio
      // "Sucursal 6 Cochabamba" se salia del campo.
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sucursal',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
        for (final entrada in opciones.entries)
          DropdownMenuItem<int?>(
            value: entrada.key,
            child: Text(entrada.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged:
          filas.isEmpty
              ? null
              : (valor) {
                // Cada lista pertenece a una sucursal: sostener la lista elegida
                // despues de cambiar de sucursal deja la grilla vacia.
                ref.read(_filtroListaProvider.notifier).state = null;
                ref.read(_filtroSucursalProvider.notifier).state = valor;
              },
    );
  }
}

class _FiltroLista extends ConsumerWidget {
  const _FiltroLista({required this.filas});

  final List<FilaPrecioVigente> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursal = ref.watch(_filtroSucursalProvider);

    // Las listas que se ofrecen son las de la sucursal elegida: ofrecer las
    // veintiuna de la familia con una sucursal ya filtrada seria ofrecer
    // combinaciones que no devuelven nada.
    final opciones = <int, String>{};
    for (final f in filas) {
      if (sucursal == null || f.codSucursal == sucursal) {
        opciones[f.idClasificacion] = f.listaLegible;
      }
    }

    final elegida = ref.watch(_filtroListaProvider);

    return DropdownButtonFormField<int?>(
      value: opciones.containsKey(elegida) ? elegida : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Lista de precio',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
        for (final entrada in opciones.entries)
          DropdownMenuItem<int?>(
            value: entrada.key,
            child: Text(entrada.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged:
          opciones.isEmpty
              ? null
              : (valor) =>
                  ref.read(_filtroListaProvider.notifier).state = valor,
    );
  }
}

class _ChipSoloConPrecio extends ConsumerWidget {
  const _ChipSoloConPrecio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activo = ref.watch(_soloConPrecioProvider);

    return FilterChip(
      label: const Text('Solo con precio'),
      avatar: activo ? null : const Icon(Icons.money_off_outlined, size: 18),
      selected: activo,
      onSelected: (v) => ref.read(_soloConPrecioProvider.notifier).state = v,
      tooltip: 'Esconde las listas que no tienen precio cargado.',
    );
  }
}

class _ChipInactivas extends ConsumerWidget {
  const _ChipInactivas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activo = ref.watch(_incluirInactivasProvider);

    return FilterChip(
      label: const Text('Incluir familias inactivas'),
      avatar: activo ? null : const Icon(Icons.inventory_2_outlined, size: 18),
      selected: activo,
      onSelected: (v) => ref.read(_incluirInactivasProvider.notifier).state = v,
      tooltip:
          'Las familias dadas de baja conservan sus precios y se pueden '
          'consultar.',
    );
  }
}

class _ConmutadorVista extends ConsumerWidget {
  const _ConmutadorVista();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(_vistaProvider);

    return SegmentedButton<VistaPrecios>(
      segments: [
        for (final v in VistaPrecios.values)
          ButtonSegment(
            value: v,
            icon: Icon(v.icono, size: 18),
            label: Text(v.rotulo),
            tooltip:
                v == VistaPrecios.completa
                    ? 'Agrega el vpp, la lista de SAP y el id de precio'
                    : 'Solo sucursal, lista, porcentaje y precio',
          ),
      ],
      selected: {vista},
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged:
          (s) => ref.read(_vistaProvider.notifier).state = s.first,
    );
  }
}

/// El combo mientras viajan las familias. Ocupa el mismo lugar que el de
/// verdad para que la barra no salte cuando llega la respuesta.
class _ComboCargando extends StatelessWidget {
  const _ComboCargando({required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: const Padding(
        padding: EdgeInsets.all(Esp.m),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
    child: Text('Cargando…', style: context.apagado()),
  );
}

class _ComboEnError extends StatelessWidget {
  const _ComboEnError({required this.etiqueta, required this.onReintentar});

  final String etiqueta;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
      errorText: 'No se pudo traer el catálogo',
      suffixIcon: IconButton(
        onPressed: onReintentar,
        icon: const Icon(Icons.refresh, size: 20),
        tooltip: 'Reintentar',
      ),
    ),
    child: const SizedBox(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CUERPO
// ═══════════════════════════════════════════════════════════════════════════

class _Cuerpo extends ConsumerWidget {
  const _Cuerpo({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codigo = ref.watch(_familiaConsultadaProvider);

    if (codigo == null) {
      return const MensajeVacio(
        icono: Icons.price_change_outlined,
        titulo: 'Elija una familia',
        detalle:
            'Los precios se consultan por familia de producto. En el selector '
            'de arriba puede buscar por código, grupo SAP, proveedor o color.',
      );
    }

    return ref
        .watch(_filasProvider(codigo))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => _Error(
                error: error,
                onReintentar:
                    () => ref.invalidate(preciosTonPorFamiliaProvider(codigo)),
              ),
          data:
              (filas) =>
                  _Contenido(aire: aire, codigoFamilia: codigo, filas: filas),
        );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({
    required this.aire,
    required this.codigoFamilia,
    required this.filas,
  });

  final Aire aire;
  final int codigoFamilia;
  final List<FilaPrecioVigente> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursal = ref.watch(_filtroSucursalProvider);
    final lista = ref.watch(_filtroListaProvider);
    final soloConPrecio = ref.watch(_soloConPrecioProvider);

    final visibles =
        filas
            .where(
              (f) =>
                  (sucursal == null || f.codSucursal == sucursal) &&
                  (lista == null || f.idClasificacion == lista) &&
                  (!soloConPrecio || !f.sinPrecio),
            )
            .toList();

    final padding = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
    );

    // Un solo scroll para la ficha y las filas: con la ficha fija arriba, en
    // un telefono quedaba un tercio de pantalla para las tarjetas y en el
    // escritorio la tabla se leia por una ranura de cinco filas.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding.copyWith(top: Esp.l, bottom: Esp.m),
          sliver: SliverToBoxAdapter(
            child: _Ficha(
              aire: aire,
              codigoFamilia: codigoFamilia,
              filas: filas,
            ),
          ),
        ),
        // La grilla sale de las listas activas: se dice cuales faltan.
        SliverPadding(
          padding: padding.copyWith(bottom: Esp.m),
          sliver: const SliverToBoxAdapter(child: AvisoListasInactivas()),
        ),
        if (visibles.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _SinResultados(hayFilas: filas.isNotEmpty),
          )
        else
          _Listado(aire: aire, visibles: visibles, padding: padding),
      ],
    );
  }
}

class _Ficha extends ConsumerWidget {
  const _Ficha({
    required this.aire,
    required this.codigoFamilia,
    required this.filas,
  });

  final Aire aire;
  final int codigoFamilia;
  final List<FilaPrecioVigente> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familia = ref
        .watch(_familiaConsultadaDetalleProvider(codigoFamilia))
        .maybeWhen(data: (f) => f, orElse: () => null);

    // Mientras la ficha viaja no se dibuja un esqueleto: la grilla es lo que se
    // vino a ver y ya esta abajo. La ficha aparece cuando llega.
    if (familia == null) return const SizedBox();

    return FichaFamiliaPrecio(
      familia: familia,
      aire: aire,
      filas: filas,
      // El IVA y el IT son los mismos en todas las filas —en el resultset son
      // subconsultas escalares—, asi que alcanza con mirar la primera.
      iva: filas.isEmpty ? null : filas.first.iva,
      it: filas.isEmpty ? null : filas.first.it,
    );
  }
}

class _Listado extends ConsumerWidget {
  const _Listado({
    required this.aire,
    required this.visibles,
    required this.padding,
  });

  final Aire aire;
  final List<FilaPrecioVigente> visibles;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La tabla se muestra cuando el cajon la deja entrar entera. Por debajo de
    // los 1000 px no se achica la letra ni se parte en dos: cambia a tarjetas,
    // que es lo que se lee sin correr nada de costado. En el ancho medio van de
    // a dos.
    if (aire == Aire.amplio) {
      return TablaPreciosVigentes(
        filas: visibles,
        vista: ref.watch(_vistaProvider),
        padding: padding.copyWith(bottom: Esp.xl),
      );
    }

    return TarjetasPreciosVigentes(
      filas: visibles,
      columnas: aire == Aire.medio ? 2 : 1,
      padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADOS SIN DATOS
// ═══════════════════════════════════════════════════════════════════════════

/// Se distinguen los dos vacios: la familia no tiene ninguna lista de precios
/// cargada, o las tiene pero ninguna pasa los filtros. Cada uno se resuelve en
/// otro lado y por eso no dicen lo mismo.
class _SinResultados extends ConsumerWidget {
  const _SinResultados({required this.hayFilas});

  final bool hayFilas;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    // Va en el hueco que deja la ficha arriba, no en un Expanded: el scroll
    // de la pantalla le da el alto que sobre, o el suyo si no sobra nada.
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: MensajeVacio(
          icono: hayFilas ? Icons.filter_alt_off : Icons.price_check_outlined,
          titulo:
              hayFilas
                  ? 'Ninguna lista coincide con el filtro'
                  : 'La familia no tiene precios cargados',
          detalle:
              hayFilas
                  ? 'La familia tiene precios, pero ninguno queda dentro de la '
                      'sucursal y la lista elegidas.'
                  : 'No hay ninguna lista de precios activa con precio para esta '
                      'familia. Se carga desde una propuesta de reprecio.',
        ),
      ),
      if (hayFilas)
        Padding(
          padding: EdgeInsets.only(bottom: Esp.xxl),
          child: TextButton.icon(
            onPressed: () => _limpiarFiltros(ref),
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: const Text('Quitar filtros'),
          ),
        ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: MensajeVacio(
          icono: Icons.cloud_off_outlined,
          titulo: 'No se pudieron traer los precios',
          // El backend manda el mensaje de negocio listo para mostrar: se
          // muestra tal cual, sin traducir ni envolver.
          detalle: error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: Esp.xxl),
        child: FilledButton.icon(
          onPressed: onReintentar,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reintentar'),
        ),
      ),
    ],
  );
}
