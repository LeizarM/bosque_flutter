import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/hex_asignable_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_falta_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_model.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/repositories/hex_api_base.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_asignacion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Asignación de horas extra contra `/horas-extras/asignacion`. Los cuerpos
/// llevan los empleados, la jornada o el id; el asignador lo pone el backend.
class HexAsignacionImpl extends HexApiBase implements HexAsignacionRepository {
  @override
  Future<List<HexAsignableEntity>> asignables(DateTime? fechaJornada) => listar(
    AppConstants.hexAsignables,
    hexCuerpo({'fechaJornada': hexDiaJson(fechaJornada)}),
    (j) => HexAsignableModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> asignar({
    required List<BigInt> codEmpleados,
    required DateTime fechaJornada,
    required String motivo,
    bool confirmado = false,
  }) => escribir(
    AppConstants.hexAsignar,
    hexCuerpo({
      'codEmpleados': [for (final c in codEmpleados) c.toInt()],
      'fechaJornada': hexDiaJson(fechaJornada),
      'motivo': motivo,
      // Solo viaja como `true` en el reenvío; nunca como `false`.
      'confirmado': confirmado ? true : null,
    }),
  );

  @override
  Future<HexRespuesta> quitar({
    required BigInt idAsignacion,
    String? observacion,
  }) => escribir(
    AppConstants.hexQuitarAsignacion,
    hexCuerpo({'idAsignacion': idAsignacion, 'observacion': observacion}),
  );

  @override
  Future<PaginaHex<HexAsignacionEntity>> historial(
    FiltroAsignacionesHex f,
  ) async {
    final filas = await listar(
      AppConstants.hexHistorialAsignacion,
      hexCuerpo({
        'fechaDesde': hexDiaJson(f.desde),
        'fechaHasta': hexDiaJson(f.hasta),
        'estado': f.estado,
        'pagina': f.pagina,
        'tamano': f.tamano,
      }),
      (j) => HexAsignacionModel.fromJson(j).toEntity(),
    );
    return (filas: filas, total: filas.isEmpty ? 0 : filas.first.totalFilas);
  }

  @override
  Future<List<HexAsignacionFaltaEntity>> faltas({DateTime? desde}) => listar(
    AppConstants.hexFaltasAsignacion,
    hexCuerpo({'fechaDesde': hexDiaJson(desde)}),
    (j) => HexAsignacionFaltaModel.fromJson(j).toEntity(),
  );
}
