import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Filtro del historial de asignaciones. Lo nulo no viaja: el SP pone sus
/// valores por defecto (30 días antes y después de hoy). [pagina] parte en 1.
typedef FiltroAsignacionesHex =
    ({
      DateTime? desde,
      DateTime? hasta,
      String? estado,
      int pagina,
      int tamano,
    });

/// Asignación de horas extra del encargado o del jefe con aprobación directa
/// (D37). Quién asigna lo pone el backend por el token; aquí solo viajan los
/// empleados, la jornada y el id que se toca.
abstract class HexAsignacionRepository {
  /// A quién puede asignar el actor en [fechaJornada] (hoy si es nula), con
  /// el aviso de cada uno; vacía si el SP respondió 204.
  Future<List<HexAsignableEntity>> asignables(DateTime? fechaJornada);

  /// Todo o nada. Con avisos el SP responde [ConfirmacionHex]; [confirmado]
  /// solo vale `true` en el reenvío del mismo cuerpo. D41: [motivo] siempre
  /// viaja (vacío también): si falta o es largo, el texto es del SP.
  Future<HexRespuesta> asignar({
    required List<BigInt> codEmpleados,
    required DateTime fechaJornada,
    required String motivo,
    bool confirmado = false,
  });

  Future<HexRespuesta> quitar({
    required BigInt idAsignacion,
    String? observacion,
  });

  /// Lo que asignó el actor; el total es el `totalFilas` de cada fila.
  Future<PaginaHex<HexAsignacionEntity>> historial(FiltroAsignacionesHex f);

  /// Adenda D37: las faltas de lo que asignó el actor desde [desde] (si es
  /// nula, el SP toma los últimos 7 días); vacía si respondió 204.
  Future<List<HexAsignacionFaltaEntity>> faltas({DateTime? desde});
}
