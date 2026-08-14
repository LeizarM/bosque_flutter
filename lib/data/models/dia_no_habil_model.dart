import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/dia_no_habil_entity.dart';

/// `POST /permiso-rrhh/permisos/dias-no-habiles` → `DiaNoHabilDto`.
class DiaNoHabilModel {
  const DiaNoHabilModel({
    required this.fecha,
    required this.tipo,
    required this.motivo,
  });

  final DateTime? fecha;
  final String tipo;
  final String motivo;

  factory DiaNoHabilModel.fromJson(Map<String, dynamic> json) =>
      DiaNoHabilModel(
        fecha: prDate(json['fecha']),
        tipo: prStr(json['tipo']),
        motivo: prStr(json['motivo']),
      );

  DiaNoHabilEntity toEntity() => DiaNoHabilEntity(
    fecha: fecha ?? DateTime(1900),
    tipo: tipo,
    motivo: motivo,
  );
}
