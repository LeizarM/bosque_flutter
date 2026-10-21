import 'package:bosque_flutter/domain/entities/empresa_entity.dart';

/// Una sucursal (`tb_sucursal`). [nombreEmpresa], [estado] y [cargos] solo
/// vienen en la pantalla de empresas y sucursales.
class SucursalEntity {
  final int codSucursal;
  final String nombre;
  final int codEmpresa;
  final int codCiudad;
  final int audUsuarioI;
  final EmpresaEntity empresa;
  final String nombreCiudad;
  final int codSucursalPlanilla;
  final String nombrePlanilla;
  final String nombreEmpresa;
  final int estado;
  final int cargos;

  SucursalEntity({
    required this.codSucursal,
    required this.nombre,
    required this.codEmpresa,
    required this.codCiudad,
    required this.audUsuarioI,
    required this.empresa,
    required this.nombreCiudad,
    required this.codSucursalPlanilla,
    required this.nombrePlanilla,
    this.nombreEmpresa = '',
    this.estado = 1,
    this.cargos = 0,
  });
}
