// control_combustible_maquina_montacarga_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/control_combustible_maquina_montacarga_impl.dart';
import 'package:bosque_flutter/domain/entities/compra_garrafa_entity.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/contenedor_entity.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_maquina_montacarga_repository.dart';

enum RegistroStatus { initial, loading, success, error }

enum FetchStatus { initial, loading, success, error }

class RegistroState {
  final RegistroStatus registroStatus;
  final FetchStatus almacenesStatus;
  final FetchStatus maquinasStatus;
  final FetchStatus bidonesStatus;
  final FetchStatus reporteStatus;
  final FetchStatus bidonesSucursalStatus;
  final FetchStatus ultimosMovimientosStatus;
  final FetchStatus
  bidonesPendientesStatus; // Nuevo estado para bidones pendientes
  final String? errorMessage;
  final List<ControlCombustibleMaquinaMontacargaEntity> almacenes;
  final List<MaquinaMontacargaEntity> maquinasMontacarga;
  final List<ControlCombustibleMaquinaMontacargaEntity> bidones;
  final List<ControlCombustibleMaquinaMontacargaEntity> reporteMovimientos;
  final List<ControlCombustibleMaquinaMontacargaEntity> bidonesSucursal;
  final List<ControlCombustibleMaquinaMontacargaEntity> ultimosMovimientos;
  final List<ControlCombustibleMaquinaMontacargaEntity>
  bidonesPendientes; // Nueva lista para bidones pendientes

  RegistroState({
    required this.registroStatus,
    required this.almacenesStatus,
    required this.maquinasStatus,
    required this.bidonesStatus,
    required this.reporteStatus,
    required this.bidonesSucursalStatus,
    required this.ultimosMovimientosStatus,
    required this.bidonesPendientesStatus,
    this.errorMessage,
    required this.almacenes,
    required this.maquinasMontacarga,
    required this.bidones,
    required this.reporteMovimientos,
    required this.bidonesSucursal,
    required this.ultimosMovimientos,
    required this.bidonesPendientes,
  });

  RegistroState copyWith({
    RegistroStatus? registroStatus,
    FetchStatus? almacenesStatus,
    FetchStatus? maquinasStatus,
    FetchStatus? bidonesStatus,
    FetchStatus? reporteStatus,
    FetchStatus? bidonesSucursalStatus,
    FetchStatus? ultimosMovimientosStatus,
    FetchStatus? bidonesPendientesStatus,
    String? errorMessage,
    List<ControlCombustibleMaquinaMontacargaEntity>? almacenes,
    List<MaquinaMontacargaEntity>? maquinasMontacarga,
    List<ControlCombustibleMaquinaMontacargaEntity>? bidones,
    List<ControlCombustibleMaquinaMontacargaEntity>? reporteMovimientos,
    List<ControlCombustibleMaquinaMontacargaEntity>? bidonesSucursal,
    List<ControlCombustibleMaquinaMontacargaEntity>? ultimosMovimientos,
    List<ControlCombustibleMaquinaMontacargaEntity>? bidonesPendientes,
  }) {
    return RegistroState(
      registroStatus: registroStatus ?? this.registroStatus,
      almacenesStatus: almacenesStatus ?? this.almacenesStatus,
      maquinasStatus: maquinasStatus ?? this.maquinasStatus,
      bidonesStatus: bidonesStatus ?? this.bidonesStatus,
      reporteStatus: reporteStatus ?? this.reporteStatus,
      bidonesSucursalStatus:
          bidonesSucursalStatus ?? this.bidonesSucursalStatus,
      ultimosMovimientosStatus:
          ultimosMovimientosStatus ?? this.ultimosMovimientosStatus,
      bidonesPendientesStatus:
          bidonesPendientesStatus ?? this.bidonesPendientesStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      almacenes: almacenes ?? this.almacenes,
      maquinasMontacarga: maquinasMontacarga ?? this.maquinasMontacarga,
      bidones: bidones ?? this.bidones,
      reporteMovimientos: reporteMovimientos ?? this.reporteMovimientos,
      bidonesSucursal: bidonesSucursal ?? this.bidonesSucursal,
      ultimosMovimientos: ultimosMovimientos ?? this.ultimosMovimientos,
      bidonesPendientes: bidonesPendientes ?? this.bidonesPendientes,
    );
  }

  factory RegistroState.initial() => RegistroState(
    registroStatus: RegistroStatus.initial,
    almacenesStatus: FetchStatus.initial,
    maquinasStatus: FetchStatus.initial,
    bidonesStatus: FetchStatus.initial,
    reporteStatus: FetchStatus.initial,
    bidonesSucursalStatus: FetchStatus.initial,
    ultimosMovimientosStatus: FetchStatus.initial,
    bidonesPendientesStatus: FetchStatus.initial,
    almacenes: [],
    maquinasMontacarga: [],
    bidones: [],
    reporteMovimientos: [],
    bidonesSucursal: [],
    ultimosMovimientos: [],
    bidonesPendientes: [],
  );
}

