import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/domain/repositories/entregas_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:geocoding/geocoding.dart';

// Estado para el proveedor de entregas
class EntregasState {
  final bool isLoading;
  final List<EntregaEntity> entregas;
  final String? error;
  final bool rutaIniciada;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Position? posicionInicial;
  final Position? posicionFinal;
  final bool sincronizacionEnProceso;

  EntregasState({
    this.isLoading = false,
    this.entregas = const [],
    this.error,
    this.rutaIniciada = false,
    this.fechaInicio,
    this.fechaFin,
    this.posicionInicial,
    this.posicionFinal,
    this.sincronizacionEnProceso = false,
  });

  EntregasState copyWith({
    bool? isLoading,
    List<EntregaEntity>? entregas,
    String? error,
    bool? rutaIniciada,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    Position? posicionInicial,
    Position? posicionFinal,
    bool? sincronizacionEnProceso,
  }) {
    return EntregasState(
      isLoading: isLoading ?? this.isLoading,
      entregas: entregas ?? this.entregas,
      error: error,
      rutaIniciada: rutaIniciada ?? this.rutaIniciada,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      posicionInicial: posicionInicial ?? this.posicionInicial,
      posicionFinal: posicionFinal ?? this.posicionFinal,
      sincronizacionEnProceso: sincronizacionEnProceso ?? this.sincronizacionEnProceso,
    );
  }
}

// Notifier para manejar la lógica de estado de entregas
class EntregasNotifier extends StateNotifier<EntregasState> {
  final EntregasRepository _repository;
  final SharedPreferences _prefs;
  final UserStateNotifier _userNotifier;

  EntregasNotifier(this._repository, this._prefs, this._userNotifier) : super(EntregasState()) {
    _cargarEstadoGuardado();
  }

  // Cargar estado guardado de la ruta desde SharedPreferences
  Future<void> _cargarEstadoGuardado() async {
    final rutaIniciada = _prefs.getBool('ruta_iniciada') ?? false;
    final fechaInicioStr = _prefs.getString('fecha_inicio');
    final fechaInicio = fechaInicioStr != null ? DateTime.parse(fechaInicioStr) : null;
    
    if (rutaIniciada) {
      state = state.copyWith(
        rutaIniciada: rutaIniciada,
        fechaInicio: fechaInicio,
      );
    }
  }

