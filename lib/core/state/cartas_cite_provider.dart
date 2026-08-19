import 'package:bosque_flutter/data/repositories/cartas_cite_impl.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/domain/repositories/cartas_cite_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado y catálogos del módulo Cartas CITE.
///
/// Los catálogos son `FutureProvider` globales porque casi no cambian —seis
/// tipos de documento, catorce áreas— y se consultan desde el listado y desde
/// el formulario. El listado en cambio es un `StateNotifier` con sus filtros.

final cartasCiteRepositoryProvider = Provider<CartasCiteRepository>(
  (ref) => CartasCiteImpl(),
);

// ═══════════════════════════════════════════════════════════════════════════
// CATÁLOGOS
// ═══════════════════════════════════════════════════════════════════════════

final tiposDocumentoCiteProvider =
    FutureProvider<List<TipoDocumentoCiteEntity>>((ref) async {
  return ref.read(cartasCiteRepositoryProvider).tiposDocumento();
});

/// Áreas de una empresa. Familia por `codEmpresa`: cada empresa tiene las
/// suyas y el formulario cambia de empresa sin salir de la pantalla.
final areasCiteProvider =
    FutureProvider.family<List<AreaCiteEntity>, int>((ref, codEmpresa) async {
  if (codEmpresa <= 0) return [];
  return ref.read(cartasCiteRepositoryProvider).areas(codEmpresa);
});

/// Empleados activos: sólo los pide el memorando y la comunicación interna.
/// Es una consulta pesada de RRHH, así que se carga cuando hace falta y no al
/// entrar al módulo.
final empleadosCiteProvider =
    FutureProvider<List<EmpleadoCiteEntity>>((ref) async {
  return ref.read(cartasCiteRepositoryProvider).empleados();
});

final gestionesCiteProvider =
    FutureProvider<List<GestionCiteEntity>>((ref) async {
  return ref.read(cartasCiteRepositoryProvider).gestiones();
});

