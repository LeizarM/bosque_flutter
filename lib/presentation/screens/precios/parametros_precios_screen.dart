import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';
import 'package:bosque_flutter/domain/repositories/precios_repository.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogo_impuestos_precio.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogo_parametro_gramaje.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_parametros_gramaje.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tarjeta_tc_ancla.dart';

// Estado local de la pantalla: vive aquí y no en precios_provider.dart (texto del
// buscador, página, escrituras de configuración; no debe filtrarse a otras
// pantallas). Todo autoDispose: una visita no deja su filtro a la siguiente.

/// Los tres catalogos que hacen falta para leer y para editar un parametro de
/// gramaje: el grupo, el tipo y el rango.
@immutable
class _CatalogosGramaje {
  const _CatalogosGramaje({
    required this.grupos,
    required this.tipos,
    required this.rangos,
  });

  final List<GrupoFamiliaSapEntity> grupos;

  /// Todos los tipos, activos e inactivos: hay parametros viejos que apuntan a
  /// un tipo dado de baja y su nombre igual se tiene que poder mostrar.
  final List<TipoProductoEntity> tipos;

  final List<RangoGramajeEntity> rangos;
}

final _catalogosGramajeProvider = FutureProvider.autoDispose<_CatalogosGramaje>(
  (ref) async {
    // Se piden los tres ANTES de esperar al primero: con un await por linea
    // los tres viajes se hacen en fila y la seccion tarda el triple.
    final grupos = ref.watch(gruposFamiliaSapProvider.future);
    final tipos = ref.watch(tiposProductoProvider.future);
    final rangos = ref.watch(rangosGramajeProvider.future);
    return _CatalogosGramaje(
      grupos: await grupos,
      tipos: await tipos,
      rangos: await rangos,
    );
  },
);

/// Las asignaciones de gramaje con grupo, tipo y rango ya resueltos a texto. El
/// cruce se hace una vez aquí y no en la tabla (que queda como widget tonto):
/// ordenar o buscar no recorre los tres catálogos por cada fila dibujada.
final _filasGramajeProvider =
    FutureProvider.autoDispose<List<FilaParametroGramaje>>((ref) async {
      final pendientes = ref.watch(parametrosGramajeProvider.future);
      final catalogos = await ref.watch(_catalogosGramajeProvider.future);
      final parametros = await pendientes;

      final nombreGrupo = {
        for (final g in catalogos.grupos)
          g.idGrpFamiliaSap.toInt(): g.nombreVisible,
      };
      final nombreTipo = {
        for (final t in catalogos.tipos) t.idTipo.toInt(): t.nombreLegible,
      };
      final nombreRango = {
        for (final r in catalogos.rangos) r.idRangoGram.toInt(): r.rangoLegible,
      };

      final filas = [
        for (final p in parametros)
          FilaParametroGramaje(
            parametro: p,
            // Un id huerfano se muestra como id y no se esconde: es un dato mal
            // cargado que alguien tiene que ver para poder arreglarlo.
            grupo:
                nombreGrupo[p.idGrpFamiliaSap] ?? 'Grupo ${p.idGrpFamiliaSap}',
            tipo: nombreTipo[p.idTipo] ?? 'Tipo ${p.idTipo}',
            rango:
                nombreRango[p.idRangoGram] ??
                (p.tieneRangoAsignado
                    ? 'Rango ${p.idRangoGram}'
                    : 'Sin rango asignado'),
          ),
      ];

      filas.sort((a, b) {
        final porGrupo = a.grupo.toLowerCase().compareTo(b.grupo.toLowerCase());
        return porGrupo != 0 ? porGrupo : a.tipo.compareTo(b.tipo);
      });
      return filas;
    });

/// Texto del buscador de la tabla de gramaje.
final _busquedaGramajeProvider = StateProvider.autoDispose<String>((ref) => '');

/// Pagina visible de la tabla de gramaje, base cero.
final _paginaGramajeProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Las escrituras de configuración de esta pantalla. El estado es un booleano
/// (hay una escritura en vuelo); cada método devuelve el mensaje de error del
/// backend o null si salió bien, y la pantalla decide cómo contarlo (un error no
/// cambia lo que se dibuja: se avisa y se sigue).
class _EscriturasParametros extends StateNotifier<bool> {
  _EscriturasParametros(this._ref) : super(false);

  final Ref _ref;

  PreciosRepository get _repo => _ref.read(preciosRepositoryProvider);

  /// El backend toma el usuario del token; este va igual porque la entity lo
  /// pide y porque deja el dato correcto en memoria.
  BigInt get _usuario => BigInt.from(_ref.read(userProvider)?.codUsuario ?? 0);

  /// Marca la escritura en vuelo, la ejecuta e invalida lo que queda viejo.
  /// Devuelve null si el backend acepto, o su mensaje de negocio si no.
  Future<String?> _ejecutar(
    Future<BigInt> Function() accion,
    List<ProviderOrFamily> aInvalidar,
  ) async {
    // El boton queda deshabilitado mientras dura la peticion, pero el enter de
    // un teclado llega igual: sin esta guarda se manda dos veces la misma fila.
    if (state) return 'Hay una operación en curso. Espere a que termine.';
    state = true;
    try {
      await accion();
      if (!mounted) return null;
      for (final provider in aInvalidar) {
        _ref.invalidate(provider);
      }
      return null;
    } catch (e) {
      // El procedimiento devuelve el mensaje ya redactado para el usuario.
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) state = false;
    }
  }

  /// Cambia el IVA y el IT. La tabla es un singleton: si ya hay una fila el
  /// backend la actualiza aunque el cuerpo traiga otro id, y solo inserta
  /// cuando esta vacia. Por eso aquí no hay "alta" separada del "cambio".
  Future<String?> guardarImpuestos({
    required ResultadoImpuestos valores,
    CostoIvaItEntity? actual,
  }) {
    final base =
        actual ??
        CostoIvaItEntity(
          idCii: 0,
          idPropuesta: BigInt.zero,
          iva: 0,
          it: 0,
          audUsuario: _usuario,
        );
    final costo = base.copyWith(
      iva: valores.iva,
      it: valores.it,
      audUsuario: _usuario,
    );

    return _ejecutar(() => _repo.registrarCostoIvaIt(costo), [
      costosIvaItProvider,
      costoIvaItVigenteProvider,
      costosIvaItPorPropuestaProvider,
    ]);
  }

  /// Alta o modificacion de una asignacion de gramaje. Cual de las dos es la
  /// decide el backend por la clave natural (grupo, tipo), asi un segundo alta
  /// del mismo par no duplica la fila en una tabla que no tiene unique.
  Future<String?> guardarParametroGramaje(ResultadoParametroGramaje valores) {
    final par = GrupoFamTipoRangoGramEntity(
      idGrpFamiliaSap: valores.idGrpFamiliaSap,
      idTipo: valores.idTipo,
      idRangoGram: valores.idRangoGram,
      audUsuario: _usuario,
    );
    return _ejecutar(
      () => _repo.registrarParametroGramaje(par),
      _lecturasDeGramaje,
    );
  }

  /// Baja de una asignacion por su clave natural.
  Future<String?> eliminarParametroGramaje(GrupoFamTipoRangoGramEntity par) =>
      _ejecutar(
        () =>
            _repo.eliminarParametroGramaje(par.copyWith(audUsuario: _usuario)),
        _lecturasDeGramaje,
      );

  /// Todo lo que muestra parámetros de gramaje queda viejo tras escribirlos,
  /// incluidas las consultas por grupo y clave natural de otras pantallas: se
  /// invalidan las familias enteras, no una instancia.
  List<ProviderOrFamily> get _lecturasDeGramaje => [
    parametrosGramajeProvider,
    parametrosGramajePivoteProvider,
    parametrosPorGrupoFamiliaProvider,
    parametroGramajeProvider,
    rangosPorGrupoYTipoProvider,
  ];
}

final _escrituraProvider =
    StateNotifierProvider.autoDispose<_EscriturasParametros, bool>(
      (ref) => _EscriturasParametros(ref),
    );

// La pantalla

/// Parámetros del módulo de Precios: impuestos, gramaje y ancla del tipo de
/// cambio (se revisan juntos).
///
/// 1. **Impuestos** (tpr_costoIvaIt): ficha de una fila, se edita con
///    confirmación (entra en el cálculo de todos los precios).
/// 2. **Gramaje** (tpr_grupoFamTipoRangoGram): el único ABM completo.
/// 3. **Ancla del TC** (tpr_tcAncla): SOLO CONSULTA, la escribe el proceso de
///    repreciación nocturno, externo a la app.
///
/// Layout por ancho del CAJÓN (`LayoutBuilder`, no `MediaQuery`): dos columnas
/// con la tabla a la derecha, una sola apretado y, en teléfono, tarjetas.
class ParametrosPreciosScreen extends ConsumerStatefulWidget {
  const ParametrosPreciosScreen({super.key});

  @override
  ConsumerState<ParametrosPreciosScreen> createState() =>
      _ParametrosPreciosScreenState();
}

class _ParametrosPreciosScreenState
    extends ConsumerState<ParametrosPreciosScreen> {
  // Las secciones cambian de lugar al cruzar _anchoParaDosColumnas. Sin clave se
  // destruían y recreaban: un diálogo abierto encima perdía su sección (y lo que
  // se confirmaba) y el buscador de gramaje quedaba vacío con el filtro puesto.
  // Con la clave, Flutter las mueve enteras, con su estado.
  final _claveImpuestos = GlobalKey();
  final _claveGramaje = GlobalKey();
  final _claveTcAncla = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final guardando = ref.watch(_escrituraProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final margen = aire.esChico ? Esp.m : Esp.xl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(aire: aire, margen: margen),
              // Dos pixeles siempre reservados: si la barra apareciera y
              // desapareciera, toda la pagina saltaria en cada guardado.
              if (guardando)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child:
                    cajon.maxWidth >= _anchoParaDosColumnas
                        ? _dosColumnas(cajon.maxWidth, margen)
                        : _unaColumna(aire, margen),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Escritorio: la tabla a la derecha y las dos fichas a la izquierda (400 px);
  /// cada lado scrollea por su cuenta. Cada columna usa el aire de SU ancho (la de
  /// fichas es "teléfono" aunque la ventana sea enorme). Los anchos se calculan y
  /// no se miden con un LayoutBuilder por columna, para que las secciones se
  /// muden con su estado (ver las claves).
  Widget _dosColumnas(double ancho, double margen) {
    final aireFichas = Aire.de(_anchoColumnaFichas);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _anchoColumnaFichas,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, Esp.m, Esp.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SeccionImpuestos(key: _claveImpuestos, aire: aireFichas),
                const SizedBox(height: Esp.l),
                _SeccionTcAncla(key: _claveTcAncla, aire: aireFichas),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(Esp.m, Esp.l, margen, Esp.xxl),
            child: _SeccionGramaje(
              key: _claveGramaje,
              aire: Aire.de(ancho - _anchoColumnaFichas),
            ),
          ),
        ),
      ],
    );
  }

  /// Tablet y telefono: una sola columna, en el orden en que importan. Los
  /// impuestos van primero porque son el parametro que se consulta a diario.
  Widget _unaColumna(Aire aire, double margen) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SeccionImpuestos(key: _claveImpuestos, aire: aire),
        const SizedBox(height: Esp.l),
        _SeccionGramaje(key: _claveGramaje, aire: aire),
        const SizedBox(height: Esp.l),
        _SeccionTcAncla(key: _claveTcAncla, aire: aire),
      ],
    ),
  );
}

/// Ancho de la columna de fichas en escritorio. Fijo: las fichas muestran cifras
/// cortas y estiradas a 700 px el número se pierde en una fila vacía.
const double _anchoColumnaFichas = 400;

/// A partir de aquí la pantalla se parte en dos columnas. No basta `Aire.amplio`:
/// a 1000 px la tabla queda en 560 y sus cinco columnas apretadas; con 1240
/// queda en 800 y sigue siendo una tabla.
const double _anchoParaDosColumnas = 1240;

