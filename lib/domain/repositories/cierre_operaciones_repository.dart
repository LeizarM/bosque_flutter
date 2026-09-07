// Destino final: lib/domain/repositories/cierre_operaciones_repository.dart
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

abstract class CierreOperacionesRepository {
  /// Traspasos de movimiento de caja sincronizados para [fecha] (null =
  /// hoy) — no los crea el usuario, ya existen; acá solo se muestran antes
  /// de confirmarlos. El legacy deja elegir cualquier fecha con un
  /// `<p:calendar>`, no solo hoy.
  Future<List<TraspasoMovCajaEntity>> obtenerTraspasos({DateTime? fecha});

  /// Confirma [fecha] (null = hoy) con el flag "¿Fue Verificado?" de CADA
  /// fila incluida en [traspasos] — igual que `guardarTraspasos()` del
  /// legacy, un UPDATE por fila, no un reclamo en bloque sin ese dato.
  /// Devuelve la cantidad de traspasos que quedaron asociados a esta
  /// ocurrencia (0 es válido: un día sin traspasos igual cierra la tarea).
  Future<int> confirmar(
    int idBitTarea, {
    DateTime? fecha,
    required List<Map<String, dynamic>> traspasos,
  });
}