/// Nombre y cargo del usuario logueado, para precargar el primer remitente.
final firmaUsuarioCiteProvider =
    FutureProvider.family<EmpleadoCiteEntity?, int>((ref, codUsuario) async {
  if (codUsuario <= 0) return null;
  return ref.read(cartasCiteRepositoryProvider).firmaUsuario(codUsuario);
});

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class CartasCiteState {
  final List<CartaCiteEntity> items;
  final bool cargando;
  final bool procesando;

  // filtros
  final DateTime fechaDesde;
  final DateTime fechaHasta;
  final int idTipoDoc;
  final int codEmpresa;
  final String buscar;

  // paginación
  final int pagina;
  final int tamanoPagina;
  final int totalRegistros;

  final String? mensajeError;
  final String? mensajeExito;

  const CartasCiteState({
    this.items = const [],
    this.cargando = false,
    this.procesando = false,
    required this.fechaDesde,
    required this.fechaHasta,
    this.idTipoDoc = 0,
    this.codEmpresa = 0,
    this.buscar = '',
    this.pagina = 1,
    this.tamanoPagina = 20,
    this.totalRegistros = 0,
    this.mensajeError,
    this.mensajeExito,
  });

  int get totalPaginas {
    if (totalRegistros <= 0) return 1;
    return ((totalRegistros - 1) ~/ tamanoPagina) + 1;
  }

  bool get hayFiltroTexto => buscar.trim().isNotEmpty;

  CartasCiteState copyWith({
    List<CartaCiteEntity>? items,
    bool? cargando,
    bool? procesando,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idTipoDoc,
    int? codEmpresa,
    String? buscar,
    int? pagina,
    int? tamanoPagina,
    int? totalRegistros,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      CartasCiteState(
        items: items ?? this.items,
        cargando: cargando ?? this.cargando,
        procesando: procesando ?? this.procesando,
        fechaDesde: fechaDesde ?? this.fechaDesde,
        fechaHasta: fechaHasta ?? this.fechaHasta,
        idTipoDoc: idTipoDoc ?? this.idTipoDoc,
        codEmpresa: codEmpresa ?? this.codEmpresa,
        buscar: buscar ?? this.buscar,
        pagina: pagina ?? this.pagina,
        tamanoPagina: tamanoPagina ?? this.tamanoPagina,
        totalRegistros: totalRegistros ?? this.totalRegistros,
        mensajeError: limpiarMensajes ? null : (mensajeError ?? this.mensajeError),
        mensajeExito: limpiarMensajes ? null : (mensajeExito ?? this.mensajeExito),
      );
}

class CartasCiteNotifier extends StateNotifier<CartasCiteState> {
  final CartasCiteRepository _repo;
  final int _codUsuario;

  CartasCiteNotifier(this._repo, this._codUsuario)
      : super(CartasCiteState(
          /// Tres meses hacia atrás y no "desde hoy" como el módulo viejo, que
          /// abría con la fecha actual y mostraba la grilla vacía: parecía que
          /// no había cartas cuando en realidad no había ninguna de hoy.
          fechaDesde: DateTime(DateTime.now().year, DateTime.now().month - 3, 1),
          fechaHasta: DateTime.now(),
        ));

  /// Se llama al entrar al módulo. Deja activa la gestión del año en curso
  /// antes de cualquier otra cosa: el correlativo cuelga de ahí.
  Future<void> inicializar({required int codEmpresa}) async {
    try {
      await _repo.prepararGestion(_codUsuario);
    } catch (_) {
      // Si falla, el listado igual sirve; el alta avisará que no hay gestión.
    }
    state = state.copyWith(codEmpresa: codEmpresa);
    await cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarMensajes: true);
    try {
      final items = await _repo.listar(
        fechaDesde: state.fechaDesde,
        fechaHasta: state.fechaHasta,
        idTipoDoc: state.idTipoDoc,
        codEmpresa: state.codEmpresa,
        codUsuario: _codUsuario,
        buscar: state.buscar.trim().isEmpty ? null : state.buscar.trim(),
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
      );

      /// El total viaja repetido en cada fila; con la lista vacía no hay de
      /// dónde sacarlo y es cero.
      final total = items.isEmpty ? 0 : items.first.totalRegistros;

      state = state.copyWith(items: items, totalRegistros: total, cargando: false);
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        items: const [],
        totalRegistros: 0,
        mensajeError: _limpiar(e),
      );
    }
  }

  /// Cualquier cambio de filtro vuelve a la página 1: quedarse en la página 4
  /// de un resultado que ahora tiene dos páginas muestra una grilla vacía.
  Future<void> filtrar({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idTipoDoc,
    int? codEmpresa,
    String? buscar,
  }) async {
    state = state.copyWith(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      idTipoDoc: idTipoDoc,
      codEmpresa: codEmpresa,
      buscar: buscar,
      pagina: 1,
    );
    await cargar();
  }

  Future<void> irAPagina(int pagina) async {
    if (pagina < 1 || pagina > state.totalPaginas || pagina == state.pagina) return;
    state = state.copyWith(pagina: pagina);
    await cargar();
  }

  Future<void> cambiarTamanoPagina(int tamano) async {
    state = state.copyWith(tamanoPagina: tamano, pagina: 1);
    await cargar();
  }

  /// Guarda y recarga el listado. Devuelve el mensaje del backend, que en un
  /// alta incluye el número de CITE que quedó asignado.
  Future<String> guardar(
    CartaCiteEntity carta, {
    List<BigInt> copiasAEliminar = const [],
    List<BigInt> destinatariosAEliminar = const [],
    List<BigInt> remitentesAEliminar = const [],
  }) async {
    state = state.copyWith(procesando: true, limpiarMensajes: true);
    try {
      final msg = await _repo.guardar(
        carta,
        copiasAEliminar: copiasAEliminar,
        destinatariosAEliminar: destinatariosAEliminar,
        remitentesAEliminar: remitentesAEliminar,
        audUsuario: _codUsuario,
      );
      state = state.copyWith(procesando: false, mensajeExito: msg);
      await cargar();
      return msg;
    } catch (e) {
      state = state.copyWith(procesando: false, mensajeError: _limpiar(e));
      rethrow;
    }
  }

  Future<void> anular(BigInt idDocumento, {String? motivo}) async {
    state = state.copyWith(procesando: true, limpiarMensajes: true);
    try {
      final msg = await _repo.anular(idDocumento, _codUsuario, motivo: motivo);
      state = state.copyWith(procesando: false, mensajeExito: msg);
      await cargar();
    } catch (e) {
      state = state.copyWith(procesando: false, mensajeError: _limpiar(e));
    }
  }

  void limpiarMensajes() => state = state.copyWith(limpiarMensajes: true);

  /// `postAndReturnList` envuelve en `Exception`, `postAndReturnFullResponse`
  /// tira el String pelado. Al usuario le llega el texto del backend en los
  /// dos casos y no un "Exception: " adelante.
  static String _limpiar(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

/// Familia por usuario: el `esAutor` de cada fila —y por lo tanto quién puede
/// editar qué— depende de quién consulta.
final cartasCiteProvider = StateNotifierProvider.family<CartasCiteNotifier,
    CartasCiteState, int>((ref, codUsuario) {
  return CartasCiteNotifier(ref.read(cartasCiteRepositoryProvider), codUsuario);
});
