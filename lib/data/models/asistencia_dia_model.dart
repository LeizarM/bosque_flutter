import 'package:bosque_flutter/domain/entities/asistencia_dia_entity.dart';

/// Origen: `POST /biometrico/reporte-mensual` -> `AsistenciaDiaDto` del backend.
class AsistenciaDiaModel {
  final DateTime fecha;
  final String estado;
  final String? motivo;
  final DateTime? horaEntradaEsperada;
  final DateTime? horaSalidaEsperada;
  final DateTime? horaEntradaReal;
  final DateTime? horaSalidaReal;

  const AsistenciaDiaModel({
    required this.fecha,
    required this.estado,
    this.motivo,
    this.horaEntradaEsperada,
    this.horaSalidaEsperada,
    this.horaEntradaReal,
    this.horaSalidaReal,
  });

  factory AsistenciaDiaModel.fromJson(Map<String, dynamic> json) =>
      AsistenciaDiaModel(
        fecha: DateTime.parse(json['fecha']),
        estado: json['estado'] ?? '',
        motivo: json['motivo'],
        horaEntradaEsperada:
            json['horaEntradaEsperada'] != null
                ? DateTime.tryParse(json['horaEntradaEsperada'])
                : null,
        horaSalidaEsperada:
            json['horaSalidaEsperada'] != null
                ? DateTime.tryParse(json['horaSalidaEsperada'])
                : null,
        horaEntradaReal:
            json['horaEntradaReal'] != null
                ? DateTime.tryParse(json['horaEntradaReal'])
                : null,
        horaSalidaReal:
            json['horaSalidaReal'] != null
                ? DateTime.tryParse(json['horaSalidaReal'])
                : null,
      );

  AsistenciaDiaEntity toEntity() => AsistenciaDiaEntity(
    fecha: fecha,
    estado: estado,
    motivo: motivo,
    horaEntradaEsperada: horaEntradaEsperada,
    horaSalidaEsperada: horaSalidaEsperada,
    horaEntradaReal: horaEntradaReal,
    horaSalidaReal: horaSalidaReal,
  );
}
