import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';

class EmpleadoEntity {
  final int? fila;
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
  final EmpleadoCargoEntity empleadoCargo;
  final DependienteEntity? dependiente;
  final EmpresaEntity empresa;
  final SucursalEntity sucursal;
  final RelacionLaboralEntity relEmpEmpr;
  final double? haberBasico;

  EmpleadoEntity({
    this.fila,
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
    required this.relEmpEmpr,
    this.haberBasico,
  });
  //metodo tojson
  Map<String, dynamic> toJson() => {
    "codPersona": codPersona,
    "codZona": codZona,
    "nombres": nombres,
    "apPaterno": apPaterno,
    "apMaterno": apMaterno,
    "ciExpedido": ciExpedido,
    "ciFechaVencimiento": ciFechaVencimiento.toIso8601String(),
    "ciNumero": ciNumero,
    "direccion": direccion,
    "estadoCivil": estadoCivil,
    "fechaNacimiento": fechaNacimiento.toIso8601String(),
    "lugarNacimiento": lugarNacimiento,
    "nacionalidad": nacionalidad,
    "sexo": sexo,
    "lat": lat,
    "lng": lng,
    "audUsuarioI": audUsuarioI,
    "datoPersona": datoPersona,
    "codEmpleado": codEmpleado,
    "numCuenta": numCuenta,
    "codRelBeneficios": codRelBeneficios,
    "codRelPlanilla": codRelPlanilla,
    "codDependiente": codDependiente,
    "esActivoString": esActivoString,
    "haberBasico": haberBasico,
  };
  EmpleadoEntity copyWith({
    int? fila,
    int? codPersona,
    int? codZona,
    String? nombres,
    String? apPaterno,
    String? apMaterno,
    String? ciExpedido,
    DateTime? ciFechaVencimiento,
    String? ciNumero,
    String? direccion,
    String? estadoCivil,
    DateTime? fechaNacimiento,
    String? lugarNacimiento,
    int? nacionalidad,
    String? sexo,
    double? lat,
    double? lng,
    int? audUsuarioI,
    String? datoPersona,
    int? codEmpleado,
    dynamic numCuenta,
    int? codRelBeneficios,
    int? codRelPlanilla,
    int? codDependiente,
    dynamic esActivoString,
    PersonaEntity? persona,
    EmpleadoCargoEntity? empleadoCargo,
    DependienteEntity? dependiente,
    EmpresaEntity? empresa,
    SucursalEntity? sucursal,
    RelacionLaboralEntity? relEmpEmpr,
    double? haberBasico,
  }) {
    return EmpleadoEntity(
      fila: fila ?? this.fila,
      codPersona: codPersona ?? this.codPersona,
      codZona: codZona ?? this.codZona,
      nombres: nombres ?? this.nombres,
      apPaterno: apPaterno ?? this.apPaterno,
      apMaterno: apMaterno ?? this.apMaterno,
      ciExpedido: ciExpedido ?? this.ciExpedido,
      ciFechaVencimiento: ciFechaVencimiento ?? this.ciFechaVencimiento,
      ciNumero: ciNumero ?? this.ciNumero,
      direccion: direccion ?? this.direccion,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      lugarNacimiento: lugarNacimiento ?? this.lugarNacimiento,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      sexo: sexo ?? this.sexo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      datoPersona: datoPersona ?? this.datoPersona,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      numCuenta: numCuenta ?? this.numCuenta,
      codRelBeneficios: codRelBeneficios ?? this.codRelBeneficios,
      codRelPlanilla: codRelPlanilla ?? this.codRelPlanilla,
      codDependiente: codDependiente ?? this.codDependiente,
      esActivoString: esActivoString ?? this.esActivoString,
      persona: persona ?? this.persona,
      empleadoCargo: empleadoCargo ?? this.empleadoCargo,
      dependiente: dependiente ?? this.dependiente,
      empresa: empresa ?? this.empresa,
      sucursal: sucursal ?? this.sucursal,
      relEmpEmpr: relEmpEmpr ?? this.relEmpEmpr,
      haberBasico: haberBasico ?? this.haberBasico,
    );
  }
}
