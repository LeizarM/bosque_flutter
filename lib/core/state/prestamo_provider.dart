import 'dart:typed_data';
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
    this.estadoFiltro = 'TODOS',
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

// ─────────────────────────────────────────────
// ESTADO UNIFICADO DE PRESTAMOS
// ─────────────────────────────────────────────
class PrestamoState {
  final List<PrestamoEntity> items;
  final bool cargando;
  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final String search;
  final String? fechaDesde;
  final String? fechaHasta;
  final int totalRegistros;
  final String? mensajeError;
  final String estadoFiltro;

  const PrestamoState({
    this.items = const [],
    this.cargando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.search = '',
    this.fechaDesde,
    this.fechaHasta,
    this.totalRegistros = 0,
    this.mensajeError,
    this.estadoFiltro = 'TODOS',
  });

  PrestamoState copyWith({
    List<PrestamoEntity>? items,
    bool? cargando,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    String? search,
    String? fechaDesde,
    String? fechaHasta,
    int? totalRegistros,
    String? mensajeError,
    String? estadoFiltro,
  }) => PrestamoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
    fechaDesde: fechaDesde ?? this.fechaDesde,
    fechaHasta: fechaHasta ?? this.fechaHasta,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError ?? this.mensajeError,
    estadoFiltro: estadoFiltro ?? this.estadoFiltro,
  );
}

class PrestamoNotifier extends StateNotifier<PrestamoState> {
  final PrestamoImpl _repo;
  PrestamoImpl get repo => _repo;
  final int codEmpresa;
  final Ref ref;

  PrestamoNotifier(this._repo, this.codEmpresa, this.ref)
    : super(const PrestamoState()) {
    final filtros = ref.read(_filtrosPrestamoProvider);
    state = state.copyWith(
      tamanoPagina: filtros.tamanoPagina,
      fechaDesde: filtros.fechaDesde,
      fechaHasta: filtros.fechaHasta,
      estadoFiltro: filtros.estadoFiltro,
    );
    cargar();
  }

  Future<void> cargar({int? pagina, String? search}) async {
    if (state.cargando) return;

    final p = pagina ?? state.pagina;
    final s = search ?? state.search;

    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      search: s,
      pagina: p,
    );

    try {
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;
      final data = await _repo.getPrestamosSAP(
        p,
        state.tamanoPagina,
        empFiltro,
        s,
        state.fechaDesde,
        state.fechaHasta,
        state.estadoFiltro,
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
    ref
        .read(_filtrosPrestamoProvider.notifier)
        .update((s) => s.copyWith(tamanoPagina: size));
    state = state.copyWith(tamanoPagina: size, pagina: 1);
    cargar();
  }

  void filtrarFechas(String? desde, String? hasta) {
    ref
        .read(_filtrosPrestamoProvider.notifier)
        .update((s) => s.copyWith(fechaDesde: desde, fechaHasta: hasta));
    state = state.copyWith(fechaDesde: desde, fechaHasta: hasta, pagina: 1);
    cargar();
  }

  void filtrarEstado(String estado) {
    ref
        .read(_filtrosPrestamoProvider.notifier)
        .update((s) => s.copyWith(estadoFiltro: estado));
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
  }) async {
    try {
      state = state.copyWith(cargando: true, mensajeError: null);
      final resp = await _repo.asignarPrestamosMasivo(
        sapRecord: sapRecord,
        xmlEmpleados: xmlEmpleados,
        fecIniPago: fecIniPago,
        numCuotas: numCuotas,
        audUsuarioI: audUsuarioI,
        tipoPago: tipoPago,
        forzar: forzar,
        xmlCuotas: xmlCuotas,
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
  }) async {
    try {
      state = state.copyWith(cargando: true, mensajeError: null);
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
      state = state.copyWith(cargando: true, mensajeError: null);
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
      state = state.copyWith(cargando: true, mensajeError: null);
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
      state = state.copyWith(cargando: true, mensajeError: null);
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
}

final prestamoProvider = StateNotifierProvider.family
    .autoDispose<PrestamoNotifier, PrestamoState, int>((ref, codEmpresa) {
      return PrestamoNotifier(PrestamoImpl(), codEmpresa, ref);
    });

final searchEmpleadoPrestamoProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

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
