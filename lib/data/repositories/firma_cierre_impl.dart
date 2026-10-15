// Destino final: lib/data/repositories/firma_cierre_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/firma_cierre_model.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/domain/repositories/firma_cierre_repository.dart';

class FirmaCierreImpl extends BaseApiRepository
    implements FirmaCierreRepository {
  Map<String, dynamic> _rango(DateTime? desde, DateTime? hasta) => {
    if (desde != null) 'fechaIni': fechaParaSql(desde),
    if (hasta != null) 'fechaFin': fechaParaSql(hasta),
  };

  @override
  Future<List<CeldaCierre>> misSecciones(int idBitTarea) => postAndReturnList(
    endpoint: AppConstants.tarVerificarCierreMisSecciones,
    data: {'idBitTarea': idBitTarea},
    fromJson: FirmaCierreModel.celda,
  );

  @override
  Future<void> firmar(
    int idBitTarea,
    CeldaCierre celda, {
    String? obs,
    DateTime? fecha,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreFirmarSeccion,
      data: {
        'idBitTarea': idBitTarea,
        'seccion': celda.codigo,
        'codSucursal': celda.codSucursal,
        'obs': (obs == null || obs.trim().isEmpty) ? null : obs.trim(),
        if (fecha != null) 'fecha': fechaParaSql(fecha),
      },
      errorMessage: 'No se pudo firmar la sección.',
    );
  }

  @override
  Future<void> anular(int idFC, {required String motivo}) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreAnularFirma,
      data: {'idFC': idFC, 'obs': motivo.trim()},
      errorMessage: 'No se pudo anular la firma.',
    );
  }

  @override
  Future<List<FilaSeccion>> filasSeccion(
    int idBitTarea,
    CeldaCierre celda, {
    DateTime? fecha,
  }) => postAndReturnList(
    endpoint: AppConstants.tarVerificarCierreFilasSeccion,
    data: {
      'idBitTarea': idBitTarea,
      'seccion': celda.codigo,
      'codSucursal': celda.codSucursal,
      if (fecha != null) 'fecha': fechaParaSql(fecha),
    },
    fromJson:
        (j) => FirmaCierreModel.fila(j, codSucursalCelda: celda.codSucursal),
  );

  @override
  Future<void> marcarFila(
    int idBitTarea,
    CeldaCierre celda,
    FilaSeccion fila, {
    required bool revisada,
    DateTime? fecha,
  }) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreMarcarFila,
      data: {
        'idBitTarea': idBitTarea,
        'seccion': celda.codigo,
        'codSucursal': celda.codSucursal,
        'clave': fila.clave,
        'marca': revisada ? 1 : 0,
        if (fecha != null) 'fecha': fechaParaSql(fecha),
      },
      errorMessage: 'No se pudo marcar la fila.',
    );
    // Un SP sin la rama G devuelve 0: falta el script.
    if (id <= BigInt.zero) {
      throw Exception('Falta correr el script 86 en la base.');
    }
  }

  @override
  Future<List<CeldaTablero>> tablero({DateTime? desde, DateTime? hasta}) =>
      postAndReturnList(
        endpoint: AppConstants.tarVerificarCierreTablero,
        data: _rango(desde, hasta),
        fromJson: FirmaCierreModel.tablero,
      );

  @override
  Future<List<ResumenCierrePersona>> resumen({
    DateTime? desde,
    DateTime? hasta,
  }) => postAndReturnList(
    endpoint: AppConstants.tarVerificarCierreTableroResumen,
    data: _rango(desde, hasta),
    fromJson: FirmaCierreModel.resumen,
  );
}
