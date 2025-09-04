import 'package:bosque_flutter/domain/entities/persona_entity.dart';

class GaranteReferenciaEntity {
  final int codGarante;
  final int codPersona;
  final int codEmpleado;
  final String direccionTrabajo;
  final String empresaTrabajo;
  final String tipo;
  final String observacion;
  final int audUsuario;
  final String? esEmpleado;
  final String? nombreCompleto;
  final String? direccionDomicilio;
  final String? telefonos;
final PersonaEntity? persona;
  GaranteReferenciaEntity({
    required this.codGarante,
    required this.codPersona,
    required this.codEmpleado,
    required this.direccionTrabajo,
    required this.empresaTrabajo,
    required this.tipo,
    required this.observacion,
    required this.audUsuario,
     this.esEmpleado,
     this.nombreCompleto,
     this.direccionDomicilio,
     this.telefonos,
     this.persona,
  });
  Map<String, dynamic> toJson() {
    return {
      'codGarante': codGarante,
      'codPersona': codPersona,
      'codEmpleado': codEmpleado,
      'direccionTrabajo': direccionTrabajo,
      'empresaTrabajo': empresaTrabajo,
      'tipo': tipo,
      'observacion': observacion,
      'audUsuario': audUsuario,
      'esEmpleado': esEmpleado,
      'nombreCompleto': nombreCompleto,
      'direccionDomicilio': direccionDomicilio,
      'telefonos': telefonos,
    };
  }
  // Método copyWith
  GaranteReferenciaEntity copyWith({
    int? codGarante,
    int? codPersona,
    int? codEmpleado,
    String? direccionTrabajo,
    String? empresaTrabajo,
    String? tipo,
    String? observacion,
    int? audUsuario,
    String? esEmpleado,
    String? nombreCompleto,
    String? direccionDomicilio,
    String? telefonos,
    PersonaEntity? persona,
  }) {
    return GaranteReferenciaEntity(
      codGarante: codGarante ?? this.codGarante,
      codPersona: codPersona ?? this.codPersona,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      direccionTrabajo: direccionTrabajo ?? this.direccionTrabajo,
      empresaTrabajo: empresaTrabajo ?? this.empresaTrabajo,
      tipo: tipo ?? this.tipo,
      observacion: observacion ?? this.observacion,
      audUsuario: audUsuario ?? this.audUsuario,
      esEmpleado: esEmpleado ?? this.esEmpleado,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      direccionDomicilio: direccionDomicilio ?? this.direccionDomicilio,
      telefonos: telefonos ?? this.telefonos,
      persona: persona ?? this.persona,
    );
  }
}