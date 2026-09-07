import 'dart:typed_data';
import 'package:bosque_flutter/data/models/prestamo_model.dart';
import 'package:bosque_flutter/data/repositories/prestamo_impl.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Filtros persistentes ──────────────────
class _FiltrosPersistidosPrestamo {
  final String? fechaDesde;
  final String? fechaHasta;
  final int tamanoPagina;
  final String estadoFiltro;

  const _FiltrosPersistidosPrestamo({
    this.fechaDesde,
    this.fechaHasta,
    this.tamanoPagina = 15,
    this.estadoFiltro = 'NO ASIGNADOS',
  });

  _FiltrosPersistidosPrestamo copyWith({
    String? fechaDesde,
    String? fechaHasta,
    int? tamanoPagina,
    String? estadoFiltro,
  }) => _FiltrosPersistidosPrestamo(
    fechaDesde: fechaDesde ?? this.fechaDesde,
    fechaHasta: fechaHasta ?? this.fechaHasta,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    estadoFiltro: estadoFiltro ?? this.estadoFiltro,
  );
}

final _filtrosPrestamoProvider = StateProvider<_FiltrosPersistidosPrestamo>(
  (ref) => const _FiltrosPersistidosPrestamo(),
);

final estadosPrestamoProvider = FutureProvider<List<TipoPrestamoEntity>>((
  ref,
) async {
  final repo = PrestamoImpl();
  return await repo.getEstadosPrestamo();
});

final tiposPagoPrestamoProvider = FutureProvider<List<TipoPrestamoEntity>>((
  ref,
) async {
  final repo = PrestamoImpl();
  return await repo.getTiposPagoPrestamo();
});

final reporteCuotasProvider = FutureProvider.family<Uint8List, int>((
  ref,
  codPrestamo,
) async {
  final repo = PrestamoImpl();
  return await repo.getReporteCuotas(codPrestamo);
});

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER DE TOTAL
// ══════════════════════════════════════════════════════════════════════════════
final prestamosTotalProvider = FutureProvider.autoDispose.family<
  double,
  ({int? codEmpresa, String? fechaDesde, String? fechaHasta})
>((ref, args) async {
  final repo = PrestamoImpl();
  return repo.getTotalPrestamos(
    args.codEmpresa,
    args.fechaDesde,
    args.fechaHasta,
  );
});

final prestamosTotalSAPProvider = FutureProvider.autoDispose.family<
  double,
  ({int? codEmpresa, String? fechaDesde, String? fechaHasta})
>((ref, args) async {
  final repo = PrestamoImpl();
  return repo.getTotalPrestamosSAP(
    args.codEmpresa,
    args.fechaDesde,
    args.fechaHasta,
  );
});

// ══════════════════════════════════════════════════════════════════════════════
// LISTA PAGINADA DE PRESTAMOS VIGENTES O BANDEJA SAP
// ══════════════════════════════════════════════════════════════════════════════
// ESTADO UNIFICADO DE PRESTAMOS
// ─────────────────────────────────────────────
class PrestamoState {
  final List<PrestamoEntity> items;
  final bool cargando;
  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final String search;
  final String? mes;
  final String? anio;
  final int totalRegistros;
  final String? mensajeError;
  final String estadoFiltro;
  final int? codEmpleadoFiltro;

  const PrestamoState({
    this.items = const [],
    this.cargando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.search = '',
    this.mes,
    this.anio,
    this.totalRegistros = 0,
    this.mensajeError,
    this.estadoFiltro = 'TODOS',
    this.codEmpleadoFiltro,
  });

  PrestamoState copyWith({
    List<PrestamoEntity>? items,
    bool? cargando,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    String? search,
    String? mes,
    String? anio,
    int? totalRegistros,
    String? mensajeError,
    String? estadoFiltro,
    int? codEmpleadoFiltro,
    bool clearCodEmpleado = false,
    bool clearError = false,
  }) => PrestamoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: clearError ? null : (mensajeError ?? this.mensajeError),
    estadoFiltro: estadoFiltro ?? this.estadoFiltro,
    codEmpleadoFiltro:
        clearCodEmpleado ? null : (codEmpleadoFiltro ?? this.codEmpleadoFiltro),
  );
}

class PrestamoNotifier extends StateNotifier<PrestamoState> {
  final PrestamoImpl _repo;
  PrestamoImpl get repo => _repo;
  final int codEmpresa;
  final Ref ref;
  final bool isVigentes;

  PrestamoNotifier(
    this._repo,
    this.codEmpresa,
    this.ref, {
    this.isVigentes = false,
  }) : super(const PrestamoState()) {
    final estadoDefault = isVigentes ? 'PEN' : 'TODOS';
    final now = DateTime.now();
    state = state.copyWith(
      estadoFiltro: estadoDefault,
      mes: now.month.toString(),
      anio: now.year.toString(),
    );
    cargar();
  }

