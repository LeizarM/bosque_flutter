import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/utils/console_log.dart';

/// La última pregunta vista de cada examen, en el almacenamiento local (en web,
/// `localStorage`): al recargar la página, la rendición vuelve a ella. Nunca
/// lanza: si falla, la rendición empieza en la primera pregunta.
class UltimaPreguntaStorage {
  const UltimaPreguntaStorage();

  static const _prefijo = 'tcpe_ultima_pregunta_';

  static String clave(BigInt codExamen) => '$_prefijo$codExamen';

  /// El `codPreguntaH` guardado, o null.
  Future<BigInt?> leer(BigInt codExamen) async {
    try {
      final p = await SharedPreferences.getInstance();
      return BigInt.tryParse(p.getString(clave(codExamen)) ?? '');
    } catch (e) {
      console('⚠️ No se pudo leer la última pregunta del examen $codExamen: $e');
      return null;
    }
  }

  Future<void> guardar(BigInt codExamen, BigInt codPreguntaH) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(clave(codExamen), '$codPreguntaH');
    } catch (e) {
      console('⚠️ No se pudo guardar la última pregunta del examen $codExamen: $e');
    }
  }

  /// Al entregar: el examen ya no se rinde.
  Future<void> olvidar(BigInt codExamen) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(clave(codExamen));
    } catch (_) {
      // Sin almacenamiento no hay nada que olvidar.
    }
  }
}
