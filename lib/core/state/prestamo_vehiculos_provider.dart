import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/prestamo_vehiculos_impl.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';

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

// This is a placeholder. In a real app, you would get this from your authentication state
final userProvider = Provider<UserData>((ref) {
  return const UserData(
    codUsuario: 1,
    cargo: 'RESPONSABLE DE SISTEMAS'
  );
});

class UserData {
  final int codUsuario;
  final String cargo;
  
  const UserData({required this.codUsuario, required this.cargo});
}