  // Cargar entregas para un chofer específico
  Future<void> cargarEntregas(int codEmpleado) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final entregas = await _repository.getEntregas(codEmpleado);
      state = state.copyWith(
        isLoading: false,
        entregas: entregas,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Iniciar la ruta de entregas
  Future<void> iniciarRuta() async {
    try {
      // Verificar si hay entregas pendientes
      if (state.entregas.isEmpty) {
        state = state.copyWith(
          error: 'No hay entregas pendientes para iniciar la ruta',
        );
        return;
      }

      // Obtener posición actual
      final posicion = await _obtenerPosicionActual();
      
      // Guardar estado en SharedPreferences
      final ahora = DateTime.now();
      await _prefs.setBool('ruta_iniciada', true);
      await _prefs.setString('fecha_inicio', ahora.toIso8601String());
      
      // Actualizar estado
      state = state.copyWith(
        rutaIniciada: true,
        fechaInicio: ahora,
        posicionInicial: posicion,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  // Finalizar la ruta de entregas
  Future<void> finalizarRuta() async {
    try {
      // Obtener posición actual
      final posicion = await _obtenerPosicionActual();
      final ahora = DateTime.now();
      
      // Intentar sincronizar las entregas completadas
      state = state.copyWith(sincronizacionEnProceso: true);
      final sincronizacionExitosa = await _repository.sincronizarEntregasCompletadas(state.entregas);
      
      // Guardar estado en SharedPreferences
      await _prefs.setBool('ruta_iniciada', false);
      await _prefs.setString('fecha_fin', ahora.toIso8601String());
      
      // Actualizar estado
      state = state.copyWith(
        rutaIniciada: false,
        fechaFin: ahora,
        posicionFinal: posicion,
        sincronizacionEnProceso: false,
        error: sincronizacionExitosa ? null : 'Las entregas se guardaron localmente, pero hubo un error al sincronizar con el servidor',
      );
    } catch (e) {
      state = state.copyWith(
        sincronizacionEnProceso: false,
        error: e.toString(),
      );
    }
  }

  // Marcar una entrega como completada
  Future<void> marcarEntregaCompletada(int idEntrega, String direccion, {String? observaciones}) async {
    try {
      if (!state.rutaIniciada) {
        state = state.copyWith(
          error: 'Debe iniciar la ruta antes de marcar entregas',
        );
        return;
      }

      // Obtener posición actual
      final posicion = await _obtenerPosicionActual();
      
      // Obtener dirección automáticamente a partir de las coordenadas
      final direccionGeo = await _obtenerDireccionDesdeUbicacion(posicion);
      
      // Encontrar la entrega que se quiere marcar
      final entrega = state.entregas.firstWhere(
        (e) => e.idEntrega == idEntrega,
        orElse: () => throw Exception('No se encontró la entrega con ID $idEntrega'),
      );
      
      // Obtenemos el docNum para marcar todo el documento como entregado
      final docNum = entrega.docNum;
      final docEntry = entrega.docEntry;
      final db = entrega.db ?? "ERPB_PROD";  // Valor por defecto si es null
      
      // Obtener datos del usuario usando el userNotifier inyectado
      final codUsuario = await _userNotifier.getCodUsuario();
      final codSucursal = await _userNotifier.getCodSucursal();
      final codCiudad = await _userNotifier.getCodCiudad();
      
      // Validación adicional para asegurar que tenemos todos los datos necesarios
      if (codUsuario == 0 || codSucursal == 0 || codCiudad == 0) {
        throw Exception('No se pudieron obtener los datos del usuario necesarios para marcar la entrega');
      }
      
      final ahora = DateTime.now();
      
      // Marcar la entrega en el estado como en proceso de sincronización
      state = state.copyWith(sincronizacionEnProceso: true);
      
      // Log para depuración
      print('Marcando entrega con ID: $idEntrega');
      print('DocNum: $docNum, DocEntry: $docEntry');
      print('Posición: ${posicion.latitude}, ${posicion.longitude}');
      print('Dirección geocodificada: $direccionGeo');
      
      try {
        // Llamar al método que marca todo el documento de una vez
        final exito = await _repository.marcarDocumentoEntregado(
          docNum,
          docEntry: docEntry,
          db: db,
          latitud: posicion.latitude,
          longitud: posicion.longitude,
          direccionEntrega: direccionGeo, // Usamos la dirección obtenida por geocodificación
          fechaEntrega: ahora,
          audUsuario: codUsuario,
          codSucursalChofer: codSucursal,
          codCiudadChofer: codCiudad,
          observaciones: observaciones,
        );
        
        if (exito) {
          // Actualizar todas las entregas del documento en el estado local
          final nuevasEntregas = [...state.entregas];
          for (var i = 0; i < nuevasEntregas.length; i++) {
            if (nuevasEntregas[i].docNum == docNum) {
              nuevasEntregas[i] = nuevasEntregas[i].copyWith(
                fueEntregado: 1, // Marcar como entregado
                latitud: posicion.latitude,
                longitud: posicion.longitude,
                direccionEntrega: direccionGeo, // Actualizamos la dirección local con la geolocalizada
                fechaEntrega: ahora,
                obs: observaciones,
              );
            }
          }
          
          state = state.copyWith(
            entregas: nuevasEntregas,
            error: null,
            sincronizacionEnProceso: false,
          );
          print('Entrega marcada exitosamente');
        } else {
          print('Error: No se pudo marcar el documento como entregado');
          state = state.copyWith(
            error: 'No se pudo marcar el documento como entregado. Intente nuevamente.',
            sincronizacionEnProceso: false,
          );
        }
      } catch (repoError) {
        print('Error en la comunicación con el repositorio: ${repoError.toString()}');
        state = state.copyWith(
          error: 'Error de comunicación: ${repoError.toString()}',
          sincronizacionEnProceso: false,
        );
      }
    } catch (e) {
      print('Error en marcarEntregaCompletada: ${e.toString()}');
      state = state.copyWith(
        error: e.toString(),
        sincronizacionEnProceso: false,
      );
    }
  }

  // Verificar si los servicios de localización están disponibles
  Future<bool> verificarServiciosLocalizacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error al verificar servicios de localización: ${e.toString()}');
      return false;
    }
  }

  // Obtener la posición actual utilizando Geolocator
  Future<Position> _obtenerPosicionActual() async {
    // Verificar los servicios de localización primero
    bool disponible = await verificarServiciosLocalizacion();
    if (!disponible) {
      throw Exception('Los servicios de ubicación no están disponibles o los permisos fueron denegados.');
    }

    // Si los servicios están disponibles, obtener la posición actual
    return await Geolocator.getCurrentPosition();
  }

  // Obtener dirección a partir de coordenadas geográficas
  Future<String> _obtenerDireccionDesdeUbicacion(Position posicion) async {
    try {
      print('Obteniendo dirección para coordenadas: ${posicion.latitude}, ${posicion.longitude}');
      final placemarks = await placemarkFromCoordinates(
        posicion.latitude, 
        posicion.longitude,
         
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Protegerse contra valores nulos usando ?? para proporcionar valores por defecto
        final components = [
          place.street ?? '',
          place.subLocality ?? '',
          place.locality ?? '',
          place.administrativeArea ?? '',
          place.country ?? '',
          place.postalCode ?? '',
        ];
        
        // Filtrar componentes vacíos
        final filteredComponents = components.where((component) => component.isNotEmpty).toList();
        
        // Crear dirección combinada
        final direccion = filteredComponents.join(', ');
        
        print('DIRECCIÓN OBTENIDA: $direccion');
        
        // Si después de todo el procesamiento, la dirección sigue vacía, usar una predeterminada
        return direccion.isNotEmpty ? direccion : 'Ubicación actual (sin dirección disponible)';
      }
      
      print('No se pudieron obtener placemarks para las coordenadas');
      return 'Ubicación actual (sin dirección disponible)';
    } catch (e) {
      print('Error al obtener dirección: ${e.toString()}');
      // Siempre devolver una dirección predeterminada en lugar de propagar el error
      return 'Ubicación marcada en ${posicion.latitude.toStringAsFixed(6)}, ${posicion.longitude.toStringAsFixed(6)}';
    }
  }
}

// Proveedor para el repositorio de entregas
final entregasRepositoryProvider = Provider<EntregasRepository>((ref) {
  throw UnimplementedError('Debe ser sobrescrito en el main.dart');
});

// Proveedor para SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Debe ser sobrescrito en el main.dart');
});

// Proveedor para el notificador de entregas
final entregasNotifierProvider = StateNotifierProvider<EntregasNotifier, EntregasState>((ref) {
  final repository = ref.watch(entregasRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final userNotifier = ref.watch(userProvider.notifier);
  return EntregasNotifier(repository, prefs, userNotifier);
});