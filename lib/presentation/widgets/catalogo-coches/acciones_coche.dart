/// Lo que se puede hacer con un vehículo desde su fila o su tarjeta, y los
/// textos que la tabla, la tarjeta y las confirmaciones comparten para que digan
/// lo mismo.
library;

import 'package:bosque_flutter/domain/entities/coche_entity.dart';

enum AccionCoche { editar, cambiarEstado, eliminar }

/// «Dar de baja» y «Reactivar» son la misma acción vista desde cada estado.
String rotuloCambiarEstado(CocheEntity c) =>
    c.esActivo ? 'Dar de baja' : 'Reactivar';

/// La placa, o un rótulo si el dato falta (hay filas históricas sin ella).
String placaLegible(CocheEntity c) {
  final p = c.placa?.trim() ?? '';
  return p.isEmpty ? 'Sin placa' : p;
}

String oGuion(String? valor) {
  final v = valor?.trim() ?? '';
  return v.isEmpty ? '--' : v;
}

/// «Suzuki Minibus»: lo que la gente dice al nombrar un vehículo.
String descripcionVehiculo(CocheEntity c) {
  final partes = [
    c.marca?.trim() ?? '',
    c.clase?.trim() ?? '',
  ].where((p) => p.isNotEmpty);
  return partes.isEmpty ? 'Sin descripción' : partes.join(' ');
}

/// El nombre de la sucursal; si el listado no lo trajo, el código.
String sucursalLegible(CocheEntity c) {
  final nombre = c.nombreSucursal?.trim() ?? '';
  if (nombre.isNotEmpty) return nombre;
  final cod = c.codSucursal;
  return cod == null ? '--' : 'Sucursal $cod';
}