class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.aire, required this.margen});

  final Aire aire;
  final double margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parámetros de precios',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: Peso.dato,
                    letterSpacing: -0.4,
                  ),
                ),
                // En un telefono la bajada cuesta un tercio del alto util y no
                // dice nada que no se vea en los titulos de cada seccion.
                if (!aire.esChico)
                  Text(
                    'Impuestos, rangos de gramaje y el ancla del reprecio '
                    'automático.',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _refrescarTodo(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _refrescarTodo(WidgetRef ref) {
    ref.invalidate(costosIvaItProvider);
    ref.invalidate(costoIvaItVigenteProvider);
    ref.invalidate(parametrosGramajeProvider);
    ref.invalidate(parametrosGramajePivoteProvider);
    ref.invalidate(gruposFamiliaSapProvider);
    ref.invalidate(tiposProductoProvider);
    ref.invalidate(rangosGramajeProvider);
    ref.invalidate(anclasTipoCambioProvider);
  }
}

// La caja de una sección

/// El marco comun de las tres secciones: icono, titulo, una linea que explica
/// para que sirve, y la accion de la seccion si la tiene.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.aire,
    required this.child,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Aire aire;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: cs.primary),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: context.tituloSeccion()),
                      const SizedBox(height: Esp.xs),
                      Text(descripcion, style: context.apagado()),
                    ],
                  ),
                ),
                if (accion != null) ...[const SizedBox(width: Esp.s), accion!],
              ],
            ),
            const SizedBox(height: Esp.l),
            child,
          ],
        ),
      ),
    );
  }
}

// 1. Impuestos (tpr_costoIvaIt)

class _SeccionImpuestos extends ConsumerWidget {
  const _SeccionImpuestos({super.key, required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se mira el LISTADO y no solo la fila vigente: es una sola petición y deja ver
    // si se rompió el invariante de fila única (haría no determinista el cálculo
    // de todos los precios).
    final async = ref.watch(costosIvaItProvider);

    return _Seccion(
      icono: Icons.percent,
      titulo: 'Impuestos',
      descripcion: 'IVA e IT que entran en el cálculo de todos los precios.',
      aire: aire,
      child: async.when(
        loading:
            () => const SizedBox(height: 140, child: EsqueletoLista(filas: 2)),
        error:
            (e, _) => MensajeError(
              // Compacto: va dentro de la tarjeta, que ya scrollea; la versión grande trae su
              // propio scroll y anidada queda sin alto acotado.
              compacto: true,
              error: e,
              onReintentar: () => ref.invalidate(costosIvaItProvider),
            ),
        data: (lista) {
          final vigente = lista.isEmpty ? null : lista.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vigente == null)
                const NotaDelDato(
                  tono: TonoNota.aviso,
                  texto:
                      'Todavía no hay IVA ni IT configurados. Mientras falten, '
                      'los precios se calculan sin impuestos.',
                )
              else ...[
                Wrap(
                  spacing: Esp.xl,
                  runSpacing: Esp.m,
                  children: [
                    _Cifra(titulo: 'IVA', valor: vigente.ivaLegible),
                    _Cifra(titulo: 'IT', valor: vigente.itLegible),
                    _Cifra(
                      titulo: 'Total',
                      valor: vigente.totalIvaItLegible,
                      destacada: true,
                    ),
                  ],
                ),
                if (vigente.sinImpuestos)
                  const NotaDelDato(
                    tono: TonoNota.aviso,
                    texto:
                        'Los dos impuestos están en cero: el precio final sale '
                        'sin ningún recargo.',
                  ),
              ],
              if (lista.length > 1)
                NotaDelDato(
                  tono: TonoNota.error,
                  texto:
                      'Hay ${lista.length} filas de IVA/IT cargadas y el cálculo '
                      'toma una sin ningún orden definido. Avise a sistemas: '
                      'esta tabla debe tener una sola fila.',
                ),
              const NotaDelDato(
                tono: TonoNota.aviso,
                icono: Icons.warning_amber_rounded,
                texto:
                    'Cambiar el IVA o el IT afecta el cálculo de TODOS los '
                    'precios del sistema.',
              ),
              const SizedBox(height: Esp.l),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _editar(context, ref, vigente),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    vigente == null ? 'Cargar impuestos' : 'Editar IVA e IT',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    CostoIvaItEntity? vigente,
  ) async {
    // La confirmación la pide el propio diálogo, con los valores viejos y los nuevos
    // a la vista: confirmar sin ver contra qué se compara no es confirmar.
    final valores = await showDialog<ResultadoImpuestos>(
      context: context,
      builder: (_) => DialogoImpuestosPrecio(actual: vigente),
    );
    if (valores == null || !context.mounted) return;

    final error = await ref
        .read(_escrituraProvider.notifier)
        .guardarImpuestos(valores: valores, actual: vigente);
    if (!context.mounted) return;

    if (error == null) {
      avisar(context, 'IVA e IT actualizados.');
    } else {
      avisar(context, error, esError: true);
    }
  }
}

/// Un numero grande con su titulo. Cifras tabulares: los porcentajes se leen en
/// columna y con ancho variable los decimales bailan.
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.titulo,
    required this.valor,
    this.destacada = false,
  });

