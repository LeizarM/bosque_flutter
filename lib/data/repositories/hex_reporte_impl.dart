import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/hex_jornada_pasada_model.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/models/hex_leyenda_codigos_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_evento_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_linea_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_tramo_model.dart';
import 'package:bosque_flutter/data/models/hex_requisito_marca_model.dart';
import 'package:bosque_flutter/data/models/hex_roles_model.dart';
import 'package:bosque_flutter/data/models/hex_vista_marcacion_model.dart';
import 'package:bosque_flutter/data/repositories/hex_api_base.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

/// Reportes de horas extra contra `/horas-extras`. Los cuerpos llevan solo el
/// id y los datos que el contrato lista; la identidad la pone el backend.
class HexReporteImpl extends HexApiBase implements HexReporteRepository {
  @override
  Future<HexLeyendaCodigosEntity?> leyendaCodigos() => leerUno(
    AppConstants.hexLeyendaCodigos,
    const {},
    (j) => HexLeyendaCodigosModel.fromJson(j).toEntity(),
  );

  @override
  Future<PaginaHex<HexReporteEntity>> misReportes(FiltroReportesHex f) =>
      _pagina(AppConstants.hexMisReportes, f);

  @override
  Future<HexRespuesta> marcar({
    required String tipoMarca,
    required PosicionHex posicion,
  }) => escribir(
    AppConstants.hexMarcar,
    hexCuerpo({
      'tipoMarca': tipoMarca,
      'lat': posicion.lat,
      'lon': posicion.lon,
      'precision': posicion.precision,
    }),
  );

  @override
  Future<HexVistaMarcacionEntity?> hoy() => leerUno(
    AppConstants.hexReporteHoy,
    const {},
    (j) => HexVistaMarcacionModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> actualizar({
    required BigInt idReporte,
    String? motivo,
  }) => escribir(
    AppConstants.hexActualizarReporte,
    hexCuerpo({'idReporte': idReporte, 'motivo': motivo}),
  );

  @override
  Future<HexRespuesta> anular({
    required BigInt idReporte,
    String? observacion,
  }) => escribir(
    AppConstants.hexAnularReporte,
    _conObservacion(idReporte, observacion),
  );

  @override
  Future<HexReporteEntity?> detalle(BigInt idReporte) => leerUno(
    AppConstants.hexDetalleReporte,
    hexCuerpo({'idReporte': idReporte}),
    (j) => HexReporteModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexReporteLineaEntity>> lineas(BigInt idReporte) => listar(
    AppConstants.hexLineasReporte,
    hexCuerpo({'idReporte': idReporte}),
    (j) => HexReporteLineaModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexReporteTramoEntity>> tramos(BigInt idReporte) => listar(
    AppConstants.hexReporteTramos,
    hexCuerpo({'idReporte': idReporte}),
    (j) => HexReporteTramoModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexReporteEventoEntity>> historial(BigInt idReporte) => listar(
    AppConstants.hexHistorialReporte,
    hexCuerpo({'idReporte': idReporte}),
    (j) => HexReporteEventoModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexRequisitoMarcaEntity>> requisitosMarca() => listar(
    AppConstants.hexRequisitosMarca,
    const {},
    (j) => HexRequisitoMarcaModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRolesEntity?> misRoles() => leerUno(
    AppConstants.hexMisRoles,
    const {},
    (j) => HexRolesModel.fromJson(j).toEntity(),
  );

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaEncargado(FiltroReportesHex f) =>
      _pagina(AppConstants.hexBandejaEncargado, f);

  @override
  Future<HexRespuesta> corregirHora({
    required BigInt idReporte,
    DateTime? inicio,
    DateTime? fin,
    required String observacion,
  }) => escribir(
    AppConstants.hexCorregirHora,
    hexCuerpo({
      'idReporte': idReporte,
      'inicio': hexFechaHoraJson(inicio),
      'fin': hexFechaHoraJson(fin),
      'observacion': observacion,
    }),
  );

  @override
  Future<HexRespuesta> vistoBueno({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  }) => escribir(
    AppConstants.hexVistoBueno,
    _firma(idReporte, observacion, confirmado),
  );

  @override
  Future<HexRespuesta> rechazarEncargado({
    required BigInt idReporte,
    required String observacion,
  }) => escribir(
    AppConstants.hexRechazarEncargado,
    _conObservacion(idReporte, observacion),
  );

  @override
  Future<List<HexJornadaPasadaEntity>> jornadasPasadas() => listar(
    AppConstants.hexJornadasPasadas,
    const {},
    (j) => HexJornadaPasadaModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> crearReportePasado(HexReportePasadoEntity reporte) =>
      escribir(
        AppConstants.hexCrearReportePasado,
        HexReportePasadoModel.fromEntity(reporte).toJson(),
      );

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaJefe(FiltroReportesHex f) =>
      _pagina(AppConstants.hexBandejaJefe, f);

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaObservador(FiltroReportesHex f) =>
      _pagina(AppConstants.hexObservacionBandeja, f);

  @override
  Future<HexRespuesta> aprobar({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  }) => escribir(
    AppConstants.hexAprobar,
    _firma(idReporte, observacion, confirmado),
  );

  @override
  Future<HexRespuesta> aprobarGrupo({
    required BigInt codEncargado,
    required int anio,
    required int mes,
    String? observacion,
  }) => escribir(
    AppConstants.hexAprobarGrupo,
    hexCuerpo({
      'codEncargado': codEncargado,
      'anio': anio,
      'mes': mes,
      'observacion': observacion,
    }),
  );

  @override
  Future<HexRespuesta> rechazarJefe({
    required BigInt idReporte,
    required String observacion,
  }) => escribir(
    AppConstants.hexRechazarJefe,
    _conObservacion(idReporte, observacion),
  );

  /// Una página de bandeja; el total es el `totalFilas` que repite cada fila.
  Future<PaginaHex<HexReporteEntity>> _pagina(
    String endpoint,
    FiltroReportesHex f,
  ) async {
    final filas = await listar(
      endpoint,
      hexCuerpo({
        'fechaDesde': hexDiaJson(f.desde),
        'fechaHasta': hexDiaJson(f.hasta),
        'estado': f.estado,
        'pagina': f.pagina,
        'tamano': f.tamano,
      }),
      (j) => HexReporteModel.fromJson(j).toEntity(),
    );
    return (filas: filas, total: filas.isEmpty ? 0 : filas.first.totalFilas);
  }

  Map<String, dynamic> _conObservacion(BigInt idReporte, String? observacion) =>
      hexCuerpo({'idReporte': idReporte, 'observacion': observacion});

  /// Visto bueno y aprobar: `confirmado` solo viaja como `true` en el reenvío.
  Map<String, dynamic> _firma(
    BigInt idReporte,
    String? observacion,
    bool confirmado,
  ) => hexCuerpo({
    'idReporte': idReporte,
    'observacion': observacion,
    'confirmado': confirmado ? true : null,
  });
}
