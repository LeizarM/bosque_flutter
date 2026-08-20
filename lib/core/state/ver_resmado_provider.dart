/// Estado de la pantalla "Ver resmado": el listado y el detalle de un resmado.
///
/// Del resmado ya registrado solo se corrigen dos datos, la orden de
/// fabricacion y la empresa. Lo demas —grupo, empleado, horas, articulos— se
/// captura en el momento del resmado y aqui se muestra como lectura.
library;

import 'package:bosque_flutter/data/repositories/resmado_impl.dart';
import 'package:bosque_flutter/domain/entities/detalle_resmando_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';
import 'package:bosque_flutter/domain/repositories/resmado_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El repositorio del modulo, para poder sustituirlo en pruebas.
final resmadoRepositoryProvider = Provider<ResmadoRepository>(
  (ref) => ResmadoImpl(),
);

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class VerResmadosState {
  final List<ResmadoEntity> resmados;
  final List<EmpresaEntity> empresas;
  final bool cargando;
  final String? error;

  /// Texto libre: grupo, empleado, empresa u orden de fabricacion.
  final String busqueda;

  /// Deja a la vista solo los resmados que todavia no tienen orden asignada,
  /// que son los que hay que completar.
  final bool soloSinOrden;

  /// El rango que se le pide al SP. A diferencia de los otros dos filtros, este
  /// no recorta en memoria: acota lo que viaja desde la base.
  final DateTime desde;
  final DateTime hasta;

  VerResmadosState({
    this.resmados = const [],
    this.empresas = const [],
    this.cargando = false,
    this.error,
    this.busqueda = '',
    this.soloSinOrden = false,
    DateTime? desde,
    DateTime? hasta,
  }) : desde = desde ?? rangoPorDefecto().desde,
       hasta = hasta ?? rangoPorDefecto().hasta;

  /// Del primer dia del mes en curso hasta hoy.
  static ({DateTime desde, DateTime hasta}) rangoPorDefecto() {
    final hoy = DateTime.now();
    return (desde: DateTime(hoy.year, hoy.month, 1), hasta: hoy);
  }

  List<ResmadoEntity> get visibles {
    final texto = busqueda.trim().toLowerCase();
    return resmados.where((r) {
      if (soloSinOrden && r.docNumOrdFab > 0) return false;
      if (texto.isEmpty) return true;
      return r.descripcion.toLowerCase().contains(texto) ||
          r.nombreCompleto.toLowerCase().contains(texto) ||
          r.empresa.toLowerCase().contains(texto) ||
          r.docNumOrdFab.toString().contains(texto);
    }).toList();
  }

  /// Cuantos quedan sin orden de fabricacion, sobre el total del periodo.
  int get sinOrden => resmados.where((r) => r.docNumOrdFab <= 0).length;

  // ── Resumen del periodo ──────────────────────────────────────────────────
  //
  // Se calcula sobre [resmados] y no sobre [visibles] a proposito: el resumen
  // describe el periodo, y los filtros son una lente sobre la tabla de abajo.
  // Si tomara los visibles, los totales bailarian mientras se escribe.

  double get totalResmado => resmados.fold(0.0, (s, r) => s + r.total);

  /// Lo resmado por grupo, ordenado de mayor a menor.
  List<ResumenGrupo> get porGrupo {
    final acumulado = <int, ResumenGrupo>{};
    for (final r in resmados) {
      final previo = acumulado[r.idGrupo];
      acumulado[r.idGrupo] = ResumenGrupo(
        idGrupo: r.idGrupo,
        nombre: r.descripcion.isEmpty ? 'Sin grupo' : r.descripcion,
        total: (previo?.total ?? 0) + r.total,
        cantidad: (previo?.cantidad ?? 0) + 1,
      );
    }
    final lista = acumulado.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return lista;
  }

  VerResmadosState copyWith({
    List<ResmadoEntity>? resmados,
    List<EmpresaEntity>? empresas,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    String? busqueda,
    bool? soloSinOrden,
    DateTime? desde,
    DateTime? hasta,
  }) => VerResmadosState(
    resmados: resmados ?? this.resmados,
    empresas: empresas ?? this.empresas,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    busqueda: busqueda ?? this.busqueda,
    soloSinOrden: soloSinOrden ?? this.soloSinOrden,
    desde: desde ?? this.desde,
    hasta: hasta ?? this.hasta,
  );
}

/// Lo que resmo un grupo en el periodo.
class ResumenGrupo {
  final int idGrupo;
  final String nombre;
  final double total;
  final int cantidad;

  const ResumenGrupo({
    required this.idGrupo,
    required this.nombre,
    required this.total,
    required this.cantidad,
  });
}

class VerResmadosNotifier extends StateNotifier<VerResmadosState> {
  VerResmadosNotifier(this._repo) : super(VerResmadosState()) {
    cargar();
  }

  final ResmadoRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final resultados = await Future.wait([
        _repo.obtenerResmados(state.desde, state.hasta),
        _repo.obtenerEmpresas(),
      ]);
      state = state.copyWith(
        resmados: resultados[0] as List<ResmadoEntity>,
        empresas: resultados[1] as List<EmpresaEntity>,
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  void setBusqueda(String valor) => state = state.copyWith(busqueda: valor);

  void setSoloSinOrden(bool valor) =>
      state = state.copyWith(soloSinOrden: valor);

  /// Cambiar el rango vuelve a consultar: el recorte lo hace el SP, no la app.
  Future<void> setRango(DateTime desde, DateTime hasta) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }

  /// Guarda la orden de fabricacion y la empresa de un resmado.
  ///
  /// Devuelve null si salio bien, o el mensaje a mostrar si fallo.
  Future<String?> guardarOrden({
    required ResmadoEntity resmado,
    required int docNumOrdFab,
    required int codEmpresa,
    required int audUsuario,
  }) async {
    final editado = resmado.copyWith(
      docNumOrdFab: docNumOrdFab,
      codEmpresa: codEmpresa,
    );
    editado.audUsuario = audUsuario;

    try {
      if (!await _repo.actualizarOrdenFabricacion(editado)) {
        return 'No se pudo guardar la orden de fabricacion.';
      }
    } catch (e) {
      return 'No se pudo guardar la orden de fabricacion: $e';
    }

    // Se refleja en la lista sin volver a pedirla: el nombre de la empresa se
    // resuelve con el catalogo que ya esta cargado.
    final nombreEmpresa = state.empresas
        .where((e) => e.codEmpresa == codEmpresa)
        .map((e) => e.nombre)
        .firstOrNull;

    state = state.copyWith(
      resmados: [
        for (final r in state.resmados)
          if (r.idRes == resmado.idRes)
            r.copyWith(
              docNumOrdFab: docNumOrdFab,
              codEmpresa: codEmpresa,
              empresa: nombreEmpresa ?? r.empresa,
            )
          else
            r,
      ],
    );
    return null;
  }
}

final verResmadosProvider =
    StateNotifierProvider.autoDispose<VerResmadosNotifier, VerResmadosState>(
      (ref) => VerResmadosNotifier(ref.watch(resmadoRepositoryProvider)),
    );

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE
// ═══════════════════════════════════════════════════════════════════════════

/// Los articulos resmados de un resmado. Es solo lectura, asi que alcanza con
/// un FutureProvider.
final detalleResmadoProvider = FutureProvider.autoDispose
    .family<List<DetalleResmadoEntity>, int>(
      (ref, idRes) =>
          ref.watch(resmadoRepositoryProvider).obtenerDetalleResmado(idRes),
    );
