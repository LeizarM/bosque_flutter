import 'package:bosque_flutter/core/constants/app_constants.dart';

/// ¿Esta app puede entrar? Sí si su versión es igual o mayor a la mínima que
/// devuelve el login (`versionApp` de `p_list_Usuario`).
///
/// Antes se comparaba por igualdad, y la app y la base tenían que cambiar en el
/// mismo instante. Así se publica primero la app y después se sube la mínima.
/// Una mínima vacía o ilegible no deja entrar, igual que antes.
bool versionAppVigente(
  String? minima, {
  String actual = AppConstants.APP_VERSION,
}) {
  final req = _partes(minima);
  final app = _partes(actual);
  if (req == null || app == null) return false;
  for (var i = 0; i < 3; i++) {
    if (app[i] != req[i]) return app[i] > req[i];
  }
  return true;
}

/// "1.0.2" → [1, 0, 2]; lo que falte cuenta como 0. Null si no es una versión.
List<int>? _partes(String? v) {
  final limpio = v?.trim() ?? '';
  if (limpio.isEmpty) return null;
  final trozos = limpio.split('.');
  if (trozos.length > 3) return null;
  final nums = <int>[];
  for (final t in trozos) {
    final n = int.tryParse(t);
    if (n == null || n < 0) return null;
    nums.add(n);
  }
  while (nums.length < 3) {
    nums.add(0);
  }
  return nums;
}
