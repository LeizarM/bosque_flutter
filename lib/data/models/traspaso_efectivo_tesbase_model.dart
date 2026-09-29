// Destino final: lib/data/models/traspaso_efectivo_tesbase_model.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';

class TraspasoEfectivoTesBaseModel {
  final int codTes;
  final String? codCliente;
  final String? datoCliente;
  final String? nombreEmpresa;
  final DateTime? fechaRegistro;
  final String? observacion;
  final String? estado;
  final DateTime? fechaFinalizacion;

  const TraspasoEfectivoTesBaseModel({
    required this.codTes,
    this.codCliente,
    this.datoCliente,
    this.nombreEmpresa,
    this.fechaRegistro,
    this.observacion,
    this.estado,
    this.fechaFinalizacion,
  });

  factory TraspasoEfectivoTesBaseModel.fromJson(Map<String, dynamic> json) =>
      TraspasoEfectivoTesBaseModel(
        codTes: (json['codTes'] as num?)?.toInt() ?? 0,
        codCliente: json['codCliente'] as String?,
        datoCliente: json['datoCliente'] as String?,
        // El SP del sistema anterior la llama "nombre"; el backend la
        // renombra hacia afuera. Se acepta cualquiera de las dos.
        nombreEmpresa: (json['nombreEmpresa'] ?? json['nombre']) as String?,
        fechaRegistro: soloFecha(json['fechaRegistro']),
        observacion: json['observacion'] as String?,
        estado: json['estado'] as String?,
        fechaFinalizacion: soloFecha(json['fechaFinalizacion']),
      );

  TraspasoEfectivoTesBaseEntity toEntity() => TraspasoEfectivoTesBaseEntity(
    codTes: codTes,
    codCliente: codCliente,
    datoCliente: datoCliente,
    nombreEmpresa: nombreEmpresa,
    fechaRegistro: fechaRegistro,
    observacion: observacion,
    estado: estado,
    fechaFinalizacion: fechaFinalizacion,
  );
}

/// La respuesta de `/traspaso-efectivo-tesbase/dia-revisado` (archivo SQL 58).
class DiaRevisadoTesBaseModel {
  final DateTime? fechaTarea;
  final DateTime? fechaRevisada;
  final String? feriado;

  const DiaRevisadoTesBaseModel({
    this.fechaTarea,
    this.fechaRevisada,
    this.feriado,
  });

  factory DiaRevisadoTesBaseModel.fromJson(Map<String, dynamic> json) =>
      DiaRevisadoTesBaseModel(
        fechaTarea: soloFecha(json['fechaTarea']),
        fechaRevisada: soloFecha(json['fechaRevisada']),
        feriado: (json['feriado'] as String?)?.trim(),
      );

  /// Nulo si el servidor no mandó el día revisado: sin él no hay qué mostrar.
  DiaRevisadoTesBase? toEntity() {
    final revisada = fechaRevisada;
    if (revisada == null) return null;
    final motivo = feriado;
    return DiaRevisadoTesBase(
      fechaTarea:
          fechaTarea ??
          DateTime(revisada.year, revisada.month, revisada.day + 1),
      fechaRevisada: revisada,
      feriado: motivo == null || motivo.isEmpty ? null : motivo,
    );
  }
}
