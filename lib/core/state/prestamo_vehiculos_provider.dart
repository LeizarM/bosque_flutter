import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/prestamo_vehiculos_impl.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';
import 'package:bosque_flutter/data/repositories/entregas_impl.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

enum FetchStatus {
  initial,
  loading,
  success,
  error,
}

// Provider for the PrestamoVehiculos implementation
final prestamoVehiculosProvider = Provider<PrestamoVehiculosImpl>((ref) {
  return PrestamoVehiculosImpl();
});

// Provider for the list of vehicle types (asynchronous)
final tipoSolicitudesProvider = FutureProvider<List<TipoSolicitudEntity>>((ref) async {
  final repository = ref.watch(prestamoVehiculosProvider);
  return await repository.lstTipoSolicitudes();
});

// Provider for the list of available cars (asynchronous)
final cochesDisponiblesProvider = FutureProvider<List<SolicitudChoferEntity>>((ref) async {
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

  factory SolicitudesState.initial() => SolicitudesState(
    status: FetchStatus.initial,
    solicitudes: [],
  );
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
      state = state.copyWith(
        status: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// Provider para las solicitudes del empleado con estado de carga
final solicitudesNotifierProvider = StateNotifierProvider<SolicitudesNotifier, SolicitudesState>((ref) {
  final repository = ref.watch(prestamoVehiculosProvider);
  return SolicitudesNotifier(repository);
});

// Provider for registering a new vehicle request
final registroSolicitudProvider = StateNotifierProvider<RegistroSolicitudNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(prestamoVehiculosProvider);
  return RegistroSolicitudNotifier(repository);
});

class RegistroSolicitudNotifier extends StateNotifier<AsyncValue<bool>> {
  final PrestamoVehiculosImpl _repository;

  RegistroSolicitudNotifier(this._repository) : super(const AsyncValue.data(false));

  Future<bool> registrarSolicitud(SolicitudChoferEntity solicitud) async {
    state = const AsyncValue.loading();
    try {
      // Create a modified entity to send to backend
      // We use DateTime.now() as a placeholder, but it will be ignored by backend
      final solicitudParaBackend = SolicitudChoferEntity(
        idSolicitud: solicitud.idSolicitud,
        fechaSolicitud: DateTime.now(), // This will be ignored/calculated by backend
        motivo: solicitud.motivo,
        codEmpSoli: solicitud.codEmpSoli,
        cargo: solicitud.cargo,
        estado: solicitud.estado,
        idCocheSol: solicitud.idCocheSol,
        idES: solicitud.idES,
        requiereChofer: solicitud.requiereChofer,
        audUsuario: solicitud.audUsuario,
        fechaSolicitudCad: '', // Let the backend calculate this
        estadoCad: solicitud.estadoCad,
        codSucursal: solicitud.codSucursal,
        coche: solicitud.coche,
      );
      
      final result = await _repository.registerSolicitudChofer(solicitudParaBackend);
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
  final FetchStatus choferesStatus; // Nuevo estado para choferes
  final List<EntregaEntity> choferes; // Lista de choferes

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
class SolicitudesPrestamosNotifier extends StateNotifier<SolicitudesPrestamosState> {
  final PrestamoVehiculosImpl _repository;
  final EntregasImpl _entregasRepository;

  SolicitudesPrestamosNotifier(this._repository, this._entregasRepository) 
      : super(SolicitudesPrestamosState.initial());

  Future<void> cargarSolicitudesPrestamos(int codSucursal, int codEmpEntregadoPor) async {
    state = state.copyWith(status: FetchStatus.loading);
    
    try {
      final solicitudes = await _repository.lstSolicitudesPretamos(codSucursal, codEmpEntregadoPor);
      
      state = state.copyWith(
        status: FetchStatus.success,
        solicitudesPrestamos: solicitudes,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: FetchStatus.error,
        errorMessage: e.toString(),
      );
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

  Future<bool> registrarEntregaPrestamo(Map<String, dynamic> datosEntrega) async {
    try {
      // Crear la entity desde los datos del diálogo
      final prestamoEntity = PrestamoChoferEntity(
        idPrestamo: datosEntrega["idPrestamo"] ?? 0,
        idCoche: datosEntrega["idCoche"] ?? 0,
        idSolicitud: datosEntrega["idSolicitud"] ?? 0,
        codSucursal: datosEntrega["codSucursal"] ?? 0,
        fechaEntrega: DateTime.now(), // Placeholder - será ignorado por el backend
        codEmpChoferSolicitado: datosEntrega["codEmpChoferSolicitado"] ?? 0,
        codEmpEntregadoPor: datosEntrega["codEmpEntregadoPor"] ?? 0,
        kilometrajeEntrega: datosEntrega["kilometrajeEntrega"]?.toDouble() ?? 0.0,
        kilometrajeRecepcion: datosEntrega["kilometrajeRecepcion"]?.toDouble() ?? 0.0,
        nivelCombustibleEntrega: datosEntrega["nivelCombustibleEntrega"] ?? 0,
        nivelCombustibleRecepcion: datosEntrega["nivelCombustibleRecepcion"] ?? 0,
        estadoLateralesEntrega: 0, // Será calculado por el backend
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
        // Usar los campos Aux para enviar los estados como string
        estadoLateralesEntregaAux: datosEntrega["estadoLateralesEntrega"] ?? '',
        estadoInteriorEntregaAux: datosEntrega["estadoInteriorEntrega"] ?? '',
        estadoDelanteraEntregaAux: datosEntrega["estadoDelanteraEntrega"] ?? '',
        estadoTraseraEntregaAux: datosEntrega["estadoTraseraEntrega"] ?? '',
        estadoCapoteEntregaAux: datosEntrega["estadoCapoteEntrega"] ?? '',
        estadoLateralRecepcionAux: '',
        estadoInteriorRecepcionAux: '',
        estadoDelanteraRecepcionAux: '',
        estadoTraseraRecepcionAux: '',
        estadoCapoteRecepcionAux: '',
      );

      // Registrar la entrega usando el método registerPrestamo del impl
      final result = await _repository.registerPrestamo(prestamoEntity);
      
      if (result) {
        return true;
      }
      
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registrarRecepcionPrestamo(Map<String, dynamic> datosRecepcion) async {
    try {
      // Crear la entity optimizada para recepción usando solo los campos necesarios
      final prestamoEntity = PrestamoChoferEntity(
        idPrestamo: datosRecepcion["idPrestamo"] ?? 0,
        idCoche: 0, // No necesario para recepción
        idSolicitud: 0, // No necesario para recepción
        codSucursal: 0, // No necesario para recepción
        fechaEntrega: DateTime.now(), // Placeholder - será ignorado por el backend
        codEmpChoferSolicitado: 0, // No necesario para recepción
        codEmpEntregadoPor: 0, // No necesario para recepción
        kilometrajeEntrega: 0.0, // No necesario para recepción
        kilometrajeRecepcion: datosRecepcion["kilometrajeRecepcion"]?.toDouble() ?? 0.0,
        nivelCombustibleEntrega: 0, // No necesario para recepción
        nivelCombustibleRecepcion: datosRecepcion["nivelCombustibleRecepcion"] ?? 0,
        estadoLateralesEntrega: 0, // No necesario para recepción
        estadoInteriorEntrega: 0,
        estadoDelanteraEntrega: 0,
        estadoTraseraEntrega: 0,
        estadoCapoteEntrega: 0,
        estadoLateralRecepcion: 0, // Será calculado por el backend
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
        // Campos de entrega vacíos para recepción
        estadoLateralesEntregaAux: '',
        estadoInteriorEntregaAux: '',
        estadoDelanteraEntregaAux: '',
        estadoTraseraEntregaAux: '',
        estadoCapoteEntregaAux: '',
        // Usar los campos Aux correctos para enviar los estados de recepción como string
        estadoLateralRecepcionAux: datosRecepcion["estadoLateralRecepcionAux"] ?? '',
        estadoInteriorRecepcionAux: datosRecepcion["estadoInteriorRecepcionAux"] ?? '',
        estadoDelanteraRecepcionAux: datosRecepcion["estadoDelanteraRecepcionAux"] ?? '',
        estadoTraseraRecepcionAux: datosRecepcion["estadoTraseraRecepcionAux"] ?? '',
        estadoCapoteRecepcionAux: datosRecepcion["estadoCapoteRecepcionAux"] ?? '',
      );

      // Usar el mismo método registerPrestamo para la recepción
      final result = await _repository.registerPrestamo(prestamoEntity);
      
      if (result) {
        return true;
      }
      
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

// Provider para las solicitudes de préstamos con estado de carga
final solicitudesPrestamosNotifierProvider = StateNotifierProvider<SolicitudesPrestamosNotifier, SolicitudesPrestamosState>((ref) {
  final repository = ref.watch(prestamoVehiculosProvider);
  final entregasRepository = ref.watch(entregasProvider);
  return SolicitudesPrestamosNotifier(repository, entregasRepository);
});
