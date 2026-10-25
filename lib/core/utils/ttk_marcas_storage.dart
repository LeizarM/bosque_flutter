import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/utils/console_log.dart';

/// Las marcas que el participante pone a mano en su cartón, guardadas solo en
/// su equipo (en web, `localStorage`): el servidor nunca las ve ni las revisa.
/// Nunca lanza: si falla, el cartón empieza sin marcas.
class TtkMarcasStorage {
  const TtkMarcasStorage();

  static const _prefijo = 'ttk_marcas_';

  static String clave(BigInt codCarton, int nroJuego) =>
      '$_prefijo${codCarton}_$nroJuego';

  /// Posiciones marcadas de un juego del cartón.
  Future<Set<int>> leer(BigInt codCarton, int nroJuego) async {
    try {
      final p = await SharedPreferences.getInstance();
      return {
        for (final t
            in p.getStringList(clave(codCarton, nroJuego)) ?? const <String>[])
          if (int.tryParse(t) != null) int.parse(t),
      };
    } catch (e) {
      console('⚠️ No se pudieron leer las marcas del cartón $codCarton: $e');
      return <int>{};
    }
  }

  Future<void> guardar(BigInt codCarton, int nroJuego, Set<int> marcas) async {
    try {
      final p = await SharedPreferences.getInstance();
      final k = clave(codCarton, nroJuego);
      if (marcas.isEmpty) {
        await p.remove(k);
      } else {
        await p.setStringList(k, [for (final m in marcas.toList()..sort()) '$m']);
      }
    } catch (e) {
      console('⚠️ No se pudieron guardar las marcas del cartón $codCarton: $e');
    }
  }
}
