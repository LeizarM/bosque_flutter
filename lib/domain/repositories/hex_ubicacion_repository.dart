/// Posición que la app manda al marcar: coordenadas y precisión en metros.
/// La hora y el empleado los pone el backend, nunca el dispositivo.
typedef PosicionHex = ({double lat, double lon, double precision});

/// Si se puede leer la ubicación para marcar y, si no, qué falta.
enum EstadoUbicacionHex { lista, servicioApagado, sinPermiso, denegadoSiempre }

/// No se pudo leer la posición. [estado] dice qué se perdió entre tanto
/// (servicio o permiso); nulo si el GPS no respondió a tiempo.
class UbicacionNoDisponibleHex implements Exception {
  const UbicacionNoDisponibleHex([this.estado]);

  final EstadoUbicacionHex? estado;

  @override
  String toString() =>
      'UbicacionNoDisponibleHex(${estado?.name ?? 'sin señal'})';
}

/// Ubicación del teléfono para marcar en la app. Sin ella la pantalla no deja
/// marcar; detrás de esta interfaz para poder probarla sin GPS.
abstract class UbicacionHex {
  /// Servicio y permiso; con [pedirPermiso] pregunta al usuario si aún puede.
  Future<EstadoUbicacionHex> verificar({bool pedirPermiso = false});

  /// Lanza [UbicacionNoDisponibleHex] si no hay posición a tiempo.
  Future<PosicionHex> posicionActual();

  /// `true`/`false` cada vez que el usuario enciende o apaga la ubicación.
  Stream<bool> servicioActivo();

  Future<void> abrirAjustesUbicacion();

  Future<void> abrirAjustesApp();
}
