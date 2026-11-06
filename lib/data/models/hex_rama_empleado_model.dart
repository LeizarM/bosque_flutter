import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';

/// Columnas de `p_list_thex_Aprobador` R: la rama de un aprobador. Solo
/// lectura; `toJson` existe por la paridad de modelos.
class HexRamaEmpleadoModel {
  const HexRamaEmpleadoModel(this.entidad);

  final HexRamaEmpleadoEntity entidad;

  factory HexRamaEmpleadoModel.fromJson(Map<String, dynamic> j) =>
      HexRamaEmpleadoModel(
        HexRamaEmpleadoEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          codCargo: hexBigInt(j['codCargo']),
          cargo: hexTextoN(j['cargo']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          profundidad: hexInt(j['profundidad']),
          vistoBueno: hexTextoN(j['vistoBueno']),
          aprueba: hexTextoN(j['aprueba']),
          textoFirma: hexTexto(j['textoFirma']),
          cargoAprobador: hexTextoN(j['cargoAprobador']),
          rutaCargo: hexTextoN(j['rutaCargo']),
        ),
      );

  factory HexRamaEmpleadoModel.fromEntity(HexRamaEmpleadoEntity e) =>
      HexRamaEmpleadoModel(e);

  HexRamaEmpleadoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'codEmpleado': entidad.codEmpleado,
    'nombreEmpleado': entidad.nombreEmpleado,
    'codCargo': entidad.codCargo,
    'cargo': entidad.cargo,
    'codSucursal': entidad.codSucursal,
    'nombreSucursal': entidad.nombreSucursal,
    'profundidad': entidad.profundidad,
    'vistoBueno': entidad.vistoBueno,
    'aprueba': entidad.aprueba,
    'textoFirma': entidad.textoFirma,
    'cargoAprobador': entidad.cargoAprobador,
    'rutaCargo': entidad.rutaCargo,
  });
}
