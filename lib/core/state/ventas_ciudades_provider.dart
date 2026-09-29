import 'package:bosque_flutter/data/repositories/ventas_ciudades_impl.dart';
import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';
import 'package:bosque_flutter/domain/repositories/ventas_ciudades_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ventasCiudadesRepositoryProvider = Provider<VentasCiudadesRepository>(
  (ref) => VentasCiudadesImpl(),
);

/// Ciudades del selector del catálogo. `autoDispose`: al volver a entrar a
/// Ventas se vuelve a pedir, así un cambio de asignación se ve sin reloguear.
final ciudadesPermitidasProvider =
    FutureProvider.autoDispose<CiudadesPermitidasEntity>((ref) {
      return ref.watch(ventasCiudadesRepositoryProvider).ciudadesPermitidas();
    });

/// Botón del ACL que habilita "Ciudades por usuario" (`tb_vistaBtn`). El
/// backend exige el mismo en `/paginaXApp/usuarioCiudad/*`.
const String btnCiudadesUsuario = 'btnCiudadesUsuario';

/// Todas las ciudades de venta: las casillas de la gestión. No sale de
/// [ciudadesPermitidasProvider] porque quien gestiona puede no ser admin.
final ciudadesVentaProvider =
    FutureProvider.autoDispose<List<CiudadVentaEntity>>((ref) {
      return ref.watch(ventasCiudadesRepositoryProvider).ciudadesVenta();
    });

/// Excepciones asignadas, agrupadas por usuario (pantalla de gestión).
final asignacionesCiudadProvider =
    FutureProvider.autoDispose<Map<int, Set<int>>>((ref) async {
      final lista =
          await ref.watch(ventasCiudadesRepositoryProvider).asignaciones();
      final porUsuario = <int, Set<int>>{};
      for (final a in lista) {
        porUsuario.putIfAbsent(a.codUsuario, () => <int>{}).add(a.codCiudad);
      }
      return porUsuario;
    });