  Future<void> cargar({
    int? pagina,
    String? search,
    int? codEmpleado,
    bool clearCodEmpleado = false,
  }) async {
    if (state.cargando) return;

    final p = pagina ?? state.pagina;
    final s = search ?? state.search;
    final c =
        clearCodEmpleado ? null : (codEmpleado ?? state.codEmpleadoFiltro);

    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      search: s,
      pagina: p,
      codEmpleadoFiltro: c,
      clearCodEmpleado: clearCodEmpleado,
    );

    try {
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;

      String? fDesde;
      String? fHasta;
      if (state.mes != null && state.anio != null) {
        final mesStr = state.mes!.padLeft(2, '0');
        final d = DateTime.tryParse('${state.anio}-$mesStr-01');
        if (d != null) {
          fDesde = '${state.anio}-$mesStr-01';
          final ultimoDia = DateTime(d.year, d.month + 1, 0).day;
          fHasta = '${state.anio}-$mesStr-$ultimoDia';
        }
      }

      final fDesdeSQL = isVigentes ? null : fDesde;
      final fHastaSQL = isVigentes ? null : fHasta;

      final data =
          isVigentes
              ? await _repo.getPrestamosVigentes(
                p,
                state.tamanoPagina,
                empFiltro,
                s,
                fDesdeSQL,
                fHastaSQL,
                state.estadoFiltro,
                c,
              )
              : await _repo.getPrestamosSAP(
                p,
                state.tamanoPagina,
                empFiltro,
                s,
                fDesdeSQL,
                fHastaSQL,
                state.estadoFiltro,
                c,
              );

      if (!mounted) return;

      final totalRegs = data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0;
      final totalPags = data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1;

      state = state.copyWith(
        cargando: false,
        items: data,
        totalRegistros: totalRegs,
        totalPaginas: totalPags,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        mensajeError: 'Error al cargar préstamos: $e',
      );
    }
  }

  void cambiarTamanoPagina(int size) {
    state = state.copyWith(tamanoPagina: size, pagina: 1);
    cargar();
  }

  void setFechaFiltro({String? mes, String? anio}) {
    state = state.copyWith(
      mes: mes ?? state.mes,
      anio: anio ?? state.anio,
      pagina: 1,
    );
    cargar();
  }

  void filtrarEstado(String estado) {
    state = state.copyWith(estadoFiltro: estado, pagina: 1);
    cargar();
  }

  Future<String> asignarMasivo({
    required PrestamoEntity sapRecord,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    int forzar = 0,
    String? xmlCuotas,
    String? tipoCalculo,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.asignarPrestamosMasivo(
        sapRecord: sapRecord,
        xmlEmpleados: xmlEmpleados,
        fecIniPago: fecIniPago,
        numCuotas: numCuotas,
        audUsuarioI: audUsuarioI,
        tipoPago: tipoPago,
        forzar: forzar,
        xmlCuotas: xmlCuotas,
        tipoCalculo: tipoCalculo,
      );
      state = state.copyWith(cargando: false);
      if (mounted) cargar();
      return resp.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> crearManualMasivo({
    required int codEmpresa,
    required String db,
    required double montoPrestamo,
    required String descripcion,
    required DateTime fechaDesembolso,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    int forzar = 0,
    String? xmlCuotas,
    String? tipoCalculo,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.crearPrestamoManualMasivo(
        codEmpresa: codEmpresa,
        db: db,
        montoPrestamo: montoPrestamo,
        descripcion: descripcion,
        fechaDesembolso: fechaDesembolso,
        xmlEmpleados: xmlEmpleados,
        fecIniPago: fecIniPago,
        numCuotas: numCuotas,
        audUsuarioI: audUsuarioI,
        tipoPago: tipoPago,
        forzar: forzar,
        xmlCuotas: xmlCuotas,
        tipoCalculo: tipoCalculo,
      );
      state = state.copyWith(cargando: false);
      if (mounted) cargar();
      return resp.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> actualizarCuotaPrestamo({
    required int codPrestDetalle,
    required int codPrestamo,
    required String tipoPago,
    required DateTime fechaPago,
    required int audUsuario,
    String? estadoCuota,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.actualizarCuotaPrestamo(
        codPrestDetalle: codPrestDetalle,
        tipoPago: tipoPago,
        fechaPago: fechaPago,
        audUsuario: audUsuario,
        estadoCuota: estadoCuota,
      );
      state = state.copyWith(cargando: false);
      if (mounted) {
        ref.invalidate(reporteCuotasProvider(codPrestamo));
        ref.invalidate(
          prestamoDetallesProvider((
            codPrestamo: codPrestamo,
            mostrarAnulados: 0,
          )),
        );
        cargar();
      }
      return resp.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> anularPrestamo({
    required int codPrestamo,
    required int audUsuario,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final msg = await _repo.anularPrestamo(
        codPrestamo: codPrestamo,
        audUsuario: audUsuario,
      );
      state = state.copyWith(cargando: false);
      if (mounted) {
        ref.invalidate(reporteCuotasProvider(codPrestamo));
        cargar();
      }
      return msg;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> adelantarCuotaPrestamo({
    required int codPrestamo,
    required double montoPago,
    required DateTime fechaPago,
    required String detalle,
    required int audUsuario,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.adelantarCuotaPrestamo(
        codPrestamo: codPrestamo,
        montoPago: montoPago,
        fechaPago: fechaPago,
        detalle: detalle,
        audUsuario: audUsuario,
      );
      state = state.copyWith(cargando: false);
      if (mounted) {
        ref.invalidate(reporteCuotasProvider(codPrestamo));
        ref.invalidate(
          prestamoDetallesProvider((
            codPrestamo: codPrestamo,
            mostrarAnulados: 0,
          )),
        );
        cargar();
      }
      return resp.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> editarPrestamoMasivo({
    required int codEmpresa,
    required String db,
    required int transIdSAP,
    required String xmlEmpleados,
    required int audUsuarioI,
    required double montoPrestamo,
    String? descripcion,
    DateTime? fechaDesembolso,
    int forzar = 0,
    String? xmlCuotas,
    String? tipoCalculo,
  }) async {
    state = state.copyWith(cargando: true);
    try {
      final res = await _repo.editarPrestamoMasivo(
        codEmpresa: codEmpresa,
        db: db,
        transIdSAP: transIdSAP,
        xmlEmpleados: xmlEmpleados,
        audUsuarioI: audUsuarioI,
        montoPrestamo: montoPrestamo,
        descripcion: descripcion,
        fechaDesembolso: fechaDesembolso,
        forzar: forzar,
        xmlCuotas: xmlCuotas,
        tipoCalculo: tipoCalculo,
      );
      state = state.copyWith(cargando: false);
      if (mounted) {
        ref.invalidate(prestamoEmpleadosAsignadosProvider);
        cargar();
      }
      return res.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<String> asignarPagos(List<PrestamoDetalleEntity> pagos) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.asignarPagos(pagos);
      state = state.copyWith(cargando: false);
      if (mounted) cargar();
      return resp.message;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }

  Future<PrestamoResponse> revertirPagoMasivo({
    required int codPrestDetalle,
    required int audUsuario,
    required int codPrestamo,
  }) async {
    try {
      state = state.copyWith(cargando: true, clearError: true);
      final resp = await _repo.revertirPagoMasivo(
        codPrestDetalle: codPrestDetalle,
        audUsuario: audUsuario,
      );
      state = state.copyWith(cargando: false);

      // Invalidate to refresh the list of payments
      ref.invalidate(
        prestamoDetallesProvider((
          codPrestamo: codPrestamo,
          mostrarAnulados: 0,
        )),
      );
      ref.invalidate(
        prestamoDetallesProvider((
          codPrestamo: codPrestamo,
          mostrarAnulados: 1,
        )),
      );

      if (mounted) cargar();
      return resp;
    } catch (e) {
      if (mounted)
        state = state.copyWith(cargando: false, mensajeError: e.toString());
      rethrow;
    }
  }
}

final prestamoProvider = StateNotifierProvider.family
    .autoDispose<PrestamoNotifier, PrestamoState, int>((ref, codEmpresa) {
      return PrestamoNotifier(
        PrestamoImpl(),
        codEmpresa,
        ref,
        isVigentes: false,
      );
    });

final prestamoVigentesProvider = StateNotifierProvider.family
    .autoDispose<PrestamoNotifier, PrestamoState, int>((ref, codEmpresa) {
      return PrestamoNotifier(
        PrestamoImpl(),
        codEmpresa,
        ref,
        isVigentes: true,
      );
    });

final searchEmpleadoPrestamoProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final prestamoVigentesPorEmpleadoProvider = FutureProvider.family
    .autoDispose<List<PrestamoEntity>, int>((ref, codEmpresa) async {
      final repo = PrestamoImpl();
      final search = ref.watch(searchEmpleadoPrestamoProvider);
      return await repo.getPrestamosVigentesPorEmpleado(codEmpresa, search);
    });

final prestamoDetallesProvider = FutureProvider.family.autoDispose<
  List<PrestamoDetalleEntity>,
  ({int codPrestamo, int mostrarAnulados})
>((ref, args) async {
  final repo = PrestamoImpl();
  return await repo.listarDetallesPrestamo(
    args.codPrestamo,
    args.mostrarAnulados,
  );
});

final prestamoEmpleadosAsignadosProvider = FutureProvider.family.autoDispose<
  List<PrestamoEntity>,
  ({int codEmpresa, String db, int transIdSAP, int? codPrestamo})
>((ref, args) async {
  final repo = PrestamoImpl();
  return await repo.listarEmpleadosAsignados(
    codEmpresa: args.codEmpresa,
    db: args.db,
    transIdSAP: args.transIdSAP,
    codPrestamo: args.codPrestamo,
  );
});
