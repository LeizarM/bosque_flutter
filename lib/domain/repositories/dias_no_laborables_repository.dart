import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_seleccion_entity.dart';

abstract class DiasNoLaborablesRepository {
  /// Registra o actualiza un dia no laborable (cabecera + sucursales, atomico en el backend).
  Future<BigInt> registrarDiaNoLaborable(Map<String, dynamic> payload);

  /// Elimina un dia no laborable por su id.
  Future<BigInt> eliminarDiaNoLaborable(Map<String, dynamic> payload);

  /// Obtiene la grilla de dias no laborables. gestion 0 = sin filtrar por anio.
  Future<List<DiaNoLaborableEntity>> obtenerDiasNoLaborables({int gestion});

  /// Obtiene la matriz de sucursales para el modal ABM. idDiaNoLaborable cero = registro nuevo, todas sin marcar.
  Future<List<SucursalSeleccionEntity>> obtenerSucursalesDiaNoLaborable(
    BigInt idDiaNoLaborable,
  );
}
