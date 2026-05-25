import 'dart:math' show max;
import 'package:bosque_flutter/data/models/anticipo_preview_model.dart';
import 'package:bosque_flutter/data/repositories/anticipo_impl.dart';
import 'package:bosque_flutter/data/repositories/registro_empleado_impl.dart';
import 'package:bosque_flutter/domain/entities/anticipo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Filtros persistentes: sobreviven al cambio de empresa ──────────────────
// NO es autoDispose para que los valores se mantengan al cambiar de empresa
class _FiltrosPersistidos {
  final String? estadoFiltro;
  final String mes;
  final String anio;
  final int tamanoPagina;

  const _FiltrosPersistidos({
    this.estadoFiltro,
    required this.mes,
    required this.anio,
    this.tamanoPagina = 15,
  });

  _FiltrosPersistidos copyWith({
    String? estadoFiltro,
    bool clearEstado = false,
    String? mes,
    String? anio,
    int? tamanoPagina,
  }) => _FiltrosPersistidos(
    estadoFiltro: clearEstado ? null : (estadoFiltro ?? this.estadoFiltro),
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
  );
}

final _filtrosPersistidosProvider = StateProvider<_FiltrosPersistidos>(
  (ref) => _FiltrosPersistidos(
    mes: DateTime.now().month.toString(),
    anio: DateTime.now().year.toString(),
  ),
);

// ─────────────────────────────────────────────
// ESTADO UNIFICADO DE ANTICIPOS
// ─────────────────────────────────────────────
class AnticipoState {
  final List<AnticipoEntity> items;
  final bool cargando;
  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final String search;
  final String?
  estadoFiltro; // null = todos | 'NO ASIGNADO' | 'ASIGNADO' | 'ANULADO'
  final int totalRegistros;
  final String? mensajeError;
  final String? mensajeExito;
  final String mes;
  final String anio;

  const AnticipoState({
    this.items = const [],
    this.cargando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.search = '',
    this.estadoFiltro,
    this.totalRegistros = 0,
    this.mensajeError,
    this.mensajeExito,
    this.mes = '',
    this.anio = '',
  });

  AnticipoState copyWith({
    List<AnticipoEntity>? items,
    bool? cargando,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    String? search,
    String? estadoFiltro,
    bool clearEstado = false,
    int? totalRegistros,
    String? mensajeError,
    String? mensajeExito,
    String? mes,
    String? anio,
  }) => AnticipoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
    estadoFiltro: clearEstado ? null : (estadoFiltro ?? this.estadoFiltro),
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
  );
}

// ─────────────────────────────────────────────
// ESTADO DEL DETALLE (sin cambios)
// ─────────────────────────────────────────────
class AnticipoDetalleState {
  final List<AnticipoDetalleEntity> items;
  final bool cargando;
  final int pagina;
  final int totalPaginas;
  final String search;
  final int totalRegistros;
  final String? mensajeError;

  const AnticipoDetalleState({
    this.items = const [],
    this.cargando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.search = '',
    this.totalRegistros = 0,
    this.mensajeError,
  });

  AnticipoDetalleState copyWith({
    List<AnticipoDetalleEntity>? items,
    bool? cargando,
    int? pagina,
    int? totalPaginas,
    String? search,
    int? totalRegistros,
    String? mensajeError,
  }) => AnticipoDetalleState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    search: search ?? this.search,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError,
  );
}

// ─────────────────────────────────────────────
// NOTIFIER — ANTICIPOS UNIFICADO
// ─────────────────────────────────────────────
class AnticipoNotifier extends StateNotifier<AnticipoState> {
  final AnticipoImpl _repo;
  final int codEmpresa;
  final Ref _ref;

  AnticipoNotifier(this._repo, this.codEmpresa, this._ref)
    : super(const AnticipoState()) {
    // ► Lee filtros persistidos al crear el notifier (al cambiar empresa)
    final f = _ref.read(_filtrosPersistidosProvider);
    state = AnticipoState(
      mes: f.mes,
      anio: f.anio,
      estadoFiltro: f.estadoFiltro,
      tamanoPagina: f.tamanoPagina,
    );
    Future.microtask(() => cargar());
  }

  // Guarda los filtros actuales para la próxima empresa
  void _persistir() {
    _ref.read(_filtrosPersistidosProvider.notifier).state = _FiltrosPersistidos(
      estadoFiltro: state.estadoFiltro,
      mes: state.mes,
      anio: state.anio,
      tamanoPagina: state.tamanoPagina,
    );
  }

  void setFechaFiltro({String? mes, String? anio}) {
    state = state.copyWith(mes: mes, anio: anio, pagina: 1);
    _persistir();
    cargar();
  }

  // FIX PUNTO 5: clearEstado: estado == null resuelve "TODOS no muestra nada"
  void cambiarFiltrado({String? estado}) {
    state = state.copyWith(
      estadoFiltro: estado,
      clearEstado: estado == null,
      pagina: 1,
    );
    _persistir();
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      // PUNTO 3: codEmpresa==0 → null (TODAS las empresas)
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;
      final data = await _repo.getAnticipos(
        state.pagina,
        state.tamanoPagina,
        empFiltro,
        state.search.isEmpty ? null : state.search,
        state.estadoFiltro,
        state.mes,
        state.anio,
      );
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void cambiarPagina(int p) {
    state = state.copyWith(pagina: p);
    cargar();
  }

  void buscar(String q) {
    state = state.copyWith(search: q, pagina: 1);
    cargar();
  }

  void cambiarTamano(int t) {
    state = state.copyWith(tamanoPagina: t, pagina: 1);
    _persistir();
    cargar();
  }

  Future<void> anularAnticipo(int codAnticipo, int audUsuarioI) async {
    state = state.copyWith(cargando: true);
    try {
      final response = await _repo.anularAnticipo(
        codAnticipo: codAnticipo,
        audUsuarioI: audUsuarioI,
      );
      state = state.copyWith(
        mensajeExito: response.message,
        search: '',
        pagina: 1,
      );
      cargar();
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  // Eliminar filtrarEstado() — era duplicado de cambiarFiltrado()
}

// ─────────────────────────────────────────────
// NOTIFIER — DETALLE (sin cambios)
// ─────────────────────────────────────────────
class AnticipoDetalleNotifier extends StateNotifier<AnticipoDetalleState> {
  final AnticipoImpl _repo;

  AnticipoDetalleNotifier(this._repo) : super(const AnticipoDetalleState());

  Future<void> cargar(int codAnticipo) async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.getAnticipoDetallado(
        codAnticipo,
        state.pagina,
        20,
        state.search.isEmpty ? null : state.search,
      );
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: max(
          1,
          data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        ),
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void buscar(String q, int codAnticipo) {
    state = state.copyWith(search: q, pagina: 1);
    cargar(codAnticipo);
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────
final _repoProvider = Provider((ref) => AnticipoImpl());

final anticipoProvider = StateNotifierProvider.family
    .autoDispose<AnticipoNotifier, AnticipoState, int>(
      (ref, codEmpresa) =>
          AnticipoNotifier(ref.read(_repoProvider), codEmpresa, ref),
    );

final anticipoDetalleProvider = StateNotifierProvider.autoDispose<
  AnticipoDetalleNotifier,
  AnticipoDetalleState
>((ref) => AnticipoDetalleNotifier(ref.read(_repoProvider)));

// ─────────────────────────────────────────────
// ESTADO — ANTICIPOS SIN ASIGNAR (flujo de casamiento Tigo)
// ─────────────────────────────────────────────
class AsignacionAnticipoState {
  final List<AnticipoDetalleEntity> items;
  final bool cargando;
  final bool asignando; // spinner durante el guardado
  final int pagina;
  final int totalPaginas;
  final String search;
  final int totalRegistros;
  final String? mensajeError;
  final String? mensajeExito;

  const AsignacionAnticipoState({
    this.items = const [],
    this.cargando = false,
    this.asignando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.search = '',
    this.totalRegistros = 0,
    this.mensajeError,
    this.mensajeExito,
  });

  AsignacionAnticipoState copyWith({
    List<AnticipoDetalleEntity>? items,
    bool? cargando,
    bool? asignando,
    int? pagina,
    int? totalPaginas,
    String? search,
    int? totalRegistros,
    String? mensajeError,
    String? mensajeExito,
  }) => AsignacionAnticipoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    asignando: asignando ?? this.asignando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    search: search ?? this.search,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

// ─────────────────────────────────────────────
// NOTIFIER — ANTICIPOS SIN ASIGNAR
// Parametrizado por codEmpresa de la cabecera SAP seleccionada
// ─────────────────────────────────────────────
class AsignacionAnticipoNotifier
    extends StateNotifier<AsignacionAnticipoState> {
  final AnticipoImpl _repo;
  final int codEmpresa;
  final Ref ref;

  AsignacionAnticipoNotifier(this._repo, this.codEmpresa, this.ref)
    : super(const AsignacionAnticipoState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    if (!mounted) return; // ← AGREGAR
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.getAnticipoDetalleNoAsignado(
        state.pagina,
        200,
        codEmpresa,
        state.search.isEmpty ? null : state.search,
        null,
      );
      if (!mounted) return; // ← AGREGAR
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: max(
          1,
          data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        ),
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
      if (!mounted) return; // ← AGREGAR
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void buscar(String q) {
    state = state.copyWith(search: q, pagina: 1);
    cargar();
  }

  void cambiarPagina(int p) {
    state = state.copyWith(pagina: p);
    cargar();
  }

  Future<void> confirmarAsignacion({
    required AnticipoEntity cabecera,
    required Set<int> codAntDetalles,
    required int audUsuarioI,
  }) async {
    if (codAntDetalles.isEmpty) return;
    state = state.copyWith(asignando: true);
    try {
      final response = await _repo.asignarAnticipo(
        cabecera: cabecera,
        codAntDetalles: codAntDetalles.toList(),
        audUsuarioI: audUsuarioI,
      );
      ref.invalidate(anticipoProvider);
      state = state.copyWith(asignando: false, mensajeExito: response.message);
    } catch (e) {
      state = state.copyWith(asignando: false, mensajeError: e.toString());
    }
  }
}

// Provider parametrizado por codEmpresa de la cabecera
final asignacionAnticipoProvider = StateNotifierProvider.family
    .autoDispose<AsignacionAnticipoNotifier, AsignacionAnticipoState, int>(
      (ref, codEmpresa) =>
          AsignacionAnticipoNotifier(ref.read(_repoProvider), codEmpresa, ref),
    );

// ─────────────────────────────────────────────
// CLASES Y ESTADOS PARA ASIGNACIÓN MANUAL
// ─────────────────────────────────────────────
class EmpleadoAsignacion {
  final int codEmpleado;
  final String nombreCompleto;
  final EmpleadoEntity?
  empleado; // Ahora es opcional (solo lo tenemos al buscar uno nuevo)
  String tipo;
  double monto;
  double montoCalculadoPrev;

  EmpleadoAsignacion({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.empleado,
    this.tipo = 'A',
    this.monto = 0.0,
    this.montoCalculadoPrev = 0.0,
  });
}

class AsignacionManualState {
  final List<EmpleadoAsignacion> empleados;
  final List<AnticipoPreviewEntity> preview;
  final bool cargando;
  final String? error;
  final bool asignadoExito;
  final String? mensajeExito;

  AsignacionManualState({
    this.empleados = const [],
    this.preview = const [],
    this.cargando = false,
    this.error,
    this.asignadoExito = false,
    this.mensajeExito,
  });

  AsignacionManualState copyWith({
    List<EmpleadoAsignacion>? empleados,
    List<AnticipoPreviewEntity>? preview,
    bool? cargando,
    String? error,
    bool? asignadoExito,
    String? mensajeExito,
  }) => AsignacionManualState(
    empleados: empleados ?? this.empleados,
    preview: preview ?? this.preview,
    cargando: cargando ?? this.cargando,
    error: error,
    asignadoExito: asignadoExito ?? this.asignadoExito,
    mensajeExito: mensajeExito,
  );
}

// ─────────────────────────────────────────────
// NOTIFIER — ASIGNACIÓN MANUAL
// ─────────────────────────────────────────────
class AsignacionManualNotifier extends StateNotifier<AsignacionManualState> {
  final AnticipoImpl _repo;
  final Ref ref;

  AsignacionManualNotifier(this._repo, this.ref)
    : super(AsignacionManualState());

  void agregarEmpleado(EmpleadoEntity emp) {
    if (state.empleados.any((e) => e.codEmpleado == emp.codEmpleado)) return;

    final esElPrimero = state.empleados.isEmpty;

    // Si hay exactamente 1 empleado tipo 'A' y agregamos más → convertirlo a 'F'
    final empleadosActualizados =
        esElPrimero
            ? state.empleados
            : state.empleados
                .map(
                  (e) =>
                      e.tipo == 'A'
                          ? EmpleadoAsignacion(
                            codEmpleado: e.codEmpleado,
                            nombreCompleto: e.nombreCompleto,
                            empleado: e.empleado,
                            tipo: 'F',
                            monto: e.monto,
                            montoCalculadoPrev: e.montoCalculadoPrev,
                          )
                          : e,
                )
                .toList();

    state = state.copyWith(
      empleados: [
        ...empleadosActualizados,
        EmpleadoAsignacion(
          codEmpleado: emp.codEmpleado,
          nombreCompleto: emp.persona.datoPersona ?? '',
          empleado: emp,
          tipo: esElPrimero ? 'A' : 'F', // ← regla: 1=auto, más=fijo
        ),
      ],
      preview: [],
      error: null,
    );
  }

  void removerEmpleado(int codEmpleado) {
    state = state.copyWith(
      empleados:
          state.empleados.where((e) => e.codEmpleado != codEmpleado).toList(),
      preview: [],
      error: null,
    );
  }

  void actualizarTipoYMonto(int codEmpleado, String tipo, double monto) {
    final list =
        state.empleados.map((e) {
          if (e.codEmpleado == codEmpleado) {
            e.tipo = tipo;
            e.monto = tipo == 'F' ? monto : 0.0;
          }
          return e;
        }).toList();
    state = state.copyWith(empleados: list, preview: []);
  }

  /// Establece el tipo de distribución para TODOS los empleados a la vez.
  /// Útil para el usuario que quiere distribuir todo automático o todo fijo.
  void setAllTipo(String tipo) {
    if (state.empleados.isEmpty) return;
    final list =
        state.empleados
            .map(
              (e) => EmpleadoAsignacion(
                codEmpleado: e.codEmpleado,
                nombreCompleto: e.nombreCompleto,
                empleado: e.empleado,
                tipo: tipo,
                monto: tipo == 'F' ? e.monto : 0.0,
                montoCalculadoPrev: e.montoCalculadoPrev,
              ),
            )
            .toList();
    state = state.copyWith(empleados: list, preview: []);
  }

  // Modificamos el método para recibir el concepto de la cabecera
  String _generarXml(String conceptoCabecera) {
    final buffer = StringBuffer('<empleados>');
    final conceptoLimpio = conceptoCabecera.replaceAll('"', '&quot;');

    for (final e in state.empleados) {
      buffer.write(
        '<empleado codEmpleado="${e.codEmpleado}" tipo="${e.tipo}" monto="${e.monto}" descripcion="$conceptoLimpio" codAutorizacion="0" fechaAnticipo="${DateTime.now().toIso8601String().split('T')[0]}"/>',
      );
    }
    buffer.write('</empleados>');
    return buffer.toString();
  }

  Future<void> previsualizar(AnticipoEntity cabecera) async {
    if (!mounted || state.empleados.isEmpty) return;
    state = state.copyWith(cargando: true, error: null);
    try {
      final preview = await _repo.previsualizarAsignacion(
        cabecera: cabecera,
        xmlEmpleados: _generarXml(cabecera.concepto),
      );
      if (!mounted) return;

      if (preview.isEmpty) {
        state = state.copyWith(
          cargando: false,
          error: 'Error desconocido al validar en el servidor.',
        );
        return;
      }
      if (preview.first.codEmpleado == 0) {
        state = state.copyWith(
          cargando: false,
          error: preview.first.nombreCompleto,
        );
        return;
      }
      final list =
          state.empleados.map((e) {
            final p = preview.firstWhere(
              (p) => p.codEmpleado == e.codEmpleado,
              orElse:
                  () => AnticipoPreviewEntity(
                    codEmpleado: e.codEmpleado,
                    montoCalculado: 0,
                    esValido: false,
                    nombreCompleto: '',
                    tipo: '',
                    montoSAP: 0,
                    sumaTotalCalculada: 0,
                    diferenciaGlobal: 0,
                  ),
            );
            e.montoCalculadoPrev = p.montoCalculado;
            return e;
          }).toList();
      state = state.copyWith(
        cargando: false,
        preview: preview,
        empleados: list,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> confirmarAsignacion(
    AnticipoEntity cabecera,
    int audUsuarioI,
  ) async {
    if (!mounted) return;
    state = state.copyWith(cargando: true, error: null);
    try {
      final response = await _repo.asignarAnticipoManual(
        cabecera: cabecera,
        xmlEmpleados: _generarXml(cabecera.concepto),
        audUsuarioI: audUsuarioI,
      );
      if (!mounted) return;
      ref.invalidate(anticipoProvider);
      state = state.copyWith(
        cargando: false,
        asignadoExito: true,
        mensajeExito: response.message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> cargarParaEdicion(AnticipoEntity cabecera) async {
    if (!mounted) return;
    state = state.copyWith(cargando: true, error: null);
    try {
      final detalles = await _repo.getAnticipoDetallado(
        cabecera.codAnticipo,
        1,
        200,
        null,
      );
      if (!mounted) return;
      final list =
          detalles
              .map(
                (d) => EmpleadoAsignacion(
                  codEmpleado: d.codEmpleado,
                  nombreCompleto: d.nombreCompleto,
                  tipo: 'F',
                  monto: d.monto,
                  montoCalculadoPrev: d.monto,
                ),
              )
              .toList();
      state = state.copyWith(empleados: list);
      await previsualizar(cabecera); // previsualizar ya tiene sus checks
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> confirmarEdicion(
    AnticipoEntity cabecera,
    int audUsuarioI,
  ) async {
    if (!mounted) return;
    state = state.copyWith(cargando: true, error: null);
    try {
      final response = await _repo.editarAsignacionManual(
        cabecera: cabecera,
        xmlEmpleados: _generarXml(cabecera.concepto),
        audUsuarioI: audUsuarioI,
      );
      if (!mounted) return;
      ref.invalidate(anticipoProvider);
      state = state.copyWith(
        cargando: false,
        asignadoExito: true,
        mensajeExito: response.message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

// ─────────────────────────────────────────────
// PROVIDERS DE ASIGNACIÓN Y BÚSQUEDA MANUAL
// ─────────────────────────────────────────────

final asignacionManualProvider = StateNotifierProvider.autoDispose<
  AsignacionManualNotifier,
  AsignacionManualState
>((ref) => AsignacionManualNotifier(ref.read(_repoProvider), ref));

final searchEmpleadoTextProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final buscarEmpleadoProvider = FutureProvider.autoDispose
    .family<List<EmpleadoEntity>, int>((ref, codEmpresa) async {
      final query = ref.watch(searchEmpleadoTextProvider);

      if (query.isEmpty || query.length < 3) {
        return [];
      }

      final repo = RegistroEmpleadoImpl();
      // Busca empleados en la misma empresa que la cabecera
      final empleados = await repo.getLstEmpleados(
        query,
        1,
        1,
        200,
        codEmpresa,
      );
      return empleados;
    });
final restriccionAccionesProvider = FutureProvider.family.autoDispose<
  bool,
  int
>((ref, codAnticipo) async {
  try {
    final repo = AnticipoImpl();
    final estados = await repo.estadoAnticipo(codAnticipo);
    // Bloqueamos si existe algún detalle Cancelado o Anulado
    return estados.any(
      (e) => e.toUpperCase() == 'CANCELADO' || e.toUpperCase() == 'ANULADO',
    );
  } catch (_) {
    return false; // Por seguridad, si falla la red, permitimos ver los botones
  }
});