class ControlCombustibleMaquinaMontacargaNotifier
    extends StateNotifier<RegistroState> {
  final ControlCombustibleMaquinaMontacargaRepository _repository;

  ControlCombustibleMaquinaMontacargaNotifier(this._repository)
    : super(RegistroState.initial());

  Future<void> registrarControlCombustible(
    ControlCombustibleMaquinaMontacargaEntity datos,
  ) async {
    state = state.copyWith(registroStatus: RegistroStatus.loading);

    try {
      final result = await _repository
          .registerControlCombustibleMaquinaMontacarga(datos);

      if (result) {
        state = state.copyWith(
          registroStatus: RegistroStatus.success,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          registroStatus: RegistroStatus.error,
          errorMessage: 'Error al registrar el control de combustible',
        );
      }
    } catch (e) {
      state = state.copyWith(
        registroStatus: RegistroStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarAlmacenes() async {
    state = state.copyWith(almacenesStatus: FetchStatus.loading);

    try {
      final almacenes = await _repository.obtenerAlmacenes();

      state = state.copyWith(
        almacenesStatus: FetchStatus.success,
        almacenes: almacenes,
      );
    } catch (e) {
      state = state.copyWith(
        almacenesStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarMaquinasMontacargas() async {
    state = state.copyWith(maquinasStatus: FetchStatus.loading);

    try {
      final maquinas = await _repository.obtenerMaquinasMontacargas();

      state = state.copyWith(
        maquinasStatus: FetchStatus.success,
        maquinasMontacarga: maquinas,
      );
    } catch (e) {
      state = state.copyWith(
        maquinasStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarReporteMovimientos(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codSucursal,
  ) async {
    state = state.copyWith(reporteStatus: FetchStatus.loading);

    try {
      final reporte = await _repository.lstRptMovBidonesXTipoTransaccion(
        fechaInicio,
        fechaFin,
        codSucursal,
      );

      state = state.copyWith(
        reporteStatus: FetchStatus.success,
        reporteMovimientos: reporte,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        reporteStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarBidonesPorSucursal() async {
    state = state.copyWith(bidonesSucursalStatus: FetchStatus.loading);

    try {
      final bidonesSucursal = await _repository.lstBidonesXSucursal();

      state = state.copyWith(
        bidonesSucursalStatus: FetchStatus.success,
        bidonesSucursal: bidonesSucursal,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        bidonesSucursalStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarUltimosMovimientos() async {
    state = state.copyWith(ultimosMovimientosStatus: FetchStatus.loading);

    try {
      final ultimosMovimientos = await _repository.lstBidonesUltimosMov();

      state = state.copyWith(
        ultimosMovimientosStatus: FetchStatus.success,
        ultimosMovimientos: ultimosMovimientos,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        ultimosMovimientosStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarBidonesPendientes(int codSucursalMaqVehiDestino) async {
    state = state.copyWith(bidonesPendientesStatus: FetchStatus.loading);

    try {
      final bidonesPendientes = await _repository.listBidonesPendientes(
        codSucursalMaqVehiDestino,
      );

      state = state.copyWith(
        bidonesPendientesStatus: FetchStatus.success,
        bidonesPendientes: bidonesPendientes,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        bidonesPendientesStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetRegistroStatus() {
    state = state.copyWith(registroStatus: RegistroStatus.initial);
  }
}

// Mantenemos el provider original
final controlCombustibleMaquinaMontacargaProvider =
    Provider<ControlCombustibleMaquinaMontacargaRepository>((ref) {
      return ControlCombustibleMaquinaMontacargaImpl();
    });

final controlCombustibleMaquinaMontacargaNotifierProvider =
    StateNotifierProvider<
      ControlCombustibleMaquinaMontacargaNotifier,
      RegistroState
    >((ref) {
      final repository = ref.watch(controlCombustibleMaquinaMontacargaProvider);
      return ControlCombustibleMaquinaMontacargaNotifier(repository);
    });

// Providers adicionales para acceder directamente a los almacenes y máquinas
final almacenesProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .almacenes;
    });

final maquinasMontacargaProvider = Provider<List<MaquinaMontacargaEntity>>((
  ref,
) {
  return ref
      .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
      .maquinasMontacarga;
});

// Nuevo provider para acceder directamente a los bidones
final bidonesMaquinaProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .bidones;
    });

// Nuevo provider para acceder directamente al reporte de movimientos
final reporteMovimientosProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .reporteMovimientos;
    });

// Nuevo provider para acceder directamente a los bidones por sucursal
final bidonesSucursalProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .bidonesSucursal;
    });

// Nuevo provider para acceder directamente a los últimos movimientos
final ultimosMovimientosProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .ultimosMovimientos;
    });

// Provider para listBidonesPendientes usando FutureProvider.family
final listBidonesPendientesProvider =
    FutureProvider.family<List<ControlCombustibleMaquinaMontacargaEntity>, int>(
      (ref, codSucursalMaqVehiDestino) async {
        final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
        return await repo.listBidonesPendientes(codSucursalMaqVehiDestino);
      },
    );

// Nuevo provider para acceder directamente a los bidones pendientes desde el state
final bidonesPendientesProvider =
    Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
      return ref
          .watch(controlCombustibleMaquinaMontacargaNotifierProvider)
          .bidonesPendientes;
    });

// Provider para listDetalleBidon usando FutureProvider.family
final listDetalleBidonProvider = FutureProvider.family<
  List<ControlCombustibleMaquinaMontacargaEntity>,
  dynamic
>((ref, idCM) async {
  final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
  return await repo.listDetalleBidon(idCM);
});

// Provider para lstSucursal
final sucursalesProvider = FutureProvider<List<SucursalEntity>>((ref) async {
  final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
  return await repo.lstSucursal();
});

// Provider para lstContenedores
final contenedoresProvider = FutureProvider<List<ContenedorEntity>>((
  ref,
) async {
  final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
  return await repo.lstContenedores();
});

// Provider para registrar movimiento
final registrarMovimientoProvider =
    FutureProvider.family<bool, MovimientoEntity>((ref, movimiento) async {
      final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
      return await repo.registerMovimiento(movimiento);
    });

// Provider para registrar garrafa
final registrarGarrafaProvider =
    FutureProvider.family<bool, CompraGarrafaEntity>((ref, garrafa) async {
      final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
      return await repo.registerCompraGarrafa(garrafa);
    });
