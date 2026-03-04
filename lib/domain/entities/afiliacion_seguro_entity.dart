import 'package:bosque_flutter/domain/entities/seguro_entity.dart';

class AfiliacionSeguroEntity {
  final int codAfiliacion;
  final int codEmpleado;
  final int codSeguro;
  final DateTime? fechaAfiliacion;
  final DateTime? fechaBaja;
  final String nroAfiliacion;
  final int audUsuarioI;
  final int codPersona;
  final String nombreCompleto;
  final SeguroEntity seguro;
  AfiliacionSeguroEntity({
    required this.codAfiliacion,
    required this.codEmpleado,
    required this.codSeguro,
    this.fechaAfiliacion,
    this.fechaBaja,
    required this.nroAfiliacion,
    required this.audUsuarioI,
    required this.codPersona,
    required this.nombreCompleto,
    required this.seguro,
  });
}