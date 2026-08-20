/// Estado de la pantalla "Ver lote de produccion": el listado y el detalle
/// editable de un lote.
///
/// El listado y el detalle son dos providers separados porque tienen ciclos de
/// vida distintos: el listado vive mientras la pantalla este abierta, el
/// detalle nace y muere con cada lote que se abre.
library;

import 'package:bosque_flutter/data/repositories/lote_produccion_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';
import 'package:bosque_flutter/domain/repositories/lote_produccion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El repositorio del modulo, para poder sustituirlo en pruebas.
final loteProduccionRepositoryProvider = Provider<LoteProduccionRepository>(
  (ref) => LoteProduccionImpl(),
);

// ═══════════════════════════════════════════════════════════════════════════
// CATALOGOS
// ═══════════════════════════════════════════════════════════════════════════
//
// No son autoDispose a proposito: articulos, empresas y maquinas son los
// mismos para todos los lotes y no cambian durante la sesion. Pedirlos dentro
// del detalle significaba traer 2.356 articulos cada vez que se abria un lote.

/// Catalogo de articulos, ya ordenado.
///
/// El orden se resuelve aqui y no en el widget: ordenar 2.356 elementos en cada
/// dibujo del detalle —y el detalle se redibuja con cada tecla— era la mitad
/// del congelamiento al escribir un peso.
final articulosProduccionProvider = FutureProvider<List<LoteProduccionEntity>>((
  ref,
) async {
  final lista = await ref.watch(loteProduccionRepositoryProvider)
      .obtenerArticulos();
  lista.sort((a, b) => a.articulo.compareTo(b.articulo));
  return lista;
});

final empresasProduccionProvider = FutureProvider<List<EmpresaEntity>>(
  (ref) => ref.watch(loteProduccionRepositoryProvider).obtenerEmpresas(),
);

final maquinasProduccionProvider = FutureProvider<List<MaquinaProduccionEntity>>(
  (ref) => ref.watch(loteProduccionRepositoryProvider).obtenerMaquinas(),
);

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class VerLotesState {
  final List<LoteProduccionEntity> lotes;
  final List<MaquinaProduccionEntity> maquinas;
  final bool cargando;
  final String? error;

  /// Texto libre: numero de lote, orden de fabricacion u observacion.
  final String busqueda;

  /// null = todas las maquinas.
  final int? idMaquina;

  /// El rango que se le pide al SP. A diferencia de los otros dos filtros, este
  /// no recorta en memoria: acota lo que viaja desde la base.
  final DateTime desde;
  final DateTime hasta;

  VerLotesState({
    this.lotes = const [],
    this.maquinas = const [],
    this.cargando = false,
    this.error,
    this.busqueda = '',
    this.idMaquina,
    DateTime? desde,
    DateTime? hasta,
  }) : desde = desde ?? rangoPorDefecto().desde,
       hasta = hasta ?? rangoPorDefecto().hasta;

  /// Del primer dia del mes en curso hasta hoy: es el recorte con el que se
  /// mira la produccion todos los dias.
  static ({DateTime desde, DateTime hasta}) rangoPorDefecto() {
    final hoy = DateTime.now();
    return (desde: DateTime(hoy.year, hoy.month, 1), hasta: hoy);
  }

  /// Los lotes que hay que dibujar, ya filtrados.
  List<LoteProduccionEntity> get visibles {
    final texto = busqueda.trim().toLowerCase();
    return lotes.where((l) {
      if (idMaquina != null && l.idMa != idMaquina) return false;
      if (texto.isEmpty) return true;
      return '${l.numLote}/${l.anio}'.contains(texto) ||
          l.numLote.toString().contains(texto) ||
          l.docNumOrdFab.toString().contains(texto) ||
          l.obs.toLowerCase().contains(texto);
    }).toList();
  }

  VerLotesState copyWith({
    List<LoteProduccionEntity>? lotes,
    List<MaquinaProduccionEntity>? maquinas,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    String? busqueda,
    int? idMaquina,
    bool todasLasMaquinas = false,
    DateTime? desde,
    DateTime? hasta,
  }) => VerLotesState(
    lotes: lotes ?? this.lotes,
    maquinas: maquinas ?? this.maquinas,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    busqueda: busqueda ?? this.busqueda,
    idMaquina: todasLasMaquinas ? null : (idMaquina ?? this.idMaquina),
    desde: desde ?? this.desde,
    hasta: hasta ?? this.hasta,
  );
}

class VerLotesNotifier extends StateNotifier<VerLotesState> {
  VerLotesNotifier(this._ref, this._repo) : super(VerLotesState()) {
    cargar();
  }

  final Ref _ref;
  final LoteProduccionRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lotes = await _repo.obtenerLotesRegistrados(
        state.desde,
        state.hasta,
      );
      final maquinas = await _ref.read(maquinasProduccionProvider.future);
      // Ver la nota en DetalleLoteNotifier: un catalogo vacio es una red caida,
      // no un catalogo sin datos, y no debe quedarse en la cache.
      if (maquinas.isEmpty) _ref.invalidate(maquinasProduccionProvider);
      state = state.copyWith(
        lotes: lotes,
        maquinas: maquinas,
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  void setBusqueda(String valor) => state = state.copyWith(busqueda: valor);

  void setMaquina(int? idMa) => state =
      idMa == null
          ? state.copyWith(todasLasMaquinas: true)
          : state.copyWith(idMaquina: idMa);

  /// Cambiar el rango vuelve a consultar: el recorte lo hace el SP, no la app.
  Future<void> setRango(DateTime desde, DateTime hasta) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }
}

final verLotesProvider =
    StateNotifierProvider.autoDispose<VerLotesNotifier, VerLotesState>(
      (ref) =>
          VerLotesNotifier(ref, ref.watch(loteProduccionRepositoryProvider)),
    );

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE
// ═══════════════════════════════════════════════════════════════════════════

typedef DetalleLoteParams = ({int idLp, int audUsuario});

class DetalleLoteState {
  final LoteProduccionEntity? lote;
  final List<MaterialIngresoEntity> ingresos;
  final List<MaterialSalidaEntity> salidas;
  final List<MermaEntity> mermas;
  final List<EmpresaEntity> empresas;
  final List<MaquinaProduccionEntity> maquinas;

  /// Catalogo de articulos: de aqui sale la UTM que estima las resmas.
  final List<LoteProduccionEntity> articulos;

  /// El lote tiene un articulo de ingreso y uno de salida para todas sus
  /// filas: se eligen arriba de cada tabla y se aplican a todo el detalle.
  final String codArticuloIngreso;
  final String codArticuloSalida;

  final bool cargando;
  final bool guardando;
  final String? error;

  const DetalleLoteState({
    this.lote,
    this.ingresos = const [],
    this.salidas = const [],
    this.mermas = const [],
    this.empresas = const [],
    this.maquinas = const [],
    this.articulos = const [],
    this.codArticuloIngreso = '',
    this.codArticuloSalida = '',
    this.cargando = true,
    this.guardando = false,
    this.error,
  });

  // ── Totales: se recalculan desde el detalle, nunca se editan a mano ──────

  double get totalPesoIngreso =>
      ingresos.fold(0.0, (s, e) => s + e.pesoKilos);
  double get totalBalanza => ingresos.fold(0.0, (s, e) => s + e.balanza);
  double get totalPesoResma => salidas.fold(0.0, (s, e) => s + e.pesoResma);
  double get totalPesoPaleta => salidas.fold(0.0, (s, e) => s + e.pesoPaleta);
  double get totalPesoMaterial =>
      salidas.fold(0.0, (s, e) => s + e.pesoMaterial);
  int get totalCantResma => salidas.fold(0, (s, e) => s + e.cantidadResma);
  int get totalCantHojas => salidas.fold(0, (s, e) => s + e.cantidadHojas);
  double get totalMerma => mermas.fold(0.0, (s, e) => s + e.peso);

  /// Kilos que entraron menos los que salieron como material y como merma.
  double get difProduccion =>
      totalPesoIngreso - (totalPesoMaterial + totalMerma);

  /// El articulo de salida elegido, para leer su UTM.
  LoteProduccionEntity? get articuloSalida {
    for (final a in articulos) {
      if (a.codArticulo == codArticuloSalida) return a;
    }
    return null;
  }

  /// Resmas que deberian haber salido segun el peso de balanza.
  ///
  /// Sin UTM no hay estimacion posible: devuelve 0 en lugar de inventar un
  /// factor 1, que daria un numero con apariencia de dato real.
  double get cantEstimadaResma {
    final utm = articuloSalida?.utm ?? 0;
    if (utm <= 0) return 0;
    return (totalBalanza - totalMerma) / 1000 * utm;
  }

  double get difResma => totalCantResma - cantEstimadaResma;

  /// El lote quedo cerrado: solo se abre con permiso.
  bool get cerrado => (lote?.estado ?? 0) == 0;

  DetalleLoteState copyWith({
    LoteProduccionEntity? lote,
    List<MaterialIngresoEntity>? ingresos,
    List<MaterialSalidaEntity>? salidas,
    List<MermaEntity>? mermas,
    List<EmpresaEntity>? empresas,
    List<MaquinaProduccionEntity>? maquinas,
    List<LoteProduccionEntity>? articulos,
    String? codArticuloIngreso,
    String? codArticuloSalida,
    bool? cargando,
    bool? guardando,
    String? error,
    bool limpiarError = false,
  }) => DetalleLoteState(
    lote: lote ?? this.lote,
    ingresos: ingresos ?? this.ingresos,
    salidas: salidas ?? this.salidas,
    mermas: mermas ?? this.mermas,
    empresas: empresas ?? this.empresas,
    maquinas: maquinas ?? this.maquinas,
    articulos: articulos ?? this.articulos,
    codArticuloIngreso: codArticuloIngreso ?? this.codArticuloIngreso,
    codArticuloSalida: codArticuloSalida ?? this.codArticuloSalida,
    cargando: cargando ?? this.cargando,
    guardando: guardando ?? this.guardando,
    error: limpiarError ? null : (error ?? this.error),
  );
}

class DetalleLoteNotifier extends StateNotifier<DetalleLoteState> {
  DetalleLoteNotifier(this._ref, this._repo, this._params)
    : super(const DetalleLoteState()) {
    cargar();
  }

  final Ref _ref;
  final LoteProduccionRepository _repo;
  final DetalleLoteParams _params;

  /// Las tres consultas del lote van juntas y los catalogos salen de la cache.
  ///
  /// Antes eran seis llamadas encadenadas —una esperando a la anterior— y tres
  /// de ellas traian datos que no dependen del lote. Abrir un lote costaba seis
  /// idas y vueltas al servidor, con el catalogo de articulos entero adentro.
  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final idLp = _params.idLp;

      final detalle = await Future.wait([
        _repo.obtenerMaterialIngresoXLote(idLp),
        _repo.obtenerMaterialSalidaXLote(idLp),
        _repo.obtenerMermaXLote(idLp),
      ]);
      final ingresos = detalle[0] as List<MaterialIngresoEntity>;
      final salidas = detalle[1] as List<MaterialSalidaEntity>;
      final mermas = detalle[2] as List<MermaEntity>;

      final catalogos = await Future.wait([
        _ref.read(articulosProduccionProvider.future),
        _ref.read(empresasProduccionProvider.future),
        _ref.read(maquinasProduccionProvider.future),
      ]);

      final articulos = catalogos[0] as List<LoteProduccionEntity>;
      final empresas = catalogos[1] as List<EmpresaEntity>;
      final maquinas = catalogos[2] as List<MaquinaProduccionEntity>;

      // Los repositorios devuelven lista vacia cuando la red falla, no una
      // excepcion. Sin esto, un catalogo que fallo una vez quedaba cacheado
      // vacio para toda la sesion y el selector de articulos no se recuperaba.
      _invalidarSiVacio(articulos, articulosProduccionProvider);
      _invalidarSiVacio(empresas, empresasProduccionProvider);
      _invalidarSiVacio(maquinas, maquinasProduccionProvider);

      state = state.copyWith(
        ingresos: ingresos,
        salidas: salidas,
        mermas: mermas,
        articulos: articulos,
        empresas: empresas,
        maquinas: maquinas,
        codArticuloIngreso:
            ingresos.isNotEmpty ? ingresos.first.codArticulo : '',
        codArticuloSalida: salidas.isNotEmpty ? salidas.first.codArticulo : '',
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  /// Descarta un catalogo vacio de la cache para que el proximo intento vuelva
  /// a pedirlo. No relee aqui: eso seria un ciclo si el servidor sigue caido.
  void _invalidarSiVacio(List<Object?> lista, ProviderOrFamily provider) {
    if (lista.isEmpty) _ref.invalidate(provider);
  }

  /// El lote llega ya cargado desde el listado: no hay endpoint que traiga uno
  /// solo, y volver a pedir los 125 para quedarse con uno no aporta nada.
  void setLote(LoteProduccionEntity lote) => state = state.copyWith(lote: lote);

  // ── Cabecera ─────────────────────────────────────────────────────────────

  void setMaquina(int idMa) {
    final l = state.lote;
    if (l == null) return;
    l.idMa = idMa;
    state = state.copyWith(lote: l);
  }

  void setFecha(DateTime fecha) {
    final l = state.lote;
    if (l == null) return;
    l.fecha = fecha;
    state = state.copyWith(lote: l);
  }

  void setHoras({String? inicioCorte, String? inicio, String? fin}) {
    final l = state.lote;
    if (l == null) return;
    if (inicioCorte != null) l.hraInicioCorte = inicioCorte;
    if (inicio != null) l.hraInicio = inicio;
    if (fin != null) l.hraFin = fin;
    state = state.copyWith(lote: l);
  }

  void setObservacion(String obs) {
    final l = state.lote;
    if (l == null) return;
    l.obs = obs;
    state = state.copyWith(lote: l);
  }

  void setOrdenFabricacion(int docNum) {
    final l = state.lote;
    if (l == null) return;
    l.docNumOrdFab = docNum;
    state = state.copyWith(lote: l);
  }

  void setEmpresa(int codEmpresa) {
    final l = state.lote;
    if (l == null) return;
    l.codEmpresa = codEmpresa;
    state = state.copyWith(lote: l);
  }

  // ── Detalle ──────────────────────────────────────────────────────────────

  void setArticuloIngreso(String cod) =>
      state = state.copyWith(codArticuloIngreso: cod);

  void setArticuloSalida(String cod) =>
      state = state.copyWith(codArticuloSalida: cod);

  void editarIngreso(
    int indice, {
    double? pesoKilos,
    double? balanza,
    String? numImportacion,
  }) {
    final lista = [...state.ingresos];
    final fila = lista[indice];
    if (pesoKilos != null) fila.pesoKilos = pesoKilos;
    if (balanza != null) fila.balanza = balanza;
    if (numImportacion != null) fila.numImportacion = numImportacion;
    state = state.copyWith(ingresos: lista);
  }

  void editarSalida(
    int indice, {
    int? nroPaleta,
    double? pesoResma,
    double? pesoPaleta,
    double? pesoMaterial,
    int? cantidadResma,
    int? cantidadHojas,
  }) {
    final lista = [...state.salidas];
    final fila = lista[indice];
    if (nroPaleta != null) fila.nroPaleta = nroPaleta;
    if (pesoResma != null) fila.pesoResma = pesoResma;
    if (pesoPaleta != null) fila.pesoPaleta = pesoPaleta;
    if (pesoMaterial != null) fila.pesoMaterial = pesoMaterial;
    if (cantidadResma != null) fila.cantidadResma = cantidadResma;
    if (cantidadHojas != null) fila.cantidadHojas = cantidadHojas;
    state = state.copyWith(salidas: lista);
  }

  void editarMerma(int indice, double peso) {
    final lista = [...state.mermas];
    lista[indice].peso = peso;
    state = state.copyWith(mermas: lista);
  }

  // ── Guardar ──────────────────────────────────────────────────────────────

  /// Guarda cabecera y detalle, y deja el lote cerrado.
  ///
  /// Cerrarlo al guardar es la regla del sistema anterior: un lote se edita
  /// mientras esta abierto y despues solo lo reabre quien tenga el permiso.
  ///
  /// La cabecera va primero porque el SP recalcula la cantidad de bobinas
  /// contra las filas de ingreso que ya estan en la base.
  Future<String?> guardar() async {
    final lote = state.lote;
    if (lote == null) return 'No hay lote cargado.';

    state = state.copyWith(guardando: true, limpiarError: true);

    final usuario = _params.audUsuario;
    final idLp = _params.idLp;
    final articuloIngreso = _articulo(state.codArticuloIngreso);
    final articuloSalida = _articulo(state.codArticuloSalida);

    lote.audUsuario = usuario;
    lote.estado = 0;
    lote.cantBobinasIngresoTotal = state.ingresos.length;
    lote.pesoKilosTotalIngreso = state.totalPesoIngreso;
    lote.pesoBalanzaTotal = state.totalBalanza;
    lote.pesoTotalSalida = state.totalPesoResma;
    lote.pesoPaletaSalida = state.totalPesoPaleta;
    lote.pesoMaterialSalida = state.totalPesoMaterial;
    lote.cantResmaSalida = state.totalCantResma;
    lote.cantHojasSalida = state.totalCantHojas.toDouble();
    lote.mermaTotal = state.totalMerma;
    lote.diferenciaProduccion = state.difProduccion;
    lote.cantEstimadaResma = state.cantEstimadaResma;
    lote.diferenciaProdResma = state.difResma;

    try {
      if (!await _repo.registrarLoteProduccion(lote)) {
        return _fallo('No se pudo guardar la cabecera del lote.');
      }

      for (final fila in state.ingresos) {
        fila.idLp = idLp;
        fila.audUsuario = usuario;
        fila.codArticulo = state.codArticuloIngreso;
        fila.descripcion = articuloIngreso?.datoArt ?? fila.descripcion;
      }
      if (state.ingresos.isNotEmpty &&
          !await _repo.registrarMaterialIngreso(state.ingresos)) {
        return _fallo('No se pudo guardar el material de ingreso.');
      }

      for (final fila in state.salidas) {
        fila.idLp = idLp;
        fila.audUsuario = usuario;
        fila.codArticulo = state.codArticuloSalida;
        fila.descripcion = articuloSalida?.datoArt ?? fila.descripcion;
      }
      if (state.salidas.isNotEmpty &&
          !await _repo.registrarMaterialSalida(state.salidas)) {
        return _fallo('No se pudo guardar el material de salida.');
      }

      for (final fila in state.mermas) {
        fila.idLp = idLp;
        fila.audUsuario = usuario;
      }
      if (state.mermas.isNotEmpty &&
          !await _repo.registrarMerma(state.mermas)) {
        return _fallo('No se pudo guardar la merma.');
      }

      state = state.copyWith(guardando: false);
      return null;
    } catch (e) {
      return _fallo('No se pudo guardar el lote: $e');
    }
  }

  String _fallo(String mensaje) {
    state = state.copyWith(guardando: false, error: mensaje);
    return mensaje;
  }

  LoteProduccionEntity? _articulo(String cod) {
    for (final a in state.articulos) {
      if (a.codArticulo == cod) return a;
    }
    return null;
  }
}

final detalleLoteProvider = StateNotifierProvider.autoDispose
    .family<DetalleLoteNotifier, DetalleLoteState, DetalleLoteParams>(
      (ref, params) => DetalleLoteNotifier(
        ref,
        ref.watch(loteProduccionRepositoryProvider),
        params,
      ),
    );
