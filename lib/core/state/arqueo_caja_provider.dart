// Destino final: lib/core/state/arqueo_caja_provider.dart
import 'package:bosque_flutter/data/repositories/arqueo_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/corte_entity.dart';
import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArqueoCajaState {
  final Map<int, int> cantidadPorCorte;
  final Map<int, double> montoPorDoc;
  final List<ValeArqueoEntity> vales;
  final double saldoMovSap;
  final double tc;
  final String obs;
  final bool guardando;
  final String? mensajeError;
  final bool completado;

  // Contexto real (no manual) — ver ACCIONes 'A'/'T'/'H' del backend.
  final bool cargandoContexto;
  final List<Map<String, dynamic>> desgloseSap; // por caja: {bd, monto}
  final double?
  tcAyer; // null = no disponible (servidor enlazado caído, o simplemente no hay "ayer")
  final Map<String, dynamic>?
  anterior; // el arqueo anterior de esta sucursal, o null si es el primero

  const ArqueoCajaState({
    this.cantidadPorCorte = const {},
    this.montoPorDoc = const {},
    this.vales = const [],
    this.saldoMovSap = 0,
    this.tc = 1,
    this.obs = '',
    this.guardando = false,
    this.mensajeError,
    this.completado = false,
    this.cargandoContexto = false,
    this.desgloseSap = const [],
    this.tcAyer,
    this.anterior,
  });

  ArqueoCajaState copyWith({
    Map<int, int>? cantidadPorCorte,
    Map<int, double>? montoPorDoc,
    List<ValeArqueoEntity>? vales,
    double? saldoMovSap,
    double? tc,
    String? obs,
    bool? guardando,
    String? mensajeError,
    bool? completado,
    bool? cargandoContexto,
    List<Map<String, dynamic>>? desgloseSap,
    double? tcAyer,
    Map<String, dynamic>? anterior,
  }) => ArqueoCajaState(
    cantidadPorCorte: cantidadPorCorte ?? this.cantidadPorCorte,
    montoPorDoc: montoPorDoc ?? this.montoPorDoc,
    vales: vales ?? this.vales,
    saldoMovSap: saldoMovSap ?? this.saldoMovSap,
    tc: tc ?? this.tc,
    obs: obs ?? this.obs,
    guardando: guardando ?? this.guardando,
    mensajeError: mensajeError,
    completado: completado ?? this.completado,
    cargandoContexto: cargandoContexto ?? this.cargandoContexto,
    desgloseSap: desgloseSap ?? this.desgloseSap,
    tcAyer: tcAyer ?? this.tcAyer,
    anterior: anterior ?? this.anterior,
  );

  /// Mismo cálculo que el servidor (p_arqueo_registrar): cortes en dólares
  /// se convierten a Bs con `tc`, + documentación + vales válidos.
  double totalCon(List<CorteEntity> catalogoCortes) {
    double totalCortes = 0;
    for (final corte in catalogoCortes) {
      final cantidad = cantidadPorCorte[corte.idCorte] ?? 0;
      if (cantidad <= 0) continue;
      final valor = corte.corte ?? 0;
      final factor = corte.tipoCorte == 'DOLARES' ? tc : 1;
      totalCortes += cantidad * valor * factor;
    }
    final totalDocs = montoPorDoc.values.fold<double>(0, (a, b) => a + b);
    final totalVales = vales
        .where((v) => v.esValido)
        .fold<double>(0, (a, v) => a + (v.monto ?? 0));
    return totalCortes + totalDocs + totalVales;
  }

  double diferenciaCon(List<CorteEntity> catalogoCortes) =>
      totalCon(catalogoCortes) - saldoMovSap;
}

class ArqueoCajaNotifier extends StateNotifier<ArqueoCajaState> {
  final ArqueoCajaImpl _repo;
  int _contadorVale = 0;

  ArqueoCajaNotifier(this._repo) : super(const ArqueoCajaState());

  void setCantidadCorte(int idCorte, int cantidad) {
    state = state.copyWith(
      cantidadPorCorte: {...state.cantidadPorCorte, idCorte: cantidad},
    );
  }

  void setMontoDoc(int idDoc, double monto) {
    state = state.copyWith(montoPorDoc: {...state.montoPorDoc, idDoc: monto});
  }

  void setSaldoMovSap(double v) => state = state.copyWith(saldoMovSap: v);
  void setTc(double v) => state = state.copyWith(tc: v);
  void setObs(String v) => state = state.copyWith(obs: v);

  /// Trae el contexto real del arqueo (desglose SAP por caja, tc hoy/ayer,
  /// arqueo anterior) y AUTOCOMPLETA saldoMovSap/tc con lo que trae el
  /// servidor — igual que el legacy, que arranca el formulario con estos
  /// valores ya resueltos en vez de en blanco. Sigue siendo editable después
  /// (no se bloquea el campo): si el desglose no cuadra con lo que el
  /// usuario ve en el efectivo real, puede corregirlo antes de guardar.
  Future<void> cargarContexto(int idBitTarea) async {
    state = state.copyWith(cargandoContexto: true);
    try {
      final resultados = await Future.wait([
        _repo.saldoSap(idBitTarea),
        _repo.tipoCambio(),
        _repo.arqueoAnterior(idBitTarea),
      ]);
      final desglose = resultados[0];
      final tipoCambio = resultados[1];
      final anteriorLista = resultados[2];

      final totalSap = desglose.fold<double>(
        0,
        (a, fila) => a + ((fila['monto'] as num?)?.toDouble() ?? 0),
      );
      final filaHoy = tipoCambio.firstWhere(
        (f) => (f['dia'] as String?)?.toLowerCase() == 'hoy',
        orElse: () => const {},
      );
      final filaAyer = tipoCambio.firstWhere(
        (f) => (f['dia'] as String?)?.toLowerCase() == 'ayer',
        orElse: () => const {},
      );
      final tcHoy = (filaHoy['tipoCambio'] as num?)?.toDouble();

      state = state.copyWith(
        cargandoContexto: false,
        desgloseSap: desglose,
        saldoMovSap: desglose.isNotEmpty ? totalSap : state.saldoMovSap,
        tc: tcHoy ?? state.tc,
        tcAyer: (filaAyer['tipoCambio'] as num?)?.toDouble(),
        anterior: anteriorLista.isNotEmpty ? anteriorLista.first : null,
      );
    } catch (e) {
      // El contexto es una ayuda, no un bloqueo: si falla, el formulario
      // sigue usable con entrada manual — mismo criterio que "0 traspasos
      // hoy es válido" en otros flujos de este módulo.
      state = state.copyWith(cargandoContexto: false);
    }
  }

  void agregarVale() {
    state = state.copyWith(
      vales: [...state.vales, ValeArqueoEntity(id: '${_contadorVale++}')],
    );
  }

  void quitarVale(String id) {
    state = state.copyWith(
      vales: state.vales.where((v) => v.id != id).toList(),
    );
  }

  void actualizarVale(
    String id,
    ValeArqueoEntity Function(ValeArqueoEntity) actualizar,
  ) {
    state = state.copyWith(
      vales: state.vales.map((v) => v.id == id ? actualizar(v) : v).toList(),
    );
  }

  Future<bool> registrar({
    required int idTarRuti,
    required int idBitTarea,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      await _repo.registrar(
        idTarRuti: idTarRuti,
        idBitTarea: idBitTarea,
        saldoMovSap: state.saldoMovSap,
        tc: state.tc,
        obs: state.obs.isEmpty ? null : state.obs,
        cantidadPorCorte: state.cantidadPorCorte,
        montoPorDoc: state.montoPorDoc,
        vales: state.vales,
      );
      state = state.copyWith(guardando: false, completado: true);
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _arqueoCajaRepoProvider = Provider((ref) => ArqueoCajaImpl());

final arqueoCajaProvider =
    StateNotifierProvider.autoDispose<ArqueoCajaNotifier, ArqueoCajaState>(
      (ref) => ArqueoCajaNotifier(ref.read(_arqueoCajaRepoProvider)),
    );
