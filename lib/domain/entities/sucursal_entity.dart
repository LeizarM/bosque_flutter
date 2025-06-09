import 'package:bosque_flutter/domain/entities/empresa_entity.dart';

class SucursalEntity {
    final int codSucursal;
    final String nombre;
    final int codEmpresa;
    final int codCiudad;
    final int audUsuarioI;
    final EmpresaEntity empresa;
    final String nombreCiudad;

    SucursalEntity({
        required this.codSucursal,
        required this.nombre,
        required this.codEmpresa,
        required this.codCiudad,
        required this.audUsuarioI,
        required this.empresa,
        required this.nombreCiudad,
    });

}