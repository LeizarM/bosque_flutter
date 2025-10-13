import 'dart:convert';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';

CargoModel cargoModelFromJson(String str) =>
    CargoModel.fromJson(json.decode(str));

String cargoModelToJson(CargoModel data) => json.encode(data.toJson());

class CargoModel {
  int codCargo;
  int codCargoPadre;
  String descripcion;
  int codEmpresa;
  int codNivel;
  int posicion;
  int estado;
  int audUsuario;
  String sucursal;
  String sucursalPlanilla;
  String nombreEmpresa;
  String nombreEmpresaPlanilla;
  int codEmpresaPlanilla;
  int codCargoPlanilla;
  String descripcionPlanilla;

  //variables de apoyo
  int nivel;
  int tieneEmpleadosActivos;
  int tieneEmpleadosTotales;
  int estaAsignadoSucursal;
  int canDeactivate;
  int numDependientes;
  int numDependenciasTotales;
  int numDependenciasCompletas;
  int numDeDependencias;
  int numHijosActivos;
  int numHijosTotal;
  String resumenCompleto;
  String estadoPadre;

  List<CargoModel>? items;

  CargoModel({
    required this.codCargo,
    required this.codCargoPadre,
    required this.descripcion,
    required this.codEmpresa,
    required this.codNivel,
    required this.posicion,
    required this.estado,
    required this.audUsuario,
    required this.sucursal,
    required this.sucursalPlanilla,
    required this.nombreEmpresa,
    required this.nombreEmpresaPlanilla,
    required this.codEmpresaPlanilla,
    required this.codCargoPlanilla,
    required this.descripcionPlanilla,

    //variables de apoyo
    required this.nivel,
    required this.tieneEmpleadosActivos,
    required this.tieneEmpleadosTotales,
    required this.estaAsignadoSucursal,
    required this.canDeactivate,
    required this.numDependientes,
    required this.numDependenciasTotales,
    required this.numDependenciasCompletas,
    required this.numDeDependencias,
    required this.numHijosActivos,
    required this.numHijosTotal,
    required this.resumenCompleto,
    required this.estadoPadre,
    required this.items,
  });

  factory CargoModel.fromJson(Map<String, dynamic> json) => CargoModel(
    codCargo: json["codCargo"] ?? 0,
    codCargoPadre: json["codCargoPadre"] ?? 0,
    descripcion: json["descripcion"] ?? '',
    codEmpresa: json["codEmpresa"] ?? 0,
    codNivel: json["codNivel"] ?? 0,
    posicion: json["posicion"] ?? 0,
    estado: json["estado"] ?? 0,
    audUsuario: json["audUsuario"] ?? 0,
    sucursal: json["sucursal"] ?? '',
    sucursalPlanilla: json["sucursalPlanilla"] ?? '',
    nombreEmpresa: json["nombreEmpresa"] ?? '',
    nombreEmpresaPlanilla: json["nombreEmpresaPlanilla"] ?? '',
    codEmpresaPlanilla: json["codEmpresaPlanilla"] ?? 0,
    codCargoPlanilla: json["codCargoPlanilla"] ?? 0,
    descripcionPlanilla: json["descripcionPlanilla"] ?? '',
    //variables de apoyo
    nivel: json["nivel"] ?? 0,
    tieneEmpleadosActivos: json["tieneEmpleadosActivos"] ?? 0,
    tieneEmpleadosTotales: json["tieneEmpleadosTotales"] ?? 0,
    estaAsignadoSucursal: json["estaAsignadoSucursal"] ?? 0,
    canDeactivate: json["canDeactivate"] ?? 0,
    numDependientes: json["numDependientes"] ?? 0,
    numDependenciasTotales: json["numDependenciasTotales"] ?? 0,
    numDependenciasCompletas: json["numDependenciasCompletas"] ?? 0,
    numDeDependencias: json["numDeDependencias"] ?? 0,
    numHijosActivos: json["numHijosActivos"] ?? 0,
    numHijosTotal: json["numHijosTotal"] ?? 0,
    resumenCompleto: json["resumenCompleto"] ?? '',
    estadoPadre: json["estadoPadre"] ?? '',

    items:
        json['items'] != null
            ? (json['items'] as List<dynamic>)
                .map((item) => CargoModel.fromJson(item))
                .toList()
            : null,
  );

