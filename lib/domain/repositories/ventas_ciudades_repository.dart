import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';

abstract class VentasCiudadesRepository {
  /// Ciudades que el usuario actual puede ver en el catálogo.
  Future<CiudadesPermitidasEntity> ciudadesPermitidas();

  /// Todas las ciudades de venta, para las casillas de la gestión.
  Future<List<CiudadVentaEntity>> ciudadesVenta();

  /// Todas las excepciones asignadas (solo administradores).
  Future<List<CiudadVentaEntity>> asignaciones();

  Future<void> asignar(int codUsuario, int codCiudad);

  Future<void> quitar(int codUsuario, int codCiudad);
}
