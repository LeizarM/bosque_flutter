// Ubicación falsa del módulo Horas Extras: el estado que responde `verificar`
// se programa por llamada, la posición es fija y se cuenta cada pedido; el
// servicio se enciende o apaga a mano con `servicio`.
import 'dart:async';

import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

class UbicacionHexFalsa implements UbicacionHex {
  UbicacionHexFalsa([EstadoUbicacionHex estado = EstadoUbicacionHex.lista])
    : _estados = [estado];

  /// La posición que entrega siempre (centro de La Paz, 12 m de precisión).
  static const PosicionHex posicion = (
    lat: -16.5,
    lon: -68.15,
    precision: 12.0,
  );

  final List<EstadoUbicacionHex> _estados;

  /// `pedirPermiso` de cada llamada a `verificar`, en orden.
  final List<bool> verificaciones = [];
  int posiciones = 0;
  int ajustesUbicacion = 0;
  int ajustesApp = 0;

  /// Si no es nulo, `posicionActual` espera a que se complete (GPS lento).
  Completer<void>? pausaPosicion;

  /// Si no es nulo, `posicionActual` lo lanza en vez de responder (una
  /// `UbicacionNoDisponibleHex` o cualquier otra excepción de la plataforma).
  Exception? errorPosicion;

  /// Cambios del servicio de ubicación que escucha la pantalla.
  final StreamController<bool> servicio = StreamController<bool>.broadcast();

  /// Desde ahora `verificar` responde siempre [e].
  set estado(EstadoUbicacionHex e) => programar([e]);

  /// Respuestas de `verificar` en orden; la última se repite.
  void programar(List<EstadoUbicacionHex> estados) {
    assert(estados.isNotEmpty, 'Programa al menos un estado.');
    _estados
      ..clear()
      ..addAll(estados);
  }

  @override
  Future<EstadoUbicacionHex> verificar({bool pedirPermiso = false}) async {
    verificaciones.add(pedirPermiso);
    return _estados.length > 1 ? _estados.removeAt(0) : _estados.first;
  }

  @override
  Future<PosicionHex> posicionActual() async {
    posiciones++;
    final espera = pausaPosicion;
    if (espera != null) await espera.future;
    final error = errorPosicion;
    if (error != null) throw error;
    return posicion;
  }

  @override
  Stream<bool> servicioActivo() => servicio.stream;

  @override
  Future<void> abrirAjustesUbicacion() async => ajustesUbicacion++;

  @override
  Future<void> abrirAjustesApp() async => ajustesApp++;
}
