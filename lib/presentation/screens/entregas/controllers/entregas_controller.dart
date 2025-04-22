import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

class EntregasController {
  final WidgetRef ref;
  final BuildContext context;

  EntregasController(this.ref, this.context);

  Future<bool> checkLocationPermission() async {
    return await ref.read(entregasNotifierProvider.notifier).verificarServiciosLocalizacion();
  }

  Future<int> getCodEmpleado() async {
    return await ref.read(userProvider.notifier).getCodEmpleado();
  }

  Future<void> cargarEntregas(int codEmpleado) async {
    await ref.read(entregasNotifierProvider.notifier).cargarEntregas(codEmpleado);
  }

  Future<bool> solicitarPermisosUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        final irAConfiguracion = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos de ubicación necesarios'),
            content: const Text('Los permisos de ubicación son necesarios para marcar entregas. Por favor, habilítalos en la configuración de la aplicación.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ir a Configuración'),
              ),
            ],
          ),
        );
        if (irAConfiguracion == true) {
          await Geolocator.openAppSettings();
          permission = await Geolocator.checkPermission();
          return permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
        }
        return false;
      }
      return true;
    } catch (e) {
      print('Error al solicitar permisos de ubicación: ${e.toString()}');
      return false;
    }
  }

  Future<void> iniciarRuta() async {
    await ref.read(entregasNotifierProvider.notifier).iniciarRuta();
  }

  Future<void> finalizarRuta() async {
    await ref.read(entregasNotifierProvider.notifier).finalizarRuta();
  }

  Future<void> marcarEntregaCompletada(EntregaEntity entrega, String? observaciones) async {
    await ref.read(entregasNotifierProvider.notifier).marcarEntregaCompletada(
      entrega.idEntrega,
      "",
      observaciones: observaciones,
    );
  }

  void mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}