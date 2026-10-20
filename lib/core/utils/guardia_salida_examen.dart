import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

/// Mientras un examen está `EN_CURSO` no se sale de la rendición: el `onExit`
/// de su ruta, el `PopScope` y, en web, `beforeunload` muestran el aviso. Solo
/// se sale entregando o cuando vence el tiempo (la rendición la libera).
class GuardiaSalidaExamen {
  GuardiaSalidaExamen._();

  static String? _aviso;
  static StreamSubscription<html.Event>? _antesDeCerrar;

  static bool get activa => _aviso != null;

  /// [aviso] es el `avisoSalidaExamen` de la configuración.
  static void activar(String aviso) {
    _aviso = aviso;
    if (kIsWeb) {
      _antesDeCerrar ??= html.window.onBeforeUnload.listen((e) {
        final texto = _aviso;
        if (texto == null) return;
        e.preventDefault();
        if (e is html.BeforeUnloadEvent) e.returnValue = texto;
      });
    }
  }

  static void liberar() {
    _aviso = null;
    _antesDeCerrar?.cancel();
    _antesDeCerrar = null;
  }

  /// `GoRoute.onExit` de las rutas de rendición: con el examen en curso avisa
  /// y no deja salir. En web devuelve la URL a la del examen.
  static Future<bool> alSalir(BuildContext context, GoRouterState state) async {
    final aviso = _aviso;
    if (aviso == null) return true;
    if (kIsWeb) SystemNavigator.routeInformationUpdated(uri: state.uri, replace: true);
    await mostrarAviso(context, aviso);
    return false;
  }

  static Future<void> mostrarAviso(BuildContext context, String aviso) => showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          icon: Icon(Icons.lock_clock_outlined, color: Theme.of(ctx).colorScheme.primary),
          title: const Text('Examen en curso'),
          content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(aviso)),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Seguir en el examen'))],
        ),
  );
}
