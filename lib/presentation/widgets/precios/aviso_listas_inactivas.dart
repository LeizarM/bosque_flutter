/// Aviso de que la grilla no muestra las listas de precio inactivas: los
/// procedimientos de precios y porcentajes filtran `cp.estado = 1` (como el
/// sistema anterior) y, sin aviso, una familia con doce precios se ve con diez y
/// parece un error de carga.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';

class AvisoListasInactivas extends ConsumerWidget {
  const AvisoListasInactivas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filas = ref.watch(clasificacionesConSucursalProvider).valueOrNull;
    if (filas == null) return const SizedBox.shrink();

    final porSucursal = <String, List<int>>{};
    for (final f in filas) {
      if (_entero(f['estado']) != 0) continue;
      final cod = _entero(f['codSucursal']);
      final nombre = (f['nombreSucursal'] ?? '').toString().trim();
      porSucursal
          .putIfAbsent(nombre.isEmpty ? 'Sucursal $cod' : nombre, () => [])
          .add(_entero(f['vpp']));
    }
    if (porSucursal.isEmpty) return const SizedBox.shrink();

    final total = porSucursal.values.fold<int>(0, (s, v) => s + v.length);
    final detalle = [
      for (final e in porSucursal.entries) '${e.key} ${_rangos(e.value)}',
    ].join('; ');

    return NotaDelDato(
      texto:
          '${total == 1 ? 'No se muestra la lista inactiva' : 'No se muestran las $total listas inactivas'} '
          '($detalle): no se reprecian. Se activan en «Listas de precio».',
    );
  }

  /// "1, 2 y 5", o "30 a 35" cuando son seguidas.
  static String _rangos(List<int> vpps) {
    final ordenados = vpps.toSet().toList()..sort();
    final tramos = <String>[];
    var inicio = ordenados.first;
    var previo = inicio;
    void cerrar() {
      if (previo - inicio >= 2) {
        tramos.add('$inicio a $previo');
      } else {
        for (var v = inicio; v <= previo; v++) {
          tramos.add('$v');
        }
      }
    }

    for (final v in ordenados.skip(1)) {
      if (v == previo + 1) {
        previo = v;
        continue;
      }
      cerrar();
      inicio = v;
      previo = v;
    }
    cerrar();

    if (tramos.length == 1) return tramos.single;
    return '${tramos.sublist(0, tramos.length - 1).join(', ')} y ${tramos.last}';
  }

  static int _entero(Object? v) => switch (v) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()) ?? -1,
    _ => -1,
  };
}