  Map<String, dynamic> toJson() => {
    "codCargo": codCargo,
    "codCargoPadre": codCargoPadre,
    "descripcion": descripcion,
    "codEmpresa": codEmpresa,
    "codNivel": codNivel,
    "posicion": posicion,
    "estado": estado,
    "audUsuario": audUsuario,
    "sucursal": sucursal,
    "sucursalPlanilla": sucursalPlanilla,
    "nombreEmpresa": nombreEmpresa,
    "nombreEmpresaPlanilla": nombreEmpresaPlanilla,
    "codEmpresaPlanilla": codEmpresaPlanilla,
    "codCargoPlanilla": codCargoPlanilla,
    "descripcionPlanilla": descripcionPlanilla,
    //variables de apoyo
    "nivel": nivel,
    "tieneEmpleadosActivos": tieneEmpleadosActivos,
    "tieneEmpleadosTotales": tieneEmpleadosTotales,
    "estaAsignadoSucursal": estaAsignadoSucursal,
    "canDeactivate": canDeactivate,
    "numDependientes": numDependientes,
    "numDependenciasTotales": numDependenciasTotales,
    "numDependenciasCompletas": numDependenciasCompletas,
    "numDeDependencias": numDeDependencias,
    "numHijosActivos": numHijosActivos,
    "numHijosTotal": numHijosTotal,
    "resumenCompleto": resumenCompleto,
    "estadoPadre": estadoPadre,
    "items":
        items != null ? items!.map((item) => item.toJson()).toList() : null,
  };

  // Método para convertir de Model a Entity
  CargoEntity toEntity() => CargoEntity(
    codCargo: codCargo,
    codCargoPadre: codCargoPadre,
    descripcion: descripcion,
    codEmpresa: codEmpresa,
    codNivel: codNivel,
    posicion: posicion,
    estado: estado,
    audUsuario: audUsuario,
    sucursal: sucursal,
    sucursalPlanilla: sucursalPlanilla,
    nombreEmpresa: nombreEmpresa,
    nombreEmpresaPlanilla: nombreEmpresaPlanilla,
    codEmpresaPlanilla: codEmpresaPlanilla,
    codCargoPlanilla: codCargoPlanilla,
    descripcionPlanilla: descripcionPlanilla,
    nivel: nivel,
    tieneEmpleadosActivos: tieneEmpleadosActivos,
    tieneEmpleadosTotales: tieneEmpleadosTotales,
    estaAsignadoSucursal: estaAsignadoSucursal,
    canDeactivate: canDeactivate,
    numDependientes: numDependientes,
    numDependenciasTotales: numDependenciasTotales,
    numDependenciasCompletas: numDependenciasCompletas,
    numDeDependencias: numDeDependencias,
    numHijosActivos: numHijosActivos,
    numHijosTotal: numHijosTotal,
    resumenCompleto: resumenCompleto,
    estadoPadre: estadoPadre,
    items: items!.map((model) => model.toEntity()).toList(),
  );

  // Método factory para convertir de Entity a Model
  factory CargoModel.fromEntity(CargoEntity entity) => CargoModel(
    codCargo: entity.codCargo,
    codCargoPadre: entity.codCargoPadre,
    descripcion: entity.descripcion,
    codEmpresa: entity.codEmpresa,
    codNivel: entity.codNivel,
    posicion: entity.posicion,
    estado: entity.estado,
    audUsuario: entity.audUsuario,
    sucursal: entity.sucursal,
    sucursalPlanilla: entity.sucursalPlanilla,
    nombreEmpresa: entity.nombreEmpresa,
    nombreEmpresaPlanilla: entity.nombreEmpresaPlanilla,
    codEmpresaPlanilla: entity.codEmpresaPlanilla,
    codCargoPlanilla: entity.codCargoPlanilla,
    descripcionPlanilla: entity.descripcionPlanilla,
    //variables de apoyo
    nivel: entity.nivel,
    tieneEmpleadosActivos: entity.tieneEmpleadosActivos,
    tieneEmpleadosTotales: entity.tieneEmpleadosTotales,
    estaAsignadoSucursal: entity.estaAsignadoSucursal,
    canDeactivate: entity.canDeactivate,
    numDependientes: entity.numDependientes,
    numDependenciasTotales: entity.numDependenciasTotales,
    numDependenciasCompletas: entity.numDependenciasCompletas,
    numDeDependencias: entity.numDeDependencias,
    numHijosActivos: entity.numHijosActivos,
    numHijosTotal: entity.numHijosTotal,
    resumenCompleto: entity.resumenCompleto,
    estadoPadre: entity.estadoPadre,
    items: entity.items.map((e) => CargoModel.fromEntity(e)).toList(),
  );
}
