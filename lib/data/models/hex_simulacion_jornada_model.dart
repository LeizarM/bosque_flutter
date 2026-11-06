import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_jornada_entity.dart';

/// Columnas de `p_list_thex_Simulacion` J. Solo lectura.
class HexSimulacionJornadaModel {
  const HexSimulacionJornadaModel(this.entidad);

  final HexSimulacionJornadaEntity entidad;

  factory HexSimulacionJornadaModel.fromJson(Map<String, dynamic> j) =>
      HexSimulacionJornadaModel(
        HexSimulacionJornadaEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          cargo: hexTexto(j['cargo']),
          nombreSucursal: hexTexto(j['nombreSucursal']),
          fechaJornada: hexFecha(j['fechaJornada']),
          tipoDia: hexTexto(j['tipoDia']),
          textoTipoDia: hexTexto(j['textoTipoDia']),
          horarioIngreso: hexFecha(j['horarioIngreso']),
          horarioSalida: hexFecha(j['horarioSalida']),
          textoHorario: hexTexto(j['textoHorario']),
          textoMarcas: hexTexto(j['textoMarcas']),
          conAsignacion: hexBool(j['conAsignacion']),
          textoAsignacion: hexTexto(j['textoAsignacion']),
          idReporte: hexBigInt(j['idReporte']),
          textoReporte: hexTexto(j['textoReporte']),
          inicioUsado: hexFecha(j['inicioUsado']),
          finUsado: hexFecha(j['finUsado']),
          textoOrigen: hexTexto(j['textoOrigen']),
          haberBasico: hexDecimalN(j['haberBasico']),
          divisor: hexDecimalN(j['divisor']),
          costoHora: hexDecimalN(j['costoHora']),
          totalHoras: hexDecimal(j['totalHoras']),
          totalComidas: hexDecimal(j['totalComidas']),
          total: hexDecimal(j['total']),
          resumen: hexTexto(j['resumen']),
        ),
      );

  factory HexSimulacionJornadaModel.fromEntity(HexSimulacionJornadaEntity e) =>
      HexSimulacionJornadaModel(e);

  HexSimulacionJornadaEntity toEntity() => entidad;
}
