import 'package:bosque_flutter/domain/entities/bitacora_entity.dart';

/// Origen: `POST /biometrico/bitacora/listar`.
class BitacoraModel {
  final int idBitacora;
  final String tabla;
  final String idRegistro;
  final String accion;
  final String? motivo;
  final int audUsuario;
  final String nombreUsuario;
  final DateTime? audFecha;

  const BitacoraModel({
    required this.idBitacora,
    required this.tabla,
    required this.idRegistro,
    required this.accion,
    this.motivo,
    required this.audUsuario,
    required this.nombreUsuario,
    this.audFecha,
  });

  factory BitacoraModel.fromJson(Map<String, dynamic> json) => BitacoraModel(
    idBitacora: json['idBitacora'] ?? 0,
    tabla: json['tabla'] ?? '',
    idRegistro: json['idRegistro'] ?? '',
    accion: json['accion'] ?? '',
    motivo: json['motivo'],
    audUsuario: json['audUsuario'] ?? 0,
    nombreUsuario: json['nombreUsuario'] ?? '',
    audFecha:
        json['audFecha'] != null ? DateTime.tryParse(json['audFecha']) : null,
  );

  BitacoraEntity toEntity() => BitacoraEntity(
    idBitacora: idBitacora,
    tabla: tabla,
    idRegistro: idRegistro,
    accion: accion,
    motivo: motivo,
    audUsuario: audUsuario,
    nombreUsuario: nombreUsuario,
    audFecha: audFecha,
  );
}
