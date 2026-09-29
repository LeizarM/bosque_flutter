import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/prestamo_vehiculos_impl.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';
import 'package:bosque_flutter/data/repositories/entregas_impl.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

enum FetchStatus { initial, loading, success, error }

final prestamoVehiculosProvider = Provider<PrestamoVehiculosImpl>((ref) {
  return PrestamoVehiculosImpl();
});

final tipoSolicitudesProvider = FutureProvider<List<TipoSolicitudEntity>>((
  ref,
) async {
  final repository = ref.watch(prestamoVehiculosProvider);
  return await repository.lstTipoSolicitudes();
});

final cochesDisponiblesProvider = FutureProvider<List<SolicitudChoferEntity>>((
  ref,
) async {
  final repository = ref.watch(prestamoVehiculosProvider);
  return await repository.obtainCoches();
});

// Provider para entregas - para obtener choferes
final entregasProvider = Provider<EntregasImpl>((ref) {
  return EntregasImpl();
});

// Estado para las solicitudes del empleado
class SolicitudesState {
  final FetchStatus status;
  final List<SolicitudChoferEntity> solicitudes;
  final String? errorMessage;

  SolicitudesState({
    required this.status,
    required this.solicitudes,
    this.errorMessage,
  });

  SolicitudesState copyWith({
    FetchStatus? status,
    List<SolicitudChoferEntity>? solicitudes,
    String? errorMessage,
  }) {
    return SolicitudesState(
      status: status ?? this.status,
      solicitudes: solicitudes ?? this.solicitudes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory SolicitudesState.initial() =>
      SolicitudesState(status: FetchStatus.initial, solicitudes: []);
}

// Notifier para manejar las solicitudes del empleado
class SolicitudesNotifier extends StateNotifier<SolicitudesState> {
  final PrestamoVehiculosImpl _repository;

  SolicitudesNotifier(this._repository) : super(SolicitudesState.initial());

  Future<void> cargarSolicitudesEmpleado(int codEmpleado) async {
    state = state.copyWith(status: FetchStatus.loading);

    try {
      final solicitudes = await _repository.obtainSolicitudes(codEmpleado);

      state = state.copyWith(
        status: FetchStatus.success,
        solicitudes: solicitudes,
        errorMessage: null,
      );
    } catch (e) {
      // Un error de "no hay datos" se trata como lista vacía; otro es un fallo real.
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('no hay') ||
          errorMessage.contains('empty') ||
          errorMessage.contains('sin datos') ||
          errorMessage.contains('no encontrado') ||
          errorMessage.contains('no solicitudes') ||
          errorMessage.contains('obtain solicitudes')) {
        state = state.copyWith(
          status: FetchStatus.success,
          solicitudes: [],
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: FetchStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }
}

// Provider para las solicitudes del empleado con estado de carga
final solicitudesNotifierProvider =
    StateNotifierProvider<SolicitudesNotifier, SolicitudesState>((ref) {
      final repository = ref.watch(prestamoVehiculosProvider);
      return SolicitudesNotifier(repository);
    });

final registroSolicitudProvider =
    StateNotifierProvider<RegistroSolicitudNotifier, AsyncValue<bool>>((ref) {
      final repository = ref.watch(prestamoVehiculosProvider);
      return RegistroSolicitudNotifier(repository);
    });

class RegistroSolicitudNotifier extends StateNotifier<AsyncValue<bool>> {
  final PrestamoVehiculosImpl _repository;

  RegistroSolicitudNotifier(this._repository)
    : super(const AsyncValue.data(false));

  Future<bool> registrarSolicitud(SolicitudChoferEntity solicitud) async {
    state = const AsyncValue.loading();
    try {
      // fechaSolicitud es un marcador (el backend la ignora) y
      // fechaSolicitudCad va vacía: la calcula el backend.
      final solicitudParaBackend = SolicitudChoferEntity(
        idSolicitud: solicitud.idSolicitud,
        fechaSolicitud:
            DateTime.now(),
        motivo: solicitud.motivo,
        codEmpSoli: solicitud.codEmpSoli,
        cargo: solicitud.cargo,
        estado: solicitud.estado,
        idCocheSol: solicitud.idCocheSol,
        idES: solicitud.idES,
        requiereChofer: solicitud.requiereChofer,
        audUsuario: solicitud.audUsuario,
        fechaSolicitudCad: '',
        estadoCad: solicitud.estadoCad,
        codSucursal: solicitud.codSucursal,
        coche: solicitud.coche,
      );

      final result = await _repository.registerSolicitudChofer(
        solicitudParaBackend,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Estado para las solicitudes de préstamos (para administradores)
class SolicitudesPrestamosState {
  final FetchStatus status;
  final List<PrestamoChoferEntity> solicitudesPrestamos;
  final String? errorMessage;
  final FetchStatus choferesStatus;
  final List<EntregaEntity> choferes;

  SolicitudesPrestamosState({
    required this.status,
    required this.solicitudesPrestamos,
    this.errorMessage,
    required this.choferesStatus,
    required this.choferes,
  });

  SolicitudesPrestamosState copyWith({
    FetchStatus? status,
    List<PrestamoChoferEntity>? solicitudesPrestamos,
    String? errorMessage,
    FetchStatus? choferesStatus,
    List<EntregaEntity>? choferes,
  }) {
    return SolicitudesPrestamosState(
      status: status ?? this.status,
      solicitudesPrestamos: solicitudesPrestamos ?? this.solicitudesPrestamos,
      errorMessage: errorMessage ?? this.errorMessage,
      choferesStatus: choferesStatus ?? this.choferesStatus,
      choferes: choferes ?? this.choferes,
    );
  }

  factory SolicitudesPrestamosState.initial() => SolicitudesPrestamosState(
    status: FetchStatus.initial,
    solicitudesPrestamos: [],
    choferesStatus: FetchStatus.initial,
    choferes: [],
  );
}

// Notifier para manejar las solicitudes de préstamos
class SolicitudesPrestamosNotifier
    extends StateNotifier<SolicitudesPrestamosState> {
  final PrestamoVehiculosImpl _repository;
  final EntregasImpl _entregasRepository;

  SolicitudesPrestamosNotifier(this._repository, this._entregasRepository)
    : super(SolicitudesPrestamosState.initial());

  Future<void> cargarSolicitudesPrestamos(
    int codSucursal,
    int codEmpEntregadoPor,
  ) async {
    state = state.copyWith(status: FetchStatus.loading);

    try {
      final solicitudes = await _repository.lstSolicitudesPretamos(
        codSucursal,
        codEmpEntregadoPor,
      );

      state = state.copyWith(
        status: FetchStatus.success,
        solicitudesPrestamos: solicitudes,
        errorMessage: null,
      );
    } catch (e) {
      // Un error de "no hay datos" se trata como lista vacía; otro es un fallo real.
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('no hay') ||
          errorMessage.contains('empty') ||
          errorMessage.contains('sin datos') ||
          errorMessage.contains('no encontrado')) {
        state = state.copyWith(
          status: FetchStatus.success,
          solicitudesPrestamos: [],
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: FetchStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> cargarChoferes() async {
    state = state.copyWith(choferesStatus: FetchStatus.loading);

    try {
      final choferes = await _entregasRepository.getChoferes();

      state = state.copyWith(
        choferesStatus: FetchStatus.success,
        choferes: choferes,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        choferesStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> registrarEntregaPrestamo(
    Map<String, dynamic> datosEntrega,
  ) async {
    try {
      // fechaEntrega es un marcador (el backend la ignora) y
      // estadoLateralesEntrega lo calcula el backend.
      final prestamoEntity = PrestamoChoferEntity(
        idPrestamo: datosEntrega["idPrestamo"] ?? 0,
        idCoche: datosEntrega["idCoche"] ?? 0,
        idSolicitud: datosEntrega["idSolicitud"] ?? 0,
        codSucursal: datosEntrega["codSucursal"] ?? 0,
        fechaEntrega:
            DateTime.now(),
        codEmpChoferSolicitado: datosEntrega["codEmpChoferSolicitado"] ?? 0,
        codEmpEntregadoPor: datosEntrega["codEmpEntregadoPor"] ?? 0,
        kilometrajeEntrega:
            datosEntrega["kilometrajeEntrega"]?.toDouble() ?? 0.0,
        kilometrajeRecepcion:
            datosEntrega["kilometrajeRecepcion"]?.toDouble() ?? 0.0,
        nivelCombustibleEntrega: datosEntrega["nivelCombustibleEntrega"] ?? 0,
        nivelCombustibleRecepcion:
            datosEntrega["nivelCombustibleRecepcion"] ?? 0,
        estadoLateralesEntrega: 0,
        estadoInteriorEntrega: 0,
        estadoDelanteraEntrega: 0,
        estadoTraseraEntrega: 0,
        estadoCapoteEntrega: 0,
        estadoLateralRecepcion: 0,
        estadoInteriorRecepcion: 0,
        estadoDelanteraRecepcion: 0,
        estadoTraseraRecepcion: 0,
        estadoCapoteRecepcion: 0,
        audUsuario: datosEntrega["audUsuario"] ?? 0,
        fechaSolicitud: '',
        motivo: '',
        solicitante: '',
        cargo: '',
        coche: '',
        estadoDisponibilidad: '',
        requiereChofer: 0,
        // Los estados viajan como string en los campos Aux, que es lo que procesa el backend.
        estadoLateralesEntregaAux:
            datosEntrega["estadoLateralesEntregaAux"] ?? '',
        estadoInteriorEntregaAux:
            datosEntrega["estadoInteriorEntregaAux"] ?? '',
        estadoDelanteraEntregaAux:
            datosEntrega["estadoDelanteraEntregaAux"] ?? '',
        estadoTraseraEntregaAux: datosEntrega["estadoTraseraEntregaAux"] ?? '',
        estadoCapoteEntregaAux: datosEntrega["estadoCapoteEntregaAux"] ?? '',
        estadoLateralRecepcionAux: '',
        estadoInteriorRecepcionAux: '',
        estadoDelanteraRecepcionAux: '',
        estadoTraseraRecepcionAux: '',
        estadoCapoteRecepcionAux: '',
      );

      final result = await _repository.registerPrestamo(prestamoEntity);

      if (result) {
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registrarRecepcionPrestamo(
    Map<String, dynamic> datosRecepcion,
  ) async {
    try {
      // Recepción: solo se llenan los campos de recepción; el resto va en 0. El
      // backend ignora fechaEntrega y calcula estadoLateralRecepcion.
      final prestamoEntity = PrestamoChoferEntity(
        idPrestamo: datosRecepcion["idPrestamo"] ?? 0,
        idCoche: 0,
        idSolicitud: 0,
        codSucursal: 0,
        fechaEntrega:
            DateTime.now(),
        codEmpChoferSolicitado: 0,
        codEmpEntregadoPor: 0,
        kilometrajeEntrega: 0.0,
        kilometrajeRecepcion:
            datosRecepcion["kilometrajeRecepcion"]?.toDouble() ?? 0.0,
        nivelCombustibleEntrega: 0,
        nivelCombustibleRecepcion:
            datosRecepcion["nivelCombustibleRecepcion"] ?? 0,
        estadoLateralesEntrega: 0,
        estadoInteriorEntrega: 0,
        estadoDelanteraEntrega: 0,
        estadoTraseraEntrega: 0,
        estadoCapoteEntrega: 0,
        estadoLateralRecepcion: 0,
        estadoInteriorRecepcion: 0,
        estadoDelanteraRecepcion: 0,
        estadoTraseraRecepcion: 0,
        estadoCapoteRecepcion: 0,
        audUsuario: datosRecepcion["audUsuario"] ?? 0,
        fechaSolicitud: '',
        motivo: '',
        solicitante: '',
        cargo: '',
        coche: '',
        estadoDisponibilidad: '',
        requiereChofer: 0,
        estadoLateralesEntregaAux: '',
        estadoInteriorEntregaAux: '',
        estadoDelanteraEntregaAux: '',
        estadoTraseraEntregaAux: '',
        estadoCapoteEntregaAux: '',
        // Estados de recepción como string, en los campos Aux.
        estadoLateralRecepcionAux:
            datosRecepcion["estadoLateralRecepcionAux"] ?? '',
        estadoInteriorRecepcionAux:
            datosRecepcion["estadoInteriorRecepcionAux"] ?? '',
        estadoDelanteraRecepcionAux:
            datosRecepcion["estadoDelanteraRecepcionAux"] ?? '',
        estadoTraseraRecepcionAux:
            datosRecepcion["estadoTraseraRecepcionAux"] ?? '',
        estadoCapoteRecepcionAux:
            datosRecepcion["estadoCapoteRecepcionAux"] ?? '',
      );

      final result = await _repository.registerPrestamo(prestamoEntity);

      if (result) {
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> aprobarSolicitud(int idSolicitud) async {
    try {
      // Obtener el código de usuario para auditoría
      final userNotifier = UserStateNotifier();
      final audUsuario = await userNotifier.getCodUsuario();

      final solicitudEntity = SolicitudChoferEntity(
        idSolicitud: idSolicitud,
        fechaSolicitud: DateTime.now(), // Será ignorado por el backend
        motivo: '',
        codEmpSoli: 0,
        cargo: '',
        estado: 2, // Estado aprobado
        idCocheSol: 0,
        idES: 0,
        requiereChofer: 0,
        audUsuario: audUsuario,
        fechaSolicitudCad: '',
        estadoCad: '',
        codSucursal: 0,
        coche: '',
      );

      final result = await _repository.actualizarSolicitud(solicitudEntity);

      if (result) {
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> rechazarSolicitud(int idSolicitud) async {
    try {
      // Obtener el código de usuario para auditoría
      final userNotifier = UserStateNotifier();
      final audUsuario = await userNotifier.getCodUsuario();

      final solicitudEntity = SolicitudChoferEntity(
        idSolicitud: idSolicitud,
        fechaSolicitud: DateTime.now(), // Será ignorado por el backend
        motivo: '',
        codEmpSoli: 0,
        cargo: '',
        estado: 3, // Estado rechazado
        idCocheSol: 0,
        idES: 0,
        requiereChofer: 0,
        audUsuario: audUsuario,
        fechaSolicitudCad: '',
        estadoCad: '',
        codSucursal: 0,
        coche: '',
      );

      final result = await _repository.actualizarSolicitud(solicitudEntity);

      if (result) {
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

// Provider para las solicitudes de préstamos con estado de carga
final solicitudesPrestamosNotifierProvider = StateNotifierProvider<
  SolicitudesPrestamosNotifier,
  SolicitudesPrestamosState
>((ref) {
  final repository = ref.watch(prestamoVehiculosProvider);
  final entregasRepository = ref.watch(entregasProvider);
  return SolicitudesPrestamosNotifier(repository, entregasRepository);
});
