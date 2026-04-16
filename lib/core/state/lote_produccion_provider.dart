import 'dart:math';

import 'package:bosque_flutter/data/repositories/lote_produccion_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class LoteProduccionRegistroState {
  // Catálogos
  final List<MaquinaProduccionEntity> lstMaquina;
  final List<LoteProduccionEntity> lstArticulos;
  final List<EmpresaEntity> lstEmpresas;
  final List<LoteProduccionEntity> lstDocNumOrdFab;

  // Base del lote (viene de /newLoteProduccion)
  final int numLote;
  final int anio;
  final int numCorte;
  final int anioCorte;
  final int idLp; // 0 = nuevo, >0 = existente

  // Formulario cabecera
  final int? idMaSeleccionada;
  final int? codEmpresaSeleccionada;
  final LoteProduccionEntity? ordenSeleccionada;
  final DateTime fecha;
  final String hraInicioCorte;
  final String hraInicio;
  final String hraFin;
  final String obs;

  // Artículos seleccionados para las tablas
  final LoteProduccionEntity? articuloIngreso;
  final LoteProduccionEntity? articuloSalida;
  final bool isTableIngresoEnabled;
  final bool isTableSalidaEnabled;

  // Tablas de trabajo
  final List<MaterialIngresoEntity> lstIngreso;
  final List<MaterialSalidaEntity> lstSalida;
  final List<MermaEntity> lstMerma;

  /// Hojas por resma del artículo de salida seleccionado (ej: 500).
  /// Se usa para convertir totalCantidadHojas a unidades de resma, igual
  /// que Angular: totalCantidadHojas = sum(cantidadHojas) / cantHjs
  final int cantHjs;

  // UI flags
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  /// Código del artículo de salida no encontrado en el catálogo.
  /// Vacío ('') indica que la orden no tiene artículo de salida definido.
  /// null = sin error.
  final String? salidaArticuloErrorCodigo;

  const LoteProduccionRegistroState({
    this.lstMaquina = const [],
    this.lstArticulos = const [],
    this.lstEmpresas = const [],
    this.lstDocNumOrdFab = const [],
    this.numLote = 0,
    this.anio = 0,
    this.numCorte = 0,
    this.anioCorte = 0,
    this.idLp = 0,
    this.idMaSeleccionada,
    this.codEmpresaSeleccionada,
    this.ordenSeleccionada,
    required this.fecha,
    this.hraInicioCorte = '',
    this.hraInicio = '',
    this.hraFin = '',
    this.obs = '',
    this.articuloIngreso,
    this.articuloSalida,
    this.isTableIngresoEnabled = false,
    this.isTableSalidaEnabled = false,
    this.lstIngreso = const [],
    this.lstSalida = const [],
    this.lstMerma = const [],
    this.cantHjs = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.salidaArticuloErrorCodigo,
  });

  // ── Cálculos en tiempo real ────────────────────────────────────────────────

  double get totalIngresosKilos =>
      lstIngreso.fold(0.0, (sum, e) => sum + e.pesoKilos);

  double get totalBalanza => lstIngreso.fold(0.0, (sum, e) => sum + e.balanza);

  double get totalPesoResma =>
      lstSalida.fold(0.0, (sum, e) => sum + e.pesoResma);

  double get totalPesoPaleta =>
      lstSalida.fold(0.0, (sum, e) => sum + e.pesoPaleta);

  double get totalPesoMaterial =>
      lstSalida.fold(0.0, (sum, e) => sum + (e.pesoResma - e.pesoPaleta));

  int get totalCantidadResma =>
      lstSalida.fold(0, (sum, e) => sum + e.cantidadResma);

  /// Suma de hojas por fila, dividida entre hojas/resma → total en resmas.
  /// Equivalente a Angular: sum(cantidadHojas) / cantHjsSalida
  double get totalCantidadHojas {
    final suma = lstSalida.fold(0, (sum, e) => sum + e.cantidadHojas);
    if (cantHjs <= 0) return suma.toDouble();
    return suma / cantHjs;
  }

  double get totalMerma => lstMerma.fold(0.0, (sum, e) => sum + e.peso);

  /// Equivalente a Angular: (totalBalanza - totalMerma) / 1000 * utm
  double get cantEstimadaResma {
    final utm = articuloSalida?.utm ?? 0;
    if (utm <= 0) return 0;
    return (totalBalanza - totalMerma) / 1000 * utm;
  }

  double get difProduccion =>
      totalIngresosKilos - (totalPesoMaterial + totalMerma);

  double get difProduccionResma => totalCantidadResma - cantEstimadaResma;

  // ── Validación de tablas ────────────────────────────────────────────────────

  /// Filas de ingreso incompletas (pesoKilos o balanza = 0).
  List<int> get filasIngresoIncompletas => [
    for (int i = 0; i < lstIngreso.length; i++)
      if (lstIngreso[i].pesoKilos <= 0 || lstIngreso[i].balanza <= 0) i + 1,
  ];

  /// Filas de salida incompletas (pesoResma, pesoPaleta o cantidadResma = 0).
  List<int> get filasSalidaIncompletas => [
    for (int i = 0; i < lstSalida.length; i++)
      if (lstSalida[i].pesoResma <= 0 ||
          lstSalida[i].pesoPaleta <= 0 ||
          lstSalida[i].cantidadResma <= 0)
        i + 1,
  ];

  /// Filas de merma incompletas (peso = 0 o artículo vacío).
  List<int> get filasMermaIncompletas => [
    for (int i = 0; i < lstMerma.length; i++)
      if (lstMerma[i].peso <= 0 || lstMerma[i].codArticulo.isEmpty) i + 1,
  ];

  bool get tablasCompletas =>
      filasIngresoIncompletas.isEmpty &&
      filasSalidaIncompletas.isEmpty &&
      filasMermaIncompletas.isEmpty;

  LoteProduccionRegistroState copyWith({
    List<MaquinaProduccionEntity>? lstMaquina,
    List<LoteProduccionEntity>? lstArticulos,
    List<EmpresaEntity>? lstEmpresas,
    List<LoteProduccionEntity>? lstDocNumOrdFab,
    int? numLote,
    int? anio,
    int? numCorte,
    int? anioCorte,
    int? idLp,
    int? idMaSeleccionada,
    int? codEmpresaSeleccionada,
    LoteProduccionEntity? ordenSeleccionada,
    bool clearOrdenSeleccionada = false,
    DateTime? fecha,
    String? hraInicioCorte,
    String? hraInicio,
    String? hraFin,
    String? obs,
    LoteProduccionEntity? articuloIngreso,
    bool clearArticuloIngreso = false,
    LoteProduccionEntity? articuloSalida,
    bool clearArticuloSalida = false,
    bool? isTableIngresoEnabled,
    bool? isTableSalidaEnabled,
    List<MaterialIngresoEntity>? lstIngreso,
    List<MaterialSalidaEntity>? lstSalida,
    List<MermaEntity>? lstMerma,
    int? cantHjs,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? salidaArticuloErrorCodigo,
    bool clearSalidaError = false,
  }) {
    return LoteProduccionRegistroState(
      lstMaquina: lstMaquina ?? this.lstMaquina,
      lstArticulos: lstArticulos ?? this.lstArticulos,
      lstEmpresas: lstEmpresas ?? this.lstEmpresas,
      lstDocNumOrdFab: lstDocNumOrdFab ?? this.lstDocNumOrdFab,
      numLote: numLote ?? this.numLote,
      anio: anio ?? this.anio,
      numCorte: numCorte ?? this.numCorte,
      anioCorte: anioCorte ?? this.anioCorte,
      idLp: idLp ?? this.idLp,
      idMaSeleccionada: idMaSeleccionada ?? this.idMaSeleccionada,
      codEmpresaSeleccionada:
          codEmpresaSeleccionada ?? this.codEmpresaSeleccionada,
      ordenSeleccionada:
          clearOrdenSeleccionada
              ? null
              : (ordenSeleccionada ?? this.ordenSeleccionada),
      fecha: fecha ?? this.fecha,
      hraInicioCorte: hraInicioCorte ?? this.hraInicioCorte,
      hraInicio: hraInicio ?? this.hraInicio,
      hraFin: hraFin ?? this.hraFin,
      obs: obs ?? this.obs,
      articuloIngreso:
          clearArticuloIngreso
              ? null
              : (articuloIngreso ?? this.articuloIngreso),
      articuloSalida:
          clearArticuloSalida ? null : (articuloSalida ?? this.articuloSalida),
      isTableIngresoEnabled:
          isTableIngresoEnabled ?? this.isTableIngresoEnabled,
      isTableSalidaEnabled: isTableSalidaEnabled ?? this.isTableSalidaEnabled,
      lstIngreso: lstIngreso ?? this.lstIngreso,
      lstSalida: lstSalida ?? this.lstSalida,
      lstMerma: lstMerma ?? this.lstMerma,
      cantHjs: cantHjs ?? this.cantHjs,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      salidaArticuloErrorCodigo:
          clearSalidaError
              ? null
              : (salidaArticuloErrorCodigo ?? this.salidaArticuloErrorCodigo),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class LoteProduccionRegistroNotifier
    extends StateNotifier<LoteProduccionRegistroState> {
  final LoteProduccionImpl _repo;
  final int _audUsuario;

  LoteProduccionRegistroNotifier(this._repo, this._audUsuario)
    : super(LoteProduccionRegistroState(fecha: DateTime.now())) {
    _init();
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Extrae el número de hojas del datoArt (ej: "75 GRS 65X90 500 HJS" → 500).
  int _extraerNumeroHojas(String datoArt) {
    final regex = RegExp(r'(\d+)\s*HJS', caseSensitive: false);
    final match = regex.firstMatch(datoArt);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  MaterialIngresoEntity _filaIngresioVacia() => MaterialIngresoEntity(
    idMi: 0,
    idLp: 0,
    codArticulo: state.articuloIngreso?.codArticulo ?? '',
    descripcion: state.articuloIngreso?.articulo ?? '',
    pesoKilos: 0,
    balanza: 0,
    numImportacion: '',
    audUsuario: _audUsuario,
  );

  MaterialSalidaEntity _filaSalidaVacia(int nroPaleta) => MaterialSalidaEntity(
    idMs: 0,
    idLp: 0,
    codArticulo: state.articuloSalida?.codArticulo ?? '',
    descripcion: state.articuloSalida?.articulo ?? '',
    nroPaleta: nroPaleta,
    pesoResma: 0,
    pesoPaleta: 0,
    pesoMaterial: 0,
    cantidadResma: 0,
    cantidadHojas: 0,
    audUsuario: _audUsuario,
  );

  MermaEntity _filaMermaVacia() => MermaEntity(
    idMe: 0,
    idLp: 0,
    codArticulo: '',
    descripcion: '',
    peso: 0,
    audUsuario: _audUsuario,
  );

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.obtenerArticulos(),
        _repo.obtenerMaquinas(),
        _repo.obtenerEmpresas(),
      ]);

      final articulos = results[0] as List<LoteProduccionEntity>;
      final maquinas = results[1] as List<MaquinaProduccionEntity>;
      final empresas = results[2] as List<EmpresaEntity>;

      final ingreso = List.generate(3, (_) => _filaIngresioVacia());
      final salida = List.generate(3, (i) => _filaSalidaVacia(i + 1));
      final merma = List.generate(4, (_) => _filaMermaVacia());

      state = state.copyWith(
        lstArticulos: articulos,
        lstMaquina: maquinas,
        lstEmpresas: empresas,
        lstIngreso: ingreso,
        lstSalida: salida,
        lstMerma: merma,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los catálogos',
      );
    }
  }

  // ── Selección de máquina ───────────────────────────────────────────────────

  Future<void> onMaquinaChange(int idMa) async {
    state = state.copyWith(idMaSeleccionada: idMa, clearError: true);
    final loteBase = await _repo.obtenerNuevoLote(idMa);
    if (loteBase != null) {
      state = state.copyWith(
        numLote: loteBase.numLote,
        anio: loteBase.anio,
        numCorte: loteBase.numCorte,
        anioCorte: loteBase.anioCorte,
        idLp: loteBase.idLp,
      );
    }
  }

  // ── Selección de empresa ───────────────────────────────────────────────────

  Future<void> onEmpresaChange(int codEmpresa) async {
    state = state.copyWith(
      codEmpresaSeleccionada: codEmpresa,
      clearOrdenSeleccionada: true,
      lstDocNumOrdFab: [],
      clearError: true,
    );
    final ordenes = await _repo.obtenerDocNumXEmpresa(codEmpresa);
    state = state.copyWith(lstDocNumOrdFab: ordenes);
  }

  // ── Selección de orden de fabricación ─────────────────────────────────────

  void onDocNumChange(LoteProduccionEntity orden) {
    // Primero limpiar artículos y deshabilitar tablas para que no queden datos
    // de una orden anterior mientras se resuelve la nueva selección.
    final ingresioVacio =
        state.lstIngreso
            .map(
              (e) => MaterialIngresoEntity(
                idMi: e.idMi,
                idLp: e.idLp,
                codArticulo: '',
                descripcion: '',
                pesoKilos: e.pesoKilos,
                balanza: e.balanza,
                numImportacion: e.numImportacion,
                audUsuario: e.audUsuario,
              ),
            )
            .toList();
    final salidaVacia =
        state.lstSalida
            .map(
              (e) => MaterialSalidaEntity(
                idMs: e.idMs,
                idLp: e.idLp,
                codArticulo: '',
                descripcion: '',
                nroPaleta: e.nroPaleta,
                pesoResma: e.pesoResma,
                pesoPaleta: e.pesoPaleta,
                pesoMaterial: e.pesoMaterial,
                cantidadResma: e.cantidadResma,
                cantidadHojas: e.cantidadHojas,
                audUsuario: e.audUsuario,
              ),
            )
            .toList();

    state = state.copyWith(
      ordenSeleccionada: orden,
      clearError: true,
      clearSalidaError: true,
      clearArticuloIngreso: true,
      clearArticuloSalida: true,
      isTableIngresoEnabled: false,
      isTableSalidaEnabled: false,
      lstIngreso: ingresioVacio,
      lstSalida: salidaVacia,
    );

    if (orden.codArtEntrada.isNotEmpty) {
      _preSeleccionarArticuloIngreso(orden.codArtEntrada);
    }
    if (orden.codArtSalida.isNotEmpty) {
      _preSeleccionarArticuloSalida(orden.codArtSalida);
    } else {
      // La orden no tiene artículo de salida definido
      state = state.copyWith(salidaArticuloErrorCodigo: '');
    }
  }

  void _preSeleccionarArticuloIngreso(String codArt) {
    final art =
        state.lstArticulos.where((a) => a.codArticulo == codArt).firstOrNull;
    if (art != null) seleccionarArticuloIngreso(art);
  }

  void _preSeleccionarArticuloSalida(String codArt) {
    final art =
        state.lstArticulos.where((a) => a.codArticulo == codArt).firstOrNull;
    if (art != null) {
      seleccionarArticuloSalida(art);
    } else {
      // Artículo de salida no encontrado en el catálogo
      state = state.copyWith(salidaArticuloErrorCodigo: codArt);
    }
  }

  /// Limpia la bandera de error de artículo de salida no encontrado.
  void clearSalidaError() => state = state.copyWith(clearSalidaError: true);

  // ── Selección manual de artículos ─────────────────────────────────────────

  void seleccionarArticuloIngreso(LoteProduccionEntity art) {
    state = state.copyWith(
      articuloIngreso: art,
      isTableIngresoEnabled: art.codArticulo.length > 2,
      // Actualizar codArticulo en todas las filas de ingreso
      lstIngreso:
          state.lstIngreso
              .map(
                (e) => MaterialIngresoEntity(
                  idMi: e.idMi,
                  idLp: e.idLp,
                  codArticulo: art.codArticulo,
                  descripcion: art.articulo,
                  pesoKilos: e.pesoKilos,
                  balanza: e.balanza,
                  numImportacion: e.numImportacion,
                  audUsuario: e.audUsuario,
                ),
              )
              .toList(),
    );
  }

  void seleccionarArticuloSalida(LoteProduccionEntity art) {
    final hojasPorResma = _extraerNumeroHojas(art.datoArt);
    final lastIndex = state.lstSalida.length - 1;
    state = state.copyWith(
      articuloSalida: art,
      isTableSalidaEnabled: art.codArticulo.length > 2,
      cantHjs: hojasPorResma,
      lstSalida:
          state.lstSalida
              .asMap()
              .entries
              .map(
                (entry) => MaterialSalidaEntity(
                  idMs: entry.value.idMs,
                  idLp: entry.value.idLp,
                  codArticulo: art.codArticulo,
                  descripcion: art.articulo,
                  nroPaleta: entry.value.nroPaleta,
                  pesoResma: entry.value.pesoResma,
                  pesoPaleta: entry.value.pesoPaleta,
                  pesoMaterial: entry.value.pesoMaterial,
                  cantidadResma: entry.value.cantidadResma,
                  // Auto-fill last row's cantidadHojas with hojasPorResma
                  cantidadHojas:
                      (entry.key == lastIndex && hojasPorResma > 0)
                          ? hojasPorResma
                          : entry.value.cantidadHojas,
                  audUsuario: entry.value.audUsuario,
                ),
              )
              .toList(),
    );
  }

  // ── Campos del formulario cabecera ─────────────────────────────────────────

  void setFecha(DateTime fecha) => state = state.copyWith(fecha: fecha);
  void setHraInicioCorte(String v) => state = state.copyWith(hraInicioCorte: v);
  void setHraInicio(String v) => state = state.copyWith(hraInicio: v);
  void setHraFin(String v) => state = state.copyWith(hraFin: v);
  void setObs(String v) => state = state.copyWith(obs: v);

  /// Permite al usuario cambiar las hojas por resma sin cambiar el artículo.
  /// También actualiza automáticamente el cantidadHojas de la última fila.
  void setCantHjs(int v) {
    if (v <= 0) return;
    List<MaterialSalidaEntity> newLst = state.lstSalida;
    if (newLst.isNotEmpty) {
      newLst = [...newLst];
      final i = newLst.length - 1;
      final last = newLst[i];
      newLst[i] = MaterialSalidaEntity(
        idMs: last.idMs,
        idLp: last.idLp,
        codArticulo: last.codArticulo,
        descripcion: last.descripcion,
        nroPaleta: last.nroPaleta,
        pesoResma: last.pesoResma,
        pesoPaleta: last.pesoPaleta,
        pesoMaterial: last.pesoMaterial,
        cantidadResma: last.cantidadResma,
        cantidadHojas: v,
        audUsuario: last.audUsuario,
      );
    }
    state = state.copyWith(cantHjs: v, lstSalida: newLst);
  }

  // ── Tabla de Ingreso ───────────────────────────────────────────────────────

  void agregarFilaIngreso() {
    state = state.copyWith(
      lstIngreso: [...state.lstIngreso, _filaIngresioVacia()],
    );
  }

  void eliminarFilaIngreso(int index) {
    final lista = [...state.lstIngreso]..removeAt(index);
    state = state.copyWith(lstIngreso: lista);
  }

  void updateIngreso(int index, MaterialIngresoEntity updated) {
    final lista = [...state.lstIngreso];
    lista[index] = updated;
    state = state.copyWith(lstIngreso: lista);
  }

  // ── Tabla de Salida ────────────────────────────────────────────────────────

  void agregarFilaSalida() {
    final nroPaleta = state.lstSalida.length + 1;
    // New last row pre-filled with current cantHjs value
    final nuevaFila = MaterialSalidaEntity(
      idMs: 0,
      idLp: 0,
      codArticulo: state.articuloSalida?.codArticulo ?? '',
      descripcion: state.articuloSalida?.articulo ?? '',
      nroPaleta: nroPaleta,
      pesoResma: 0,
      pesoPaleta: 0,
      pesoMaterial: 0,
      cantidadResma: 0,
      cantidadHojas: state.cantHjs,
      audUsuario: _audUsuario,
    );
    state = state.copyWith(lstSalida: [...state.lstSalida, nuevaFila]);
  }

  void eliminarFilaSalida(int index) {
    final lista = [...state.lstSalida]..removeAt(index);
    // Renumerar paletas
    final renumerada =
        lista
            .asMap()
            .entries
            .map(
              (e) => MaterialSalidaEntity(
                idMs: e.value.idMs,
                idLp: e.value.idLp,
                codArticulo: e.value.codArticulo,
                descripcion: e.value.descripcion,
                nroPaleta: e.key + 1,
                pesoResma: e.value.pesoResma,
                pesoPaleta: e.value.pesoPaleta,
                pesoMaterial: e.value.pesoMaterial,
                cantidadResma: e.value.cantidadResma,
                cantidadHojas: e.value.cantidadHojas,
                audUsuario: e.value.audUsuario,
              ),
            )
            .toList();
    state = state.copyWith(lstSalida: renumerada);
  }

  void updateSalida(int index, MaterialSalidaEntity updated) {
    final lista = [...state.lstSalida];
    // Recalcular pesoMaterial = pesoResma - pesoPaleta
    final conCalculo = MaterialSalidaEntity(
      idMs: updated.idMs,
      idLp: updated.idLp,
      codArticulo: updated.codArticulo,
      descripcion: updated.descripcion,
      nroPaleta: updated.nroPaleta,
      pesoResma: updated.pesoResma,
      pesoPaleta: updated.pesoPaleta,
      pesoMaterial: max(0, updated.pesoResma - updated.pesoPaleta),
      cantidadResma: updated.cantidadResma,
      cantidadHojas: updated.cantidadHojas,
      audUsuario: updated.audUsuario,
    );
    lista[index] = conCalculo;
    state = state.copyWith(lstSalida: lista);
  }

  // Actualiza cantidadResma; cantidadHojas la ingresa el usuario manualmente
  void updateSalidaResma(int index, int cantResma) {
    final fila = state.lstSalida[index];
    updateSalida(
      index,
      MaterialSalidaEntity(
        idMs: fila.idMs,
        idLp: fila.idLp,
        codArticulo: fila.codArticulo,
        descripcion: fila.descripcion,
        nroPaleta: fila.nroPaleta,
        pesoResma: fila.pesoResma,
        pesoPaleta: fila.pesoPaleta,
        pesoMaterial: fila.pesoMaterial,
        cantidadResma: cantResma,
        cantidadHojas: fila.cantidadHojas,
        audUsuario: fila.audUsuario,
      ),
    );
  }

  // ── Tabla de Merma ─────────────────────────────────────────────────────────

  void agregarFilaMerma() {
    state = state.copyWith(lstMerma: [...state.lstMerma, _filaMermaVacia()]);
  }

  void eliminarFilaMerma(int index) {
    final lista = [...state.lstMerma]..removeAt(index);
    state = state.copyWith(lstMerma: lista);
  }

  void updateMerma(int index, MermaEntity updated) {
    final lista = [...state.lstMerma];
    lista[index] = updated;
    state = state.copyWith(lstMerma: lista);
  }

  void seleccionarArticuloMerma(int index, LoteProduccionEntity art) {
    final fila = state.lstMerma[index];
    updateMerma(
      index,
      MermaEntity(
        idMe: fila.idMe,
        idLp: fila.idLp,
        codArticulo: art.codArticulo,
        descripcion: art.articulo,
        peso: fila.peso,
        audUsuario: fila.audUsuario,
      ),
    );
  }

  // ── Guardado secuencial ────────────────────────────────────────────────────

  Future<bool> guardarTodo() async {
    if (state.idMaSeleccionada == null) {
      state = state.copyWith(errorMessage: 'Seleccione una máquina');
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    // Construir entidad cabecera
    final orden = state.ordenSeleccionada;
    final lote = LoteProduccionEntity(
      idMa: state.idMaSeleccionada!,
      idLp: state.idLp,
      numLote: state.numLote,
      anio: state.anio,
      fecha: state.fecha,
      hraInicioCorte: state.hraInicioCorte,
      hraInicio: state.hraInicio,
      hraFin: state.hraFin,
      cantBobinasIngresoTotal: state.lstIngreso.length,
      pesoKilosTotalIngreso: state.totalIngresosKilos,
      pesoTotalSalida: state.totalPesoResma,
      pesoPaletaSalida: state.totalPesoPaleta,
      pesoMaterialSalida: state.totalPesoMaterial,
      cantResmaSalida: state.totalCantidadResma,
      cantHojasSalida:
          state.lstSalida.isNotEmpty
              ? state.lstSalida.last.cantidadHojas.toDouble()
              : 0,
      mermaTotal: state.totalMerma,
      diferenciaProduccion: state.difProduccion,
      diferenciaProdResma: state.difProduccionResma,
      cantEstimadaResma: state.cantEstimadaResma,
      pesoBalanzaTotal: state.totalBalanza,
      estado: 1,
      obs: state.obs,
      numCorte: state.numCorte,
      anioCorte: state.anioCorte,
      docNumOrdFab: orden?.docNumOrdFab ?? 0,
      codEmpresa: state.codEmpresaSeleccionada ?? 0,
      audUsuario: _audUsuario,
      codArticulo: state.articuloSalida?.codArticulo ?? '',
      datoArt: state.articuloSalida?.datoArt ?? '',
      articulo: state.articuloSalida?.articulo ?? '',
      utm: state.articuloSalida?.utm ?? 0,
      codArtEntrada: orden?.codArtEntrada ?? '',
      codArtSalida: orden?.codArtSalida ?? '',
      db: orden?.db ?? '',
    );

    // 1) Cabecera
    final okLote = await _repo.registrarLoteProduccion(lote);
    if (!okLote) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al registrar la cabecera del lote',
      );
      return false;
    }

    // Asignar idLp a las filas (si es nuevo se espera que el backend lo devuelva
    // en el next call; como el backend no lo retorna aquí, usamos el idLp del state).
    final ingresoConLp =
        state.lstIngreso
            .where((e) => e.pesoKilos > 0)
            .map(
              (e) => MaterialIngresoEntity(
                idMi: e.idMi,
                idLp: state.idLp,
                codArticulo: e.codArticulo,
                descripcion: e.descripcion,
                pesoKilos: e.pesoKilos,
                balanza: e.balanza,
                numImportacion: e.numImportacion,
                audUsuario: e.audUsuario,
              ),
            )
            .toList();

    final salidaConLp =
        state.lstSalida
            .where((e) => e.pesoResma > 0)
            .map(
              (e) => MaterialSalidaEntity(
                idMs: e.idMs,
                idLp: state.idLp,
                codArticulo: e.codArticulo,
                descripcion: e.descripcion,
                nroPaleta: e.nroPaleta,
                pesoResma: e.pesoResma,
                pesoPaleta: e.pesoPaleta,
                pesoMaterial: e.pesoMaterial,
                cantidadResma: e.cantidadResma,
                cantidadHojas: e.cantidadHojas,
                audUsuario: e.audUsuario,
              ),
            )
            .toList();

    final mermaConLp =
        state.lstMerma
            .where((e) => e.peso > 0)
            .map(
              (e) => MermaEntity(
                idMe: e.idMe,
                idLp: state.idLp,
                codArticulo: e.codArticulo,
                descripcion: e.descripcion,
                peso: e.peso,
                audUsuario: e.audUsuario,
              ),
            )
            .toList();

    // 2) Ingreso
    if (ingresoConLp.isNotEmpty) {
      final okIng = await _repo.registrarMaterialIngreso(ingresoConLp);
      if (!okIng) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Error al registrar el material de ingreso',
        );
        return false;
      }
    }

    // 3) Salida
    if (salidaConLp.isNotEmpty) {
      final okSal = await _repo.registrarMaterialSalida(salidaConLp);
      if (!okSal) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Error al registrar el material de salida',
        );
        return false;
      }
    }

    // 4) Merma
    if (mermaConLp.isNotEmpty) {
      final okMer = await _repo.registrarMerma(mermaConLp);
      if (!okMer) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Error al registrar la merma',
        );
        return false;
      }
    }

    state = state.copyWith(
      isSaving: false,
      successMessage: 'Lote de producción registrado correctamente',
    );
    return true;
  }

  void resetState() {
    state = LoteProduccionRegistroState(fecha: DateTime.now());
    _init();
  }

  void clearMessages() =>
      state = state.copyWith(clearError: true, clearSuccess: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final loteProduccionRepoProvider = Provider<LoteProduccionImpl>((ref) {
  return LoteProduccionImpl();
});

// Se necesita audUsuario → inyectado desde la pantalla con .family o .overrideWith
final loteProduccionRegistroProvider = StateNotifierProvider.family<
  LoteProduccionRegistroNotifier,
  LoteProduccionRegistroState,
  int
>((ref, audUsuario) {
  final repo = ref.watch(loteProduccionRepoProvider);
  return LoteProduccionRegistroNotifier(repo, audUsuario);
});
