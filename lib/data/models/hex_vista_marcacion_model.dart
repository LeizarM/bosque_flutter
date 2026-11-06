import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';

/// Columnas de `reporte/hoy` (D37). Solo lectura: el actor sale del token.
class HexVistaMarcacionModel {
  const HexVistaMarcacionModel(this.entidad);

  final HexVistaMarcacionEntity entidad;

  factory HexVistaMarcacionModel.fromJson(Map<String, dynamic> j) =>
      HexVistaMarcacionModel(
        HexVistaMarcacionEntity(
          vistaHabilitada: hexBool(j['vistaHabilitada']),
          textoVista: hexTexto(j['textoVista']),
          fechaJornadaAsignada: hexFecha(j['fechaJornadaAsignada']),
          idAsignacion: hexBigInt(j['idAsignacion']),
          nombreAsignador: hexTextoN(j['nombreAsignador']),
          puedeMarcarEntrada: hexBool(j['puedeMarcarEntrada']),
          textoMarcarEntrada: hexTexto(j['textoMarcarEntrada']),
          tipoEntrada: hexTextoN(j['tipoEntrada']),
          puedeMarcarSalida: hexBool(j['puedeMarcarSalida']),
          textoMarcarSalida: hexTexto(j['textoMarcarSalida']),
          fechaJornadaSalida: hexFecha(j['fechaJornadaSalida']),
          tipoSalida: hexTextoN(j['tipoSalida']),
          horaLimiteSalida: hexFecha(j['horaLimiteSalida']),
          motivoAsignacion: hexTextoN(j['motivoAsignacion']),
        ),
      );

  factory HexVistaMarcacionModel.fromEntity(HexVistaMarcacionEntity e) =>
      HexVistaMarcacionModel(e);

  HexVistaMarcacionEntity toEntity() => entidad;
}
