import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

/// [UbicacionHex] sobre `geolocator`: solo en primer plano y una lectura por
/// marca. En la web no hay servicio que observar ni ajustes que abrir: el
/// permiso lo da el navegador.
class GeolocatorUbicacionHex implements UbicacionHex {
  GeolocatorUbicacionHex();

  /// Lo más que espera la marca a que el GPS responda.
  static const Duration _limite = Duration(seconds: 20);

  /// Android solo dice «negado para siempre» al pedir; después
  /// `checkPermission` responde «negado». Se recuerda para seguir ofreciendo
  /// los ajustes hasta que el permiso se dé o se vuelva a preguntar.
  bool _negadoSiempre = false;

  @override
  Future<EstadoUbicacionHex> verificar({bool pedirPermiso = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return EstadoUbicacionHex.servicioApagado;
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      final respuesta = pedirPermiso ? await _pedirPermiso() : null;
      if (respuesta != null) {
        permiso = respuesta;
        _negadoSiempre = respuesta == LocationPermission.deniedForever;
      } else if (_negadoSiempre) {
        permiso = LocationPermission.deniedForever;
      }
    } else {
      _negadoSiempre = permiso == LocationPermission.deniedForever;
    }
    return switch (permiso) {
      LocationPermission.whileInUse ||
      LocationPermission.always => EstadoUbicacionHex.lista,
      LocationPermission.deniedForever => EstadoUbicacionHex.denegadoSiempre,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => EstadoUbicacionHex.sinPermiso,
    };
  }

  /// Nulo si el diálogo del sistema ya está abierto (otra verificación lo
  /// pidió): la respuesta llega a esa otra verificación.
  Future<LocationPermission?> _pedirPermiso() async {
    try {
      return await Geolocator.requestPermission();
    } on PermissionRequestInProgressException {
      return null;
    }
  }

  @override
  Future<PosicionHex> posicionActual() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _limite,
        ),
      );
      return (lat: p.latitude, lon: p.longitude, precision: p.accuracy);
    } on LocationServiceDisabledException {
      throw const UbicacionNoDisponibleHex(EstadoUbicacionHex.servicioApagado);
    } on PermissionDeniedException {
      throw UbicacionNoDisponibleHex(
        _negadoSiempre
            ? EstadoUbicacionHex.denegadoSiempre
            : EstadoUbicacionHex.sinPermiso,
      );
    } on TimeoutException {
      throw const UbicacionNoDisponibleHex();
    } on PositionUpdateException {
      throw const UbicacionNoDisponibleHex();
    }
  }

  @override
  Stream<bool> servicioActivo() =>
      kIsWeb
          ? const Stream<bool>.empty()
          : Geolocator.getServiceStatusStream().map(
            (s) => s == ServiceStatus.enabled,
          );

  @override
  Future<void> abrirAjustesUbicacion() async {
    if (!kIsWeb) await Geolocator.openLocationSettings();
  }

  @override
  Future<void> abrirAjustesApp() async {
    if (!kIsWeb) await Geolocator.openAppSettings();
  }
}
