// Destino final: lib/domain/repositories/firma_cierre_repository.dart
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';

/// Verificar Cierre por responsables (archivo SQL 81). Las reglas de la firma
/// las decide el servidor: si no pasa, lanza su mensaje tal cual.
abstract class FirmaCierreRepository {
  /// Las celdas que le tocan a quien abrió su tarea 39.
  Future<List<CeldaCierre>> misSecciones(int idBitTarea);

  /// Con [fecha], otro día desde la tarea de hoy (archivo SQL 109).
  Future<void> firmar(
    int idBitTarea,
    CeldaCierre celda, {
    String? obs,
    DateTime? fecha,
  });

  Future<void> anular(int idFC, {required String motivo});

  /// Las filas de una celda con fuente (archivo SQL 86). Con [fecha], las de
  /// un día anterior, solo para consultar (92). Si la fuente no se pudo leer,
  /// lanza el motivo del servidor.
  Future<List<FilaSeccion>> filasSeccion(
    int idBitTarea,
    CeldaCierre celda, {
    DateTime? fecha,
  });

  /// Marca o desmarca una fila; con la última, el servidor puede firmar solo.
  Future<void> marcarFila(
    int idBitTarea,
    CeldaCierre celda,
    FilaSeccion fila, {
    required bool revisada,
    DateTime? fecha,
  });

  /// Sin fechas, los últimos 7 días.
  Future<List<CeldaTablero>> tablero({DateTime? desde, DateTime? hasta});

  Future<List<ResumenCierrePersona>> resumen({
    DateTime? desde,
    DateTime? hasta,
  });
}
