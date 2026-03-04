import 'package:bosque_flutter/data/models/cargo_sucursal_model.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';

class EmpleadoCargoModel {
    final int codEmpleado;
    final int codCargoSucursal;
    final int codCargoSucPlanilla;
    final DateTime fechaInicio;
    final int audUsuario;
    final CargoSucursalModel cargoSucursal;
    final dynamic cargoPlanilla;
    final int existe;
    final DateTime? fechaInicioOriginal;

    EmpleadoCargoModel({
        required this.codEmpleado,
        required this.codCargoSucursal,
        required this.codCargoSucPlanilla,
        required this.fechaInicio,
        required this.audUsuario,
        required this.cargoSucursal,
        required this.cargoPlanilla,
        required this.existe,
        this.fechaInicioOriginal,
    });

    factory EmpleadoCargoModel.fromJson(Map<String, dynamic> json) => EmpleadoCargoModel(
        codEmpleado: json["codEmpleado"]?? 0,
        codCargoSucursal: json["codCargoSucursal"]?? 0,
        codCargoSucPlanilla: json["codCargoSucPlanilla"]?? 0,
        fechaInicio: json["fechaInicio"]!= null ? DateTime.parse(json["fechaInicio"]) : DateTime.now(),
        audUsuario: json["audUsuario"]?? 0,
        cargoSucursal: CargoSucursalModel.fromJson(json["cargoSucursal"]),
        cargoPlanilla: json["cargoPlanilla"]?? '',
        existe: json["existe"]??0,
        fechaInicioOriginal: json["fechaInicioOriginal"] != null ? DateTime.parse(json["fechaInicioOriginal"]) : null,
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
        "fechaInicioOriginal": fechaInicioOriginal,
    };
    EmpleadoCargoEntity toEntity() => EmpleadoCargoEntity(
        codEmpleado: codEmpleado,
        codCargoSucursal: codCargoSucursal,
        codCargoSucPlanilla: codCargoSucPlanilla,
        fechaInicio: fechaInicio,
        audUsuario: audUsuario,
        cargoSucursal: cargoSucursal.toEntity(),
        cargoPlanilla: cargoPlanilla ?? '',
        existe: existe,
        fechaInicioOriginal: fechaInicioOriginal,
    );
    factory EmpleadoCargoModel.fromEntity(EmpleadoCargoEntity entity) => EmpleadoCargoModel(
        codEmpleado:  entity.codEmpleado,
        codCargoSucursal: entity.codCargoSucursal,
        codCargoSucPlanilla: entity.codCargoSucPlanilla,
        fechaInicio: entity.fechaInicio ?? DateTime.now(),
        audUsuario: entity.audUsuario,
        cargoSucursal: CargoSucursalModel.fromEntity(entity.cargoSucursal!),
        cargoPlanilla: entity.cargoPlanilla,
        existe: entity.existe ?? 0,
        fechaInicioOriginal: entity.fechaInicioOriginal,
    );
}