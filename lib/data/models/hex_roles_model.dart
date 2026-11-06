import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';

/// Columnas de `p_list_thex_Aprobador` M. Solo lectura.
class HexRolesModel {
  const HexRolesModel(this.entidad);

  final HexRolesEntity entidad;

  factory HexRolesModel.fromJson(Map<String, dynamic> j) => HexRolesModel(
    HexRolesEntity(
      esEncargado: hexBool(j['esEncargado']),
      esJefe: hexBool(j['esJefe']),
      esObservador: hexBool(j['esObservador']),
      sucursales: hexTextoN(j['sucursales']),
    ),
  );

  factory HexRolesModel.fromEntity(HexRolesEntity e) => HexRolesModel(e);

  HexRolesEntity toEntity() => entidad;
}
