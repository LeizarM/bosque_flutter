// Repositorio falso de «Actualizar datos SAP»: cuenta las llamadas, puede
// fallar con el texto que la prueba elija y puede quedarse esperando para
// comprobar el estado «Actualizando…» sin red.
import 'dart:async';

import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/actualizar_socios_sap_repository.dart';

class RepositorioActualizarSociosSapFalso
    implements ActualizarSociosSapRepository {
  /// Cuantas veces se pidio la actualizacion.
  int llamadas = 0;

  /// Lo que responde cuando sale bien: la frase del servidor, sin numero.
  ActualizarSociosSapEntity resultado = const ActualizarSociosSapEntity(
    mensaje:
        'Clientes actualizados desde SAP. Los cheques de los clientes que '
        'antes no estaban cargados ya aparecen en la lista.',
  );

  /// Si no es null, la llamada lo lanza. Como los repositorios reales, un 400 o
  /// un 403 llegan como el texto del servidor (un `String`).
  Object? error;

  /// Si no es null, la llamada espera a que se complete: el dialogo se queda en
  /// «Actualizando…» hasta entonces.
  Completer<void>? esperar;

  @override
  Future<ActualizarSociosSapEntity> actualizar() async {
    llamadas++;
    final c = esperar;
    if (c != null) await c.future;
    final e = error;
    if (e != null) throw e;
    return resultado;
  }
}
