import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';

/// Columnas de `p_list_thex_Reporte` P (D43): las jornadas pasadas que el
/// actor puede registrar. Solo lectura; `toJson` existe por la paridad.
class HexJornadaPasadaModel {
  const HexJornadaPasadaModel(this.entidad);

  final HexJornadaPasadaEntity entidad;

  factory HexJornadaPasadaModel.fromJson(Map<String, dynamic> j) =>
      HexJornadaPasadaModel(
        HexJornadaPasadaEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          cargo: hexTextoN(j['cargo']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          fechaJornada: hexFecha(j['fechaJornada']),
          tipoDia: hexTexto(j['tipoDia']),
          textoTipoDia: hexTexto(j['textoTipoDia']),
          textoHorario: hexTexto(j['textoHorario']),
          tipoSugerido: hexTexto(j['tipoSugerido']),
          inicioSugerido: hexFecha(j['inicioSugerido']),
          finSugerido: hexFecha(j['finSugerido']),
          motivo: hexTextoN(j['motivo']),
          textoAyuda: hexTexto(j['textoAyuda']),
          puedeCrear: hexBool(j['puedeCrear']),
          textoRegularizacion: hexTexto(j['textoRegularizacion']),
        ),
      );

  factory HexJornadaPasadaModel.fromEntity(HexJornadaPasadaEntity e) =>
      HexJornadaPasadaModel(e);

  HexJornadaPasadaEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'codEmpleado': entidad.codEmpleado,
    'nombreEmpleado': entidad.nombreEmpleado,
    'cargo': entidad.cargo,
    'nombreSucursal': entidad.nombreSucursal,
    'fechaJornada': hexDiaJson(entidad.fechaJornada),
    'tipoDia': entidad.tipoDia,
    'textoTipoDia': entidad.textoTipoDia,
    'textoHorario': entidad.textoHorario,
    'tipoSugerido': entidad.tipoSugerido,
    'inicioSugerido': hexFechaHoraJson(entidad.inicioSugerido),
    'finSugerido': hexFechaHoraJson(entidad.finSugerido),
    'motivo': entidad.motivo,
    'textoAyuda': entidad.textoAyuda,
    'puedeCrear': entidad.puedeCrear,
    'textoRegularizacion': entidad.textoRegularizacion,
  });
}

/// Cuerpo de `revision/crear-pasado` (D43): solo el empleado al que se le
/// crea, la jornada, las horas y la justificación; quien crea sale del token.
class HexReportePasadoModel {
  const HexReportePasadoModel(this.entidad);

  final HexReportePasadoEntity entidad;

  factory HexReportePasadoModel.fromEntity(HexReportePasadoEntity e) =>
      HexReportePasadoModel(e);

  HexReportePasadoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'codEmpleado': entidad.codEmpleado,
    'fechaJornada': hexDiaJson(entidad.fechaJornada),
    'inicio': hexFechaHoraJson(entidad.inicio),
    'fin': hexFechaHoraJson(entidad.fin),
    'observacion': entidad.observacion,
  });
}
