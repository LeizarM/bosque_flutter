// Destino final: lib/core/state/coche_provider.dart
//
// El catálogo de vehículos (`tac_coche`). El listado se descarga entero y se
// filtra del lado del cliente: son decenas de filas, y el backend descarta los
// ceros de los filtros (`estado = 0` no filtraría).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/coche_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/coche_repository.dart';

/// Perezoso y reemplazable: las pruebas lo cambian con `overrideWithValue`.
final cocheRepositoryProvider = Provider<CocheRepository>((ref) => CocheImpl());

@immutable
class CocheState {
  const CocheState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.error,
  });

  final List<CocheEntity> items;

  /// Hay una lectura en curso (la primera o una recarga).
  final bool cargando;

  /// Ya hubo al menos una respuesta buena. Distingue "todavía no llegó" de
  /// "llegó y no hay vehículos".
  final bool cargado;

  /// Por qué falló la última lectura; null si salió bien.
  final Object? error;

  CocheState copyWith({
    List<CocheEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? error,
    bool limpiarError = false,
  }) => CocheState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    error: limpiarError ? null : (error ?? this.error),
  );
}

class CocheNotifier extends StateNotifier<CocheState> {
  CocheNotifier(this._repo) : super(const CocheState()) {
    Future.microtask(cargar);
  }

  final CocheRepository _repo;

  /// Número de la última lectura lanzada. Dos lecturas pueden solaparse (la
  /// inicial y un «reintentar», o una recarga tras guardar): solo la más nueva
  /// escribe, y una respuesta tardía de la vieja no pisa a la buena. La vieja,
  /// en vez de terminar «en seco», espera a la nueva: quien hizo `await cargar()`
  /// vuelve con el estado ya resuelto.
  int _lectura = 0;
  Future<void>? _actual;

  Future<void> cargar() {
    if (!mounted) return Future<void>.value();
    final lectura = _leer(++_lectura);
    _actual = lectura;
    return lectura;
  }

  Future<void> _leer(int mia) async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final datos = await _repo.obtener();
      if (!mounted) return;
      if (mia != _lectura) return await _actual;
      state = state.copyWith(items: datos, cargando: false, cargado: true);
    } catch (e) {
      if (!mounted) return;
      if (mia != _lectura) return await _actual;
      state = state.copyWith(cargando: false, error: e);
    }
  }

  /// Alta (`idCoche == 0`) o edición. Si el servidor rechaza, **lanza** con su
  /// motivo: quien llama (la ficha) lo muestra y queda abierta. Al salir bien
  /// recarga el listado.
  Future<void> guardar(CocheEntity item) async {
    await _repo.registrar(item);
    await cargar();
  }

  /// Lanza si el coche tiene movimiento; entonces corresponde darlo de baja.
  Future<void> eliminar(int idCoche, int audUsuario) async {
    await _repo.eliminar(idCoche, audUsuario);
    await cargar();
  }
}

final cocheProvider =
    StateNotifierProvider.autoDispose<CocheNotifier, CocheState>(
      (ref) => CocheNotifier(ref.watch(cocheRepositoryProvider)),
    );

// ── Filtros del listado ─────────────────────────────────────────────────────

enum EstadoFiltroCoche { todos, activos, inactivos }

/// Los criterios del listado. Es un valor puro, sin Riverpod: la pantalla lo
/// guarda en un provider local y las pruebas lo ejercitan solo.
@immutable
class FiltroCoches {
  const FiltroCoches({
    this.texto = '',
    this.codSucursal,
    this.estado = EstadoFiltroCoche.todos,
  });

  /// Texto libre. Cada palabra tiene que aparecer en algún dato del coche.
  final String texto;
  final int? codSucursal;
  final EstadoFiltroCoche estado;

  /// Cuántos criterios hay puestos además del buscador, para avisarlo en el
  /// panel plegado del teléfono.
  int get criterios =>
      (codSucursal != null ? 1 : 0) +
      (estado != EstadoFiltroCoche.todos ? 1 : 0);

  bool get hayAlgo => texto.trim().isNotEmpty || criterios > 0;

  FiltroCoches copyWith({
    String? texto,
    int? codSucursal,
    bool limpiarSucursal = false,
    EstadoFiltroCoche? estado,
  }) => FiltroCoches(
    texto: texto ?? this.texto,
    codSucursal: limpiarSucursal ? null : (codSucursal ?? this.codSucursal),
    estado: estado ?? this.estado,
  );

  /// Los coches que cumplen todo, ordenados por placa.
  List<CocheEntity> aplicar(List<CocheEntity> origen) {
    final palabras =
        texto
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();

    bool cumple(CocheEntity c) {
      if (codSucursal != null && c.codSucursal != codSucursal) return false;
      switch (estado) {
        case EstadoFiltroCoche.activos:
          if (!c.esActivo) return false;
        case EstadoFiltroCoche.inactivos:
          if (c.esActivo) return false;
        case EstadoFiltroCoche.todos:
          break;
      }
      if (palabras.isEmpty) return true;
      final pajar = textoBuscable(c);
      return palabras.every(pajar.contains);
    }

    return origen.where(cumple).toList()..sort(
      (a, b) => (a.placa ?? '').toLowerCase().compareTo(
        (b.placa ?? '').toLowerCase(),
      ),
    );
  }

  /// Lo que mira el buscador, en minúsculas. El estado no entra: «activo» está
  /// contenido en «inactivo» y el buscador devolvería los dos.
  static String textoBuscable(CocheEntity c) =>
      [
        c.placa,
        c.marca,
        c.clase,
        c.color,
        c.nombreSucursal,
        c.anio?.toString(),
      ].whereType<String>().join(' ').toLowerCase();
}

// ── Sucursales para los combos ──────────────────────────────────────────────

@immutable
class OpcionSucursal {
  const OpcionSucursal(this.codSucursal, this.nombre);

  final int codSucursal;
  final String nombre;
}

/// Las sucursales del catálogo, más las que ya usan los coches y el catálogo no
/// trae (una dada de baja, o el catálogo que no cargó): así un coche nunca queda
/// apuntando a una sucursal que el combo no sabe nombrar. Ordenadas por nombre.
///
/// `p_list_Sucursal` 'L' (la que sirve `/gasolinaMaquina/lstSucursal`) agrega al
/// final una fila de relleno, «-- Defina Nueva Sucursal --» con código -1, que
/// sirve a los formularios de alta de sucursal. Aquí no es una sucursal: se
/// descarta por código (≤ 0), como ya hace la pantalla de garrafas.
List<OpcionSucursal> opcionesDeSucursal({
  List<SucursalEntity>? catalogo,
  List<CocheEntity> coches = const [],
}) {
  final porCodigo = <int, String>{};
  for (final s in catalogo ?? const <SucursalEntity>[]) {
    if (s.codSucursal <= 0) continue;
    porCodigo[s.codSucursal] = s.nombre.trim();
  }
  for (final c in coches) {
    final cod = c.codSucursal;
    if (cod == null || porCodigo.containsKey(cod)) continue;
    final nombre = c.nombreSucursal?.trim() ?? '';
    porCodigo[cod] = nombre.isEmpty ? 'Sucursal $cod' : nombre;
  }
  return [for (final e in porCodigo.entries) OpcionSucursal(e.key, e.value)]
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
}
