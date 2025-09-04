// To parse this JSON data, do
//
//     final empleadoModel = empleadoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/data/models/Persona_model.dart';
import 'package:bosque_flutter/data/models/ciudad_model.dart';
import 'package:bosque_flutter/data/models/dependiente_model.dart';
import 'package:bosque_flutter/data/models/email_model.dart';
import 'package:bosque_flutter/data/models/experiencia_laboral_model.dart';
import 'package:bosque_flutter/data/models/formacion_model.dart';
import 'package:bosque_flutter/data/models/garante_referencia_model.dart';
import 'package:bosque_flutter/data/models/pais_model.dart';
import 'package:bosque_flutter/data/models/relacion_laboral_model.dart';
import 'package:bosque_flutter/data/models/telefono_model.dart';
import 'package:bosque_flutter/data/models/zona_model.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';


List<EmpleadoModel> empleadoModelFromJson(String str) => List<EmpleadoModel>.from(json.decode(str).map((x) => EmpleadoModel.fromJson(x)));

String empleadoModelToJson(List<EmpleadoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EmpleadoModel {
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
    final ZonaModel zona;
    final PaisModel pais;
    final CiudadModel ciudad;
    final int codEmpleado;
    final dynamic numCuenta;
    final int codRelBeneficios;
    final int codRelPlanilla;
    final int codDependiente;
    final PersonaModel persona;
    final EmpleadoCargo empleadoCargo;
    final RelacionLaboralModel relEmpEmpr;
    final DependienteModel dependiente;
    final dynamic esActivoString;
    final TelefonoModel telefono;
    final Empresa empresa;
    final Sucursal sucursal;
    final EmailModel email;
    final FormacionModel formacion;
    final ExperienciaLaboralModel experienciaLaboral;
    final GaranteReferenciaModel garanteReferencia;

    EmpleadoModel({
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
        required this.zona,
        required this.pais,
        required this.ciudad,
        required this.codEmpleado,
        required this.numCuenta,
        required this.codRelBeneficios,
        required this.codRelPlanilla,
        required this.codDependiente,
        required this.persona,
        required this.empleadoCargo,
        required this.relEmpEmpr,
        required this.dependiente,
        required this.esActivoString,
        required this.telefono,
        required this.empresa,
        required this.sucursal,
        required this.email,
        required this.formacion,
        required this.experienciaLaboral,
        required this.garanteReferencia,
    });

    factory EmpleadoModel.fromJson(Map<String, dynamic> json) => EmpleadoModel(
        codPersona: json["codPersona"] ?? 0,
        codZona: json["codZona"] ?? 0,
        nombres: json["nombres"]?? '',
        apPaterno: json["apPaterno"]??'',
        apMaterno: json["apMaterno"]??'',
        ciExpedido: json["ciExpedido"]??'',
        ciFechaVencimiento: json["ciFechaVencimiento"] != null ? DateTime.parse(json["ciFechaVencimiento"]) : DateTime.now(),
        ciNumero: json["ciNumero"]??'',
        direccion: json["direccion"]??'',
        estadoCivil: json["estadoCivil"]??'',
        fechaNacimiento: json["fechaNacimiento"] != null ? DateTime.parse(json["fechaNacimiento"]) : DateTime.now(),
        lugarNacimiento: json["lugarNacimiento"]??'',
        nacionalidad: json["nacionalidad"]?? 0,
        sexo: json["sexo"]??'',
        lat: json["lat"]?? 0.0,
        lng: json["lng"]?? 0.0,
        audUsuarioI: json["audUsuarioI"]?? 0,
        datoPersona: json["datoPersona"]??'',
        zona: ZonaModel.fromJson(json["zona"]),
        pais: PaisModel.fromJson(json["pais"]),
        ciudad: CiudadModel.fromJson(json["ciudad"]),
        codEmpleado: json["codEmpleado"]?? 0,
        numCuenta: json["numCuenta"]?? 0,
        codRelBeneficios: json["codRelBeneficios"]?? 0,
        codRelPlanilla: json["codRelPlanilla"]?? 0,
        codDependiente: json["codDependiente"]?? 0,
        persona: PersonaModel.fromJson(json["persona"]),
        empleadoCargo: EmpleadoCargo.fromJson(json["empleadoCargo"]),
        relEmpEmpr: RelacionLaboralModel.fromJson(json["relEmpEmpr"]),
        dependiente: DependienteModel.fromJson(json["dependiente"]),
        esActivoString: json["esActivoString"]?? '',
        telefono: TelefonoModel.fromJson(json["telefono"]),
        empresa: Empresa.fromJson(json["empresa"]),
        sucursal: Sucursal.fromJson(json["sucursal"]),
        email: EmailModel.fromJson(json["email"]),
        formacion: FormacionModel.fromJson(json["formacion"]),
        experienciaLaboral: ExperienciaLaboralModel.fromJson(json["experienciaLaboral"]),
        garanteReferencia: GaranteReferenciaModel.fromJson(json["garanteReferencia"]),
    );

    Map<String, dynamic> toJson() => {
        "codPersona": codPersona,
        "codZona": codZona,
        "nombres": nombres,
        "apPaterno": apPaterno,
        "apMaterno": apMaterno,
        "ciExpedido": ciExpedido,
        "ciFechaVencimiento": ciFechaVencimiento,
        "ciNumero": ciNumero,
        "direccion": direccion,
        "estadoCivil": estadoCivil,
        "fechaNacimiento": fechaNacimiento,
        "lugarNacimiento": lugarNacimiento,
        "nacionalidad": nacionalidad,
        "sexo": sexo,
        "lat": lat,
        "lng": lng,
        "audUsuarioI": audUsuarioI,
        "datoPersona": datoPersona,
        "zona": zona.toJson(),
        "pais": pais.toJson(),
        "ciudad": ciudad.toJson(),
        "codEmpleado": codEmpleado,
        "numCuenta": numCuenta,
        "codRelBeneficios": codRelBeneficios,
        "codRelPlanilla": codRelPlanilla,
        "codDependiente": codDependiente,
        "persona": persona.toJson(),
        "empleadoCargo": empleadoCargo.toJson(),
        "relEmpEmpr": relEmpEmpr.toJson(),
        "dependiente": dependiente.toJson(),
        "esActivoString": esActivoString,
        "telefono": telefono.toJson(),
        "empresa": empresa.toJson(),
        "sucursal": sucursal.toJson(),
        "email": email.toJson(),
        "formacion": formacion.toJson(),
        "experienciaLaboral": experienciaLaboral.toJson(),
        "garanteReferencia": garanteReferencia.toJson(),
    };
  EmpleadoEntity toEntity()=> EmpleadoEntity(
    codPersona: codPersona,
    codZona: codZona,
    nombres: nombres,
    apPaterno: apPaterno,
    apMaterno: apMaterno,
    ciExpedido: ciExpedido,
    ciFechaVencimiento: ciFechaVencimiento,
    ciNumero: ciNumero,
    direccion: direccion,
    estadoCivil: estadoCivil,
    fechaNacimiento: fechaNacimiento,
    lugarNacimiento: lugarNacimiento,
    nacionalidad: nacionalidad,
    sexo: sexo,
    lat: lat,
    lng: lng,
    audUsuarioI: audUsuarioI,
    datoPersona: datoPersona,
    codEmpleado: codEmpleado,
    numCuenta: numCuenta,
    codRelBeneficios: codRelBeneficios,
    codRelPlanilla: codRelPlanilla,
    codDependiente: codDependiente,
    esActivoString: esActivoString,
    persona: persona.toEntity(),
    empleadoCargo: empleadoCargo,
    dependiente: dependiente.toEntity(),
    empresa: empresa,
    sucursal: sucursal,
    relEmpEmpr: relEmpEmpr.toEntity(),
  );
  factory EmpleadoModel.fromEntity(EmpleadoEntity entity) => EmpleadoModel(
    codPersona: entity.codPersona,
    codZona: entity.codZona,
    nombres: entity.nombres,
    apPaterno: entity.apPaterno,
    apMaterno: entity.apMaterno,
    ciExpedido: entity.ciExpedido,
    ciFechaVencimiento: entity.ciFechaVencimiento,
    ciNumero: entity.ciNumero,
    direccion: entity.direccion,
    estadoCivil: entity.estadoCivil,
    fechaNacimiento: entity.fechaNacimiento,
    lugarNacimiento: entity.lugarNacimiento,
    nacionalidad: entity.nacionalidad,
    sexo: entity.sexo,
    lat: entity.lat,
    lng: entity.lng,
    audUsuarioI: entity.audUsuarioI,
    datoPersona: entity.datoPersona,
    codEmpleado: entity.codEmpleado,
    numCuenta: entity.numCuenta,
    codRelBeneficios: entity.codRelBeneficios,
    codRelPlanilla: entity.codRelPlanilla,
    codDependiente: entity.codDependiente,
    esActivoString: entity.esActivoString,
    persona: PersonaModel(codPersona: 0,codZona: 0,zona: ZonaModel(codZona: 0, codCiudad: 0, zona: '', audUsuario: 0), nombres: '', apPaterno: '', apMaterno: '', ciExpedido: '', ciFechaVencimiento: DateTime.now(), ciNumero: '', direccion: '', estadoCivil: '', fechaNacimiento: DateTime.now(), lugarNacimiento: '', nacionalidad: 0, sexo: '', lat: 0.0, lng: 0.0, audUsuarioI: 0, datoPersona: '',pais: PaisModel(codPais: 0, pais: '', audUsuario: 0),ciudad: CiudadModel(codCiudad: 0, ciudad: '', codPais: 0, audUsuario: 0)),
    empleadoCargo: EmpleadoCargo(codEmpleado: 0, codCargoSucursal: 0, codCargoSucPlanilla: 0, fechaInicio: DateTime.now(), audUsuario: 0, cargoSucursal: CargoSucursal(codCargoSucursal: 0, codSucursal: 0, codCargo: 0, audUsuario: 0, datoCargo: '', sucursal: Sucursal(codSucursal: 0, nombre: '', codEmpresa: 0, codCiudad: 0, audUsuarioI: 0, empresa: Empresa(codEmpresa: 0, nombre: '', codPadre: 0, sigla: '', audUsuario: 0), nombreCiudad: ''), cargo: Cargo(codCargo: 0, codCargoPadre: 0, descripcion: '', codEmpresa: 0, codNivel: 0, posicion: 0, audUsuario: 0, sucursal: '', sucursalPlanilla: '', nombreEmpresa: '', nombreEmpresaPlanilla: '', codEmpresaPlanilla: 0, codCargoPlanilla: 0, descripcionPlanilla: '')), cargoPlanilla: '', existe: 0),
    relEmpEmpr: RelacionLaboralModel(codRelEmplEmpr: 0, codEmpleado: 0, esActivo: 0,tipoRel: '',nombreFileContrato: '', fechaIni: DateTime.now(), fechaFin: DateTime.now(), audUsuario: 0, motivoFin: '', cargo: '', fechaInicioBeneficio: DateTime.now(), fechaInicioPlanilla: DateTime.now(), datoFechasBeneficio: '', sucursal: '', empresaFiscal: '', empresaInterna: ''),
    dependiente: DependienteModel(codDependiente: 0, codPersona: 0,codEmpleado: 0, parentesco: '', esActivo: '', audUsuario: 0, nombreCompleto: '', descripcion: '', edad: 0),
    telefono: TelefonoModel(codTelefono: 0, codPersona: 0, codTipoTel: 0, telefono: '', tipo: '', audUsuario: 0),
    empresa: Empresa(codEmpresa: 0, nombre: '', codPadre: 0, sigla: '', audUsuario: 0),
    sucursal: Sucursal(codSucursal: 0, nombre: '', codEmpresa: 0, codCiudad: 0, audUsuarioI: 0, empresa: Empresa(codEmpresa: 0, nombre: '', codPadre: 0, sigla: '', audUsuario: 0), nombreCiudad: ''),
    email: EmailModel(codEmail: 0, codPersona: 0, email: '', audUsuario: 0),
    formacion: FormacionModel(codFormacion: 0, codEmpleado: 0, descripcion: '', duracion: 0, fechaFormacion: DateTime.now(), audUsuario: 0, tipoDuracion: '', tipoFormacion: ''),
    experienciaLaboral: ExperienciaLaboralModel(codExperienciaLaboral: 0, codEmpleado: 0, nombreEmpresa: '',cargo:'',descripcion: '', fechaInicio: DateTime.now(), fechaFin: DateTime.now(),nroReferencia: '', audUsuario: 0),
    garanteReferencia: GaranteReferenciaModel(codGarante: 0,codPersona: 0, codEmpleado: 0,direccionTrabajo: '',empresaTrabajo: '',tipo: '',observacion: '',audUsuario: 0, nombreCompleto:'',direccionDomicilio: '',telefonos: '',esEmpleado: ''),
    zona: ZonaModel(codZona: 0, codCiudad: 0, zona: '', audUsuario: 0),
    pais: PaisModel(codPais: 0, pais: '', audUsuario: 0),
    ciudad: CiudadModel(codCiudad: 0, ciudad: '', codPais: 0, audUsuario: 0),
  );

}

class EmpleadoCargo {
    final int codEmpleado;
    final int codCargoSucursal;
    final int codCargoSucPlanilla;
    final DateTime fechaInicio;
    final int audUsuario;
    final CargoSucursal cargoSucursal;
    final dynamic cargoPlanilla;
    final int existe;

    EmpleadoCargo({
        required this.codEmpleado,
        required this.codCargoSucursal,
        required this.codCargoSucPlanilla,
        required this.fechaInicio,
        required this.audUsuario,
        required this.cargoSucursal,
        required this.cargoPlanilla,
        required this.existe,
    });

    factory EmpleadoCargo.fromJson(Map<String, dynamic> json) => EmpleadoCargo(
        codEmpleado: json["codEmpleado"]?? 0,
        codCargoSucursal: json["codCargoSucursal"]?? 0,
        codCargoSucPlanilla: json["codCargoSucPlanilla"]?? 0,
        fechaInicio: json["fechaInicio"]!= null ? DateTime.parse(json["fechaInicio"]) : DateTime.now(),
        audUsuario: json["audUsuario"]?? 0,
        cargoSucursal: CargoSucursal.fromJson(json["cargoSucursal"]),
        cargoPlanilla: json["cargoPlanilla"]?? '',
        existe: json["existe"]??0,
    );

    Map<String, dynamic> toJson() => {
        "codEmpleado": codEmpleado,
        "codCargoSucursal": codCargoSucursal,
        "codCargoSucPlanilla": codCargoSucPlanilla,
        "fechaInicio": fechaInicio,
        "audUsuario": audUsuario,
        "cargoSucursal": cargoSucursal.toJson(),
        "cargoPlanilla": cargoPlanilla,
        "existe": existe,
    };
}

class CargoSucursal {
    final int codCargoSucursal;
    final int codSucursal;
    final int codCargo;
    final int audUsuario;
    final dynamic datoCargo;
    final Sucursal sucursal;
    final Cargo cargo;

    CargoSucursal({
        required this.codCargoSucursal,
        required this.codSucursal,
        required this.codCargo,
        required this.audUsuario,
        required this.datoCargo,
        required this.sucursal,
        required this.cargo,
    });

    factory CargoSucursal.fromJson(Map<String, dynamic> json) => CargoSucursal(
        codCargoSucursal: json["codCargoSucursal"]?? 0,
        codSucursal: json["codSucursal"]?? 0,
        codCargo: json["codCargo"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        datoCargo: json["datoCargo"] ?? '',
        sucursal: Sucursal.fromJson(json["sucursal"]),
        cargo: Cargo.fromJson(json["cargo"]) ,
    );

    Map<String, dynamic> toJson() => {
        "codCargoSucursal": codCargoSucursal,
        "codSucursal": codSucursal,
        "codCargo": codCargo,
        "audUsuario": audUsuario,
        "datoCargo": datoCargo,
        "sucursal": sucursal.toJson(),
        "cargo": cargo.toJson(),
    };
}

class Cargo {
    final int codCargo;
    final int codCargoPadre;
    final dynamic descripcion;
    final int codEmpresa;
    final int codNivel;
    final int posicion;
    final int audUsuario;
    final dynamic sucursal;
    final dynamic sucursalPlanilla;
    final dynamic nombreEmpresa;
    final dynamic nombreEmpresaPlanilla;
    final int codEmpresaPlanilla;
    final int codCargoPlanilla;
    final dynamic descripcionPlanilla;

    Cargo({
        required this.codCargo,
        required this.codCargoPadre,
        required this.descripcion,
        required this.codEmpresa,
        required this.codNivel,
        required this.posicion,
        required this.audUsuario,
        required this.sucursal,
        required this.sucursalPlanilla,
        required this.nombreEmpresa,
        required this.nombreEmpresaPlanilla,
        required this.codEmpresaPlanilla,
        required this.codCargoPlanilla,
        required this.descripcionPlanilla,
    });

    factory Cargo.fromJson(Map<String, dynamic> json) => Cargo(
        codCargo: json["codCargo"] ?? 0,
        codCargoPadre: json["codCargoPadre"] ?? 0,
        descripcion: json["descripcion"] ?? '',
        codEmpresa: json["codEmpresa"] ?? 0,
        codNivel: json["codNivel"] ?? 0,
        posicion: json["posicion"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        sucursal: json["sucursal"] ?? '',
        sucursalPlanilla: json["sucursalPlanilla"] ?? '',
        nombreEmpresa: json["nombreEmpresa"] ?? '',
        nombreEmpresaPlanilla: json["nombreEmpresaPlanilla"] ?? '',
        codEmpresaPlanilla: json["codEmpresaPlanilla"] ?? 0,
        codCargoPlanilla: json["codCargoPlanilla"] ?? 0,
        descripcionPlanilla: json["descripcionPlanilla"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "codCargo": codCargo,
        "codCargoPadre": codCargoPadre,
        "descripcion": descripcion,
        "codEmpresa": codEmpresa,
        "codNivel": codNivel,
        "posicion": posicion,
        "audUsuario": audUsuario,
        "sucursal": sucursal,
        "sucursalPlanilla": sucursalPlanilla,
        "nombreEmpresa": nombreEmpresa,
        "nombreEmpresaPlanilla": nombreEmpresaPlanilla,
        "codEmpresaPlanilla": codEmpresaPlanilla,
        "codCargoPlanilla": codCargoPlanilla,
        "descripcionPlanilla": descripcionPlanilla,
    };
}

class Sucursal {
    final int codSucursal;
    final dynamic nombre;
    final int codEmpresa;
    final int codCiudad;
    final int audUsuarioI;
    final Empresa empresa;
    final dynamic nombreCiudad;

    Sucursal({
        required this.codSucursal,
        required this.nombre,
        required this.codEmpresa,
        required this.codCiudad,
        required this.audUsuarioI,
        required this.empresa,
        required this.nombreCiudad,
    });

    factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        codSucursal: json["codSucursal"]?? 0,
        nombre: json["nombre"]??'',
        codEmpresa: json["codEmpresa"]?? 0,
        codCiudad: json["codCiudad"]?? 0,
        audUsuarioI: json["audUsuarioI"]?? 0,
        empresa: Empresa.fromJson(json["empresa"]),
        nombreCiudad: json["nombreCiudad"]?? '',
    );

    Map<String, dynamic> toJson() => {
        "codSucursal": codSucursal,
        "nombre": nombre,
        "codEmpresa": codEmpresa,
        "codCiudad": codCiudad,
        "audUsuarioI": audUsuarioI,
        "empresa": empresa.toJson(),
        "nombreCiudad": nombreCiudad,
    };
}

class Empresa {
    final int codEmpresa;
    final dynamic nombre;
    final int codPadre;
    final dynamic sigla;
    final int audUsuario;

    Empresa({
        required this.codEmpresa,
        required this.nombre,
        required this.codPadre,
        required this.sigla,
        required this.audUsuario,
    });

    factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        codEmpresa: json["codEmpresa"]?? 0,
        nombre: json["nombre"]??'',
        codPadre: json["codPadre"]?? 0,
        sigla: json["sigla"]??'',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codEmpresa": codEmpresa,
        "nombre": nombre,
        "codPadre": codPadre,
        "sigla": sigla,
        "audUsuario": audUsuario,
    };
}
















