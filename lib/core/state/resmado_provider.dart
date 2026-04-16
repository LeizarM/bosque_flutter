import 'package:bosque_flutter/data/repositories/resmado_impl.dart';
import 'package:bosque_flutter/domain/entities/detalle_resmando_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ResmadoRegistroState {
  // Catálogos
  final List<EmpresaEntity> lstEmpresas;
  final List<LoteProduccionEntity> lstDocNums;
  final List<GrupoProduccionEntity> lstGrupos;
  final List<LoteProduccionEntity> lstArticulos;

  // Selección cabecera
  final int? codEmpresaSeleccionada;
  final LoteProduccionEntity? ordenSeleccionada;
  final int? idGrupoSeleccionado;
  final DateTime fecha;
  final String hraInicio;
  final String hraFin;

  // Detalle
  final List<DetalleResmadoEntity> detalles;

  // UI flags
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ResmadoRegistroState({
    this.lstEmpresas = const [],
    this.lstDocNums = const [],
    this.lstGrupos = const [],
    this.lstArticulos = const [],
    this.codEmpresaSeleccionada,
    this.ordenSeleccionada,
    this.idGrupoSeleccionado,
    required this.fecha,
    this.hraInicio = '',
    this.hraFin = '',
    this.detalles = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  // ── Cálculos ─────────────────────────────────────────────────────────────

  int get total => detalles.fold(0, (sum, d) => sum + d.cantResma);

  // ── copyWith ──────────────────────────────────────────────────────────────

  ResmadoRegistroState copyWith({
    List<EmpresaEntity>? lstEmpresas,
    List<LoteProduccionEntity>? lstDocNums,
    List<GrupoProduccionEntity>? lstGrupos,
    List<LoteProduccionEntity>? lstArticulos,
    int? codEmpresaSeleccionada,
    bool clearEmpresa = false,
    LoteProduccionEntity? ordenSeleccionada,
    bool clearOrden = false,
    int? idGrupoSeleccionado,
    bool clearGrupo = false,
    DateTime? fecha,
    String? hraInicio,
    String? hraFin,
    List<DetalleResmadoEntity>? detalles,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ResmadoRegistroState(
      lstEmpresas: lstEmpresas ?? this.lstEmpresas,
      lstDocNums: lstDocNums ?? this.lstDocNums,
      lstGrupos: lstGrupos ?? this.lstGrupos,
      lstArticulos: lstArticulos ?? this.lstArticulos,
      codEmpresaSeleccionada:
          clearEmpresa
              ? null
              : codEmpresaSeleccionada ?? this.codEmpresaSeleccionada,
      ordenSeleccionada:
          clearOrden ? null : ordenSeleccionada ?? this.ordenSeleccionada,
      idGrupoSeleccionado:
          clearGrupo ? null : idGrupoSeleccionado ?? this.idGrupoSeleccionado,
      fecha: fecha ?? this.fecha,
      hraInicio: hraInicio ?? this.hraInicio,
      hraFin: hraFin ?? this.hraFin,
      detalles: detalles ?? this.detalles,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ResmadoRegistroNotifier extends StateNotifier<ResmadoRegistroState> {
  final ResmadoImpl _repo = ResmadoImpl();
  final int _audUsuario;
  final int _codEmpleado;

  ResmadoRegistroNotifier(this._audUsuario, this._codEmpleado)
    : super(ResmadoRegistroState(fecha: DateTime.now())) {
    _init();
  }

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      _repo.obtenerEmpresas(),
      _repo.obtenerGrupoProduccion(),
      _repo.obtenerArticulos(),
    ]);

    final empresas = results[0] as List<EmpresaEntity>;
    final grupos = results[1] as List<GrupoProduccionEntity>;
    final articulos = results[2] as List<LoteProduccionEntity>;

    // Grupo por defecto = 1 (igual que Angular)
    final grupoDefault = grupos.isNotEmpty ? grupos.first.idGrupo : null;

    state = state.copyWith(
      lstEmpresas: empresas,
      lstGrupos: grupos,
      lstArticulos: articulos,
      idGrupoSeleccionado: grupoDefault,
      isLoading: false,
    );
  }

  // ── Cabecera ──────────────────────────────────────────────────────────────

  void setFecha(DateTime fecha) => state = state.copyWith(fecha: fecha);

  void setHraInicio(String v) => state = state.copyWith(hraInicio: v);

  void setHraFin(String v) => state = state.copyWith(hraFin: v);

  void setGrupo(int? idGrupo) =>
      state = state.copyWith(idGrupoSeleccionado: idGrupo);

  Future<void> setEmpresa(int? codEmpresa) async {
    if (codEmpresa == null) {
      state = state.copyWith(
        clearEmpresa: true,
        clearOrden: true,
        lstDocNums: [],
      );
      return;
    }
    state = state.copyWith(
      codEmpresaSeleccionada: codEmpresa,
      clearOrden: true,
      lstDocNums: [],
      isLoading: true,
    );
    final docNums = await _repo.obtenerDocNumXEmpresa(codEmpresa);
    state = state.copyWith(lstDocNums: docNums, isLoading: false);
  }

  void setOrden(LoteProduccionEntity? orden) =>
      state = state.copyWith(
        ordenSeleccionada: orden,
        clearOrden: orden == null,
      );

  // ── Detalle ───────────────────────────────────────────────────────────────

  /// Agrega artículos desde el diálogo de selección.
  /// Retorna la lista de códigos duplicados (para mostrar al usuario).
  List<String> agregarArticulos(List<LoteProduccionEntity> seleccionados) {
    final duplicados = <String>[];
    final nuevos = List<DetalleResmadoEntity>.from(state.detalles);
    for (final art in seleccionados) {
      final existe = nuevos.any((d) => d.codArticulo == art.codArticulo);
      if (existe) {
        duplicados.add(art.codArticulo);
        continue;
      }
      nuevos.add(
        DetalleResmadoEntity(
          idRetRes: 0,
          idRes: 0,
          codArticulo: art.codArticulo,
          descripcion: art.datoArt.isNotEmpty ? art.datoArt : art.articulo,
          cantResma: 1,
          audUsuario: _audUsuario,
        ),
      );
    }
    state = state.copyWith(detalles: nuevos);
    return duplicados;
  }

  void actualizarCantidad(int index, int cantidad) {
    final nuevos = List<DetalleResmadoEntity>.from(state.detalles);
    final det = nuevos[index];
    nuevos[index] = DetalleResmadoEntity(
      idRetRes: det.idRetRes,
      idRes: det.idRes,
      codArticulo: det.codArticulo,
      descripcion: det.descripcion,
      cantResma: cantidad < 1 ? 1 : cantidad,
      audUsuario: det.audUsuario,
    );
    state = state.copyWith(detalles: nuevos);
  }

  void eliminarDetalle(int index) {
    final nuevos = List<DetalleResmadoEntity>.from(state.detalles)
      ..removeAt(index);
    state = state.copyWith(detalles: nuevos);
  }

  // ── Registro ──────────────────────────────────────────────────────────────

  Future<bool> registrar() async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    final st = state;
    final resmado = ResmadoEntity(
      idRes: 0,
      idGrupo: st.idGrupoSeleccionado!,
      codEmpleado: _codEmpleado,
      fecha: st.fecha,
      total: st.total.toDouble(),
      hraInicio: st.hraInicio,
      hraFin: st.hraFin,
      codEmpresa: st.codEmpresaSeleccionada!,
      docNumOrdFab: st.ordenSeleccionada!.docNumOrdFab,
      audUsuario: _audUsuario,
    );

    final okCab = await _repo.registrarResmado(resmado);
    if (!okCab) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al registrar el resmado. Intente nuevamente.',
      );
      return false;
    }

    // Detalle con audUsuario actualizado
    final detalles =
        st.detalles.map((d) {
          return DetalleResmadoEntity(
            idRetRes: 0,
            idRes: 0,
            codArticulo: d.codArticulo,
            descripcion: d.descripcion,
            cantResma: d.cantResma,
            audUsuario: _audUsuario,
          );
        }).toList();

    final okDet = await _repo.registrarDetalleResmado(detalles);
    if (!okDet) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Cabecera registrada, pero error en el detalle.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: false,
      successMessage: 'Resmado registrado correctamente.',
    );
    return true;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetState() {
    final grupos = state.lstGrupos;
    final empresas = state.lstEmpresas;
    final articulos = state.lstArticulos;
    state = ResmadoRegistroState(
      fecha: DateTime.now(),
      lstGrupos: grupos,
      lstEmpresas: empresas,
      lstArticulos: articulos,
      idGrupoSeleccionado: grupos.isNotEmpty ? grupos.first.idGrupo : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider (family: recibe [audUsuario, codEmpleado])
// ─────────────────────────────────────────────────────────────────────────────

typedef ResmadoParams = ({int audUsuario, int codEmpleado});

final resmadoRegistroProvider = StateNotifierProvider.family<
  ResmadoRegistroNotifier,
  ResmadoRegistroState,
  ResmadoParams
>(
  (ref, params) =>
      ResmadoRegistroNotifier(params.audUsuario, params.codEmpleado),
);
