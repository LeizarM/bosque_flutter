
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';

class EmpleadoEntity {
  final int codPersona;
  final int codZona;
  final String nombres;
  final String apPaterno;
  final String apMaterno;
  final String ciExpedido;
  final DateTime ciFechaVencimiento;
  final String ciNumero;
  final String direccion;
  final String estadoCivil;
  final DateTime fechaNacimiento;
  final String lugarNacimiento;
  final int nacionalidad;
  final String sexo;
  final double lat;
  final double lng;
  final int audUsuarioI;
  final String datoPersona;
  final int codEmpleado;
  final dynamic numCuenta;
  final int codRelBeneficios;
  final int codRelPlanilla;
  final int codDependiente;
  final dynamic esActivoString;
  final PersonaEntity persona;
  final EmpleadoCargo  empleadoCargo;
  final DependienteEntity dependiente;
  final Empresa empresa;
  final Sucursal sucursal;
  final RelacionLaboralEntity relEmpEmpr;

  EmpleadoEntity({
    required this.codPersona,
    required this.codZona,
    required this.nombres,
    required this.apPaterno,
    required this.apMaterno,
    required this.ciExpedido,
    required this.ciFechaVencimiento,
    required this.ciNumero,
    required this.direccion,
    required this.estadoCivil,
    required this.fechaNacimiento,
    required this.lugarNacimiento,
    required this.nacionalidad,
    required this.sexo,
    required this.lat,
    required this.lng,
    required this.audUsuarioI,
    required this.datoPersona,
    required this.codEmpleado,
    required this.numCuenta,
    required this.codRelBeneficios,
    required this.codRelPlanilla,
    required this.codDependiente,
    required this.esActivoString,
    required this.persona,
    required this.empleadoCargo,
    required this.dependiente,
    required this.empresa,
    required this.sucursal,
    required this.relEmpEmpr
    
  });

}