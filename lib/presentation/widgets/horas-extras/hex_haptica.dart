/// Vibración del módulo Horas Extras en los momentos clave: elegir, activar,
/// marcar, avisar un fallo. Usa `HapticFeedback` (sin paquetes); un fallo del
/// sistema nunca interrumpe la acción.
library;

import 'dart:async';

import 'package:flutter/services.dart';

abstract final class HapticaHex {
  static void _vibrar(Future<void> Function() tipo) {
    try {
      unawaited(tipo().catchError((Object _) {}));
    } catch (_) {
      // Sin vibración disponible: la acción sigue igual.
    }
  }

  /// Cambiar de pestaña, de segmento o de opción.
  static void seleccion() => _vibrar(HapticFeedback.selectionClick);

  /// Un toque que activa algo: interruptor, casilla, marcar, abrir.
  static void toque() => _vibrar(HapticFeedback.lightImpact);

  /// Algo salió bien (una escritura terminó).
  static void exito() => _vibrar(HapticFeedback.lightImpact);

  /// Algo falta o no se pudo (sin ubicación, un fallo del servidor).
  static void aviso() => _vibrar(HapticFeedback.mediumImpact);
}