  final String titulo;
  final String valor;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Text(
          valor,
          style: tt.headlineSmall?.copyWith(
            fontWeight: Peso.dato,
            fontFeatures: cifrasTabulares,
            color: destacada ? cs.primary : null,
          ),
        ),
      ],
    );
  }
}

// 2. Parámetros de gramaje (tpr_grupoFamTipoRangoGram)

class _SeccionGramaje extends ConsumerStatefulWidget {
  const _SeccionGramaje({super.key, required this.aire});

  final Aire aire;

  @override
  ConsumerState<_SeccionGramaje> createState() => _SeccionGramajeState();
}

class _SeccionGramajeState extends ConsumerState<_SeccionGramaje> {
  // Arranca con lo que ya filtra el provider: si la seccion se volviera a
  // crear, el campo vacio no esconderia un filtro puesto.
  late final _buscador = TextEditingController(
    text: ref.read(_busquedaGramajeProvider),
  );

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  Aire get _aire => widget.aire;

  /// En un telefono entran menos filas antes de que la pagina se vuelva un
  /// scroll interminable.
  int get _porPagina => _aire.esChico ? 6 : 10;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_filasGramajeProvider);
    final catalogos = ref.watch(_catalogosGramajeProvider).valueOrNull;
    final busqueda = ref.watch(_busquedaGramajeProvider);

    return _Seccion(
      icono: Icons.straighten_outlined,
      titulo: 'Parámetros de gramaje',
      descripcion:
          'Qué rango de gramaje le corresponde a cada grupo de familia según '
          'el tipo de papel.',
      aire: _aire,
      accion:
          _aire.esChico
              ? IconButton.filledTonal(
                tooltip: 'Nuevo parámetro',
                onPressed: catalogos == null ? null : () => _abrirDialogo(null),
                icon: const Icon(Icons.add),
              )
              : FilledButton.tonalIcon(
                onPressed: catalogos == null ? null : () => _abrirDialogo(null),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo parámetro'),
              ),
      child: async.when(
        loading:
            () => const SizedBox(height: 240, child: EsqueletoLista(filas: 4)),
        error:
            (e, _) => MensajeError(
              // Compacto: va dentro de la tarjeta, que ya scrollea; la versión grande trae su
              // propio scroll y anidada queda sin alto acotado.
              compacto: true,
              error: e,
              onReintentar: () => ref.invalidate(parametrosGramajeProvider),
            ),
        data: (todas) {
          final filtradas =
              todas.where((f) => f.coincideCon(busqueda)).toList();
          final totalPaginas =
              filtradas.isEmpty
                  ? 1
                  : ((filtradas.length - 1) ~/ _porPagina) + 1;
          // La pagina se acota al dibujar en vez de corregir el provider: el
          // filtro puede achicar la lista en medio de un build, y escribir un
          // provider mientras se construye el arbol es ilegal en Riverpod.
          final guardada = ref.watch(_paginaGramajeProvider);
          final pagina =
              guardada < 0
                  ? 0
                  : (guardada > totalPaginas - 1 ? totalPaginas - 1 : guardada);
          final desde = pagina * _porPagina;
          final hasta =
              desde + _porPagina < filtradas.length
                  ? desde + _porPagina
                  : filtradas.length;
          final visibles = filtradas.sublist(desde, hasta);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filtros(totales: todas.length, filtradas: filtradas.length),
              const SizedBox(height: Esp.m),
              if (filtradas.isEmpty)
                SizedBox(
                  height: 200,
                  child: MensajeVacio(
                    icono: Icons.straighten_outlined,
                    titulo:
                        todas.isEmpty
                            ? 'No hay parámetros de gramaje'
                            : 'Ningún parámetro coincide',
                    detalle:
                        todas.isEmpty
                            ? 'Cada grupo de familia necesita un rango por tipo '
                                'de papel. Cree el primero con «Nuevo parámetro».'
                            : 'Pruebe con otro texto o limpie el buscador.',
                  ),
                )
              else ...[
                TablaParametrosGramaje(
                  filas: visibles,
                  aire: _aire,
                  onEditar: (fila) => _abrirDialogo(fila.parametro),
                  onEliminar: _eliminar,
                ),
                if (totalPaginas > 1)
                  _Paginador(
                    pagina: pagina,
                    totalPaginas: totalPaginas,
                    desde: desde + 1,
                    hasta: hasta,
                    total: filtradas.length,
                    onCambiar:
                        (nueva) =>
                            ref.read(_paginaGramajeProvider.notifier).state =
                                nueva,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// El buscador. En un telefono va plegado adentro de un desplegable: ocupa
  /// una fila cuando no se usa y se abre cuando hace falta.
  Widget _filtros({required int totales, required int filtradas}) {
    final campo = TextField(
      controller: _buscador,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        hintText: 'Buscar grupo, tipo o rango',
        border: const OutlineInputBorder(),
        suffixIcon:
            _buscador.text.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _buscador.clear();
                    _cambiarBusqueda('');
                  },
                ),
      ),
      onChanged: _cambiarBusqueda,
    );

    final resumen = Text(
      filtradas == totales
          ? '$totales parámetros'
          : '$filtradas de $totales parámetros',
      style: context.apagado(),
    );

    if (_aire.esChico) {
      return ExpansionTile(
        key: const PageStorageKey('filtros-gramaje'),
        // Sin las lineas del ExpansionTile: adentro de una tarjeta que ya
        // tiene borde, dibujan un marco dentro de otro.
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: Esp.s),
        leading: const Icon(Icons.filter_list),
        title: const Text('Buscar'),
        subtitle: resumen,
        children: [campo],
      );
    }

    return Row(
      children: [Expanded(child: campo), const SizedBox(width: Esp.m), resumen],
    );
  }

  void _cambiarBusqueda(String texto) {
    ref.read(_busquedaGramajeProvider.notifier).state = texto;
    // Se vuelve a la primera pagina: quedarse en la pagina 4 de un resultado
    // que ahora tiene una sola es la forma mas rapida de creer que no hay nada.
    ref.read(_paginaGramajeProvider.notifier).state = 0;
    setState(() {}); // Solo para que aparezca o desaparezca la cruz de limpiar.
  }

  Future<void> _abrirDialogo(GrupoFamTipoRangoGramEntity? inicial) async {
    final catalogos = ref.read(_catalogosGramajeProvider).valueOrNull;
    if (catalogos == null) {
      avisar(
        context,
        'Los catálogos todavía se están cargando.',
        esError: true,
      );
      return;
    }

    final filas = ref.read(_filasGramajeProvider).valueOrNull ?? const [];
    final valores = await showDialog<ResultadoParametroGramaje>(
      context: context,
      builder:
          (_) => DialogoParametroGramaje(
            grupos: catalogos.grupos,
            tipos: catalogos.tipos,
            rangos: catalogos.rangos,
            inicial: inicial,
            // La tabla no tiene unique: el par repetido hay que atajarlo aquí,
            // porque el backend lo aceptaria como una fila mas.
            clavesOcupadas: {for (final f in filas) f.parametro.claveNatural},
          ),
    );
    if (valores == null || !mounted) return;

    final error = await ref
        .read(_escrituraProvider.notifier)
        .guardarParametroGramaje(valores);
    if (!mounted) return;

    if (error == null) {
      avisar(
        context,
        inicial == null ? 'Parámetro creado.' : 'Parámetro actualizado.',
      );
    } else {
      avisar(context, error, esError: true);
    }
  }

  Future<void> _eliminar(FilaParametroGramaje fila) async {
    final aceptado = await confirmar(
      context,
      titulo: '¿Eliminar el parámetro?',
      detalle:
          'Se quita el rango ${fila.rango} del grupo ${fila.grupo} para el '
          'tipo ${fila.tipo}.\n\n'
          'Mientras el par no tenga rango asignado, las familias de ese grupo '
          'y ese tipo quedan sin rango de gramaje.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!aceptado || !mounted) return;

    final error = await ref
        .read(_escrituraProvider.notifier)
        .eliminarParametroGramaje(fila.parametro);
    if (!mounted) return;

    if (error == null) {
      avisar(context, 'Parámetro eliminado.');
    } else {
      avisar(context, error, esError: true);
    }
  }
}

/// Paginador propio, chico y del tema. No se usa `BosquePaginator`: pinta el
/// fondo con `Colors.white` fijo (franja blanca en modo oscuro) y decide su forma
/// con `ResponsiveUtilsBosque.isMobile`, que mide la ventana y no el cajón.
class _Paginador extends StatelessWidget {
  const _Paginador({
    required this.pagina,
    required this.totalPaginas,
    required this.desde,
    required this.hasta,
    required this.total,
    required this.onCambiar,
  });

  final int pagina;
  final int totalPaginas;
  final int desde;
  final int hasta;
  final int total;
  final ValueChanged<int> onCambiar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.s),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text('$desde-$hasta de $total', style: context.apagado()),
        ),
        IconButton(
          tooltip: 'Anterior',
          onPressed: pagina > 0 ? () => onCambiar(pagina - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${pagina + 1} / $totalPaginas',
          style: context.numero(fuerte: true),
        ),
        IconButton(
          tooltip: 'Siguiente',
          onPressed:
              pagina < totalPaginas - 1 ? () => onCambiar(pagina + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

// 3. Ancla del tipo de cambio (tpr_tcAncla)

class _SeccionTcAncla extends ConsumerWidget {
  const _SeccionTcAncla({super.key, required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(anclasTipoCambioProvider);

    return _Seccion(
      icono: Icons.currency_exchange_outlined,
      titulo: 'Tipo de cambio ancla',
      descripcion:
          'Con qué tipo de cambio se repreciaron los precios por última vez, '
          'por empresa.',
      aire: aire,
      child: async.when(
        loading:
            () => const SizedBox(height: 160, child: EsqueletoLista(filas: 2)),
        error:
            (e, _) => MensajeError(
              // Compacto: va dentro de la tarjeta, que ya scrollea; la versión grande trae su
              // propio scroll y anidada queda sin alto acotado.
              compacto: true,
              error: e,
              onReintentar: () => ref.invalidate(anclasTipoCambioProvider),
            ),
        data: (anclas) {
          if (anclas.isEmpty) {
            return const SizedBox(
              height: 180,
              child: MensajeVacio(
                icono: Icons.currency_exchange_outlined,
                titulo: 'Sin anclas configuradas',
                detalle:
                    'Ninguna empresa tiene todavía un tipo de cambio ancla. '
                    'La carga el proceso de repreciación, no esta pantalla.',
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final ancla in anclas)
                Padding(
                  padding: const EdgeInsets.only(bottom: Esp.m),
                  child: TarjetaTcAncla(ancla: ancla, compacta: aire.esChico),
                ),
              // La nota va abajo y siempre: es la respuesta a "¿y dónde se
              // edita esto?", que es lo primero que pregunta quien lo ve.
              const NotaDelDato(
                icono: Icons.schedule_outlined,
                texto:
                    'Estos valores los administra el proceso automático de '
                    'repreciación nocturna, fuera de la aplicación. Esta '
                    'sección es solo de consulta.',
              ),
            ],
          );
        },
      ),
    );
  }
}
