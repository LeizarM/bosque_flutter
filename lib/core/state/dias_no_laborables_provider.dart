import 'package:bosque_flutter/data/repositories/dias_no_laborables_impl.dart';
import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_seleccion_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grilla de dias no laborables filtrada por gestion (anio). 0 = sin filtro.
final diasNoLaborablesProvider = FutureProvider.autoDispose
    .family<List<DiaNoLaborableEntity>, int>((ref, gestion) async {
      final repo = DiasNoLaborablesImpl();
      return repo.obtenerDiasNoLaborables(gestion: gestion);
    });

/// Matriz de sucursales para el modal ABM. BigInt.zero = registro nuevo (todas sin marcar).
final sucursalesDiaNoLaborableProvider = FutureProvider.autoDispose
    .family<List<SucursalSeleccionEntity>, BigInt>((ref, idDiaNoLaborable) async {
      final repo = DiasNoLaborablesImpl();
      return repo.obtenerSucursalesDiaNoLaborable(idDiaNoLaborable);
    });
