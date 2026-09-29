import 'dart:typed_data';

import 'package:bosque_flutter/data/repositories/bitacora_tareas_impl.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/repositories/bitacora_tareas_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El mismo tope que el backend
/// (`TareasRutinariasController.MAX_FILAS_PDF_BITACORA`). Se revisa antes de
/// pedirlo para no esperar una respuesta que va a ser un rechazo.
const maxFilasPdfBitacora = 5000;

/// Público para que los tests lo reemplacen y la pantalla use el buscador.
final bitacoraTareasRepoProvider = Provider<BitacoraTareasRepository>(
  (ref) => BitacoraTareasImpl(),
);

// Marca de "no cambiar" en los copyWith, para poder distinguir "no tocar este
// filtro" de "quitarlo" (pasarle null).
const _igual = Object();

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

String _texto(Object e) =>
    e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

// CUMPLIMIENTO

class OpcionFiltro {
  final int id;
  final String etiqueta;

  const OpcionFiltro(this.id, this.etiqueta);
}

List<OpcionFiltro> _opciones(
  Iterable<BitacoraCumplimientoEntity> filas,
  int? Function(BitacoraCumplimientoEntity) id,
  String? Function(BitacoraCumplimientoEntity) etiqueta,
) {
  final vistos = <int, String>{};
  for (final f in filas) {
    final k = id(f);
    if (k == null || vistos.containsKey(k)) continue;
    final e = (etiqueta(f) ?? '').trim();
    vistos[k] = e.isEmpty ? '#$k' : e;
  }
  return [for (final e in vistos.entries) OpcionFiltro(e.key, e.value)]
    ..sort((a, b) => a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase()));
}

class ResumenCumplimiento {
  final int realizadas;
  final int noRealizadas;
  final int noAplica;
  final int enPlazo;

  const ResumenCumplimiento({
    this.realizadas = 0,
    this.noRealizadas = 0,
    this.noAplica = 0,
    this.enPlazo = 0,
  });

  factory ResumenCumplimiento.de(Iterable<BitacoraCumplimientoEntity> filas) {
    var r = 0, n = 0, a = 0, p = 0;
    for (final f in filas) {
      switch (f.cumplimiento) {
        case Cumplimiento.realizada:
          r++;
        case Cumplimiento.noRealizada:
          n++;
        case Cumplimiento.noAplica:
          a++;
        case Cumplimiento.enPlazo:
        case null:
          p++;
      }
    }
    return ResumenCumplimiento(
      realizadas: r,
      noRealizadas: n,
      noAplica: a,
      enPlazo: p,
    );
  }

  int get total => realizadas + noRealizadas + noAplica + enPlazo;

  int cantidad(Cumplimiento c) => switch (c) {
    Cumplimiento.realizada => realizadas,
    Cumplimiento.noRealizada => noRealizadas,
    Cumplimiento.noAplica => noAplica,
    Cumplimiento.enPlazo => enPlazo,
  };

  /// Realizadas sobre realizadas + no realizadas: "No aplica" y "En plazo" no
  /// son algo que se haya dejado de hacer. Es la misma cuenta que imprime el
  /// PDF. Nulo cuando no hay nada que medir.
  double? get porcentaje {
    final base = realizadas + noRealizadas;
    return base == 0 ? null : realizadas / base;
  }
}

class BitacoraCumplimientoState {
  final DateTime desde;
  final DateTime hasta;

  /// Todo lo del rango. Los filtros se aplican encima, sin volver a consultar.
  final List<BitacoraCumplimientoEntity> filas;
  final bool cargando;
  final bool cargado;
  final bool descargandoPdf;
  final String? error;

  final Cumplimiento? estado;
  final int? codSucursal;
  final int? codCargo;
  final int? codEmpleado;
  final int? idTarRuti;

  BitacoraCumplimientoState({
    required this.desde,
    required this.hasta,
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.descargandoPdf = false,
    this.error,
    this.estado,
    this.codSucursal,
    this.codCargo,
    this.codEmpleado,
    this.idTarRuti,
  });

  /// La última semana, hoy incluido.
  factory BitacoraCumplimientoState.inicial(DateTime hoy) {
    final h = _soloDia(hoy);
    return BitacoraCumplimientoState(
      desde: DateTime(h.year, h.month, h.day - 6),
      hasta: h,
      cargando: true,
    );
  }

  bool _pasa(BitacoraCumplimientoEntity f) =>
      (codSucursal == null || f.codSucursal == codSucursal) &&
      (codCargo == null || f.codCargo == codCargo) &&
      (codEmpleado == null || f.codEmpleado == codEmpleado) &&
      (idTarRuti == null || f.idTarRuti == idTarRuti);

  /// Lo que pasa los filtros de sucursal, cargo, persona y tarea, SIN mirar el
  /// estado. Los totales se cuentan sobre esto: si se contaran sobre lo
  /// visible, tocar "No realizadas" dejaría todos los demás contadores en
  /// cero y ya no se podría comparar.
  late final List<BitacoraCumplimientoEntity> enAlcance = filas
      .where(_pasa)
      .toList(growable: false);

  late final List<BitacoraCumplimientoEntity> visibles =
      estado == null
          ? enAlcance
          : enAlcance
              .where((f) => f.cumplimiento == estado)
              .toList(growable: false);

  late final ResumenCumplimiento resumen = ResumenCumplimiento.de(enAlcance);

  // Las opciones salen de TODO el rango, no de lo filtrado: si salieran de lo
  // filtrado, elegir una sucursal dejaría el selector de sucursal con una sola.
  late final List<OpcionFiltro> sucursales = _opciones(
    filas,
    (f) => f.codSucursal,
    (f) => f.nombreSucursal,
  );
  late final List<OpcionFiltro> cargos = _opciones(
    filas,
    (f) => f.codCargo,
    (f) => f.descripcionCargo,
  );
  late final List<OpcionFiltro> personas = _opciones(
    filas,
    (f) => f.codEmpleado,
    (f) => f.nombreEmpleado,
  );
  late final List<OpcionFiltro> tareas = _opciones(
    filas,
    (f) => f.idTarRuti,
    (f) => f.nombreTareaRutinaria,
  );

  int get cantidadFiltros =>
      [
        estado,
        codSucursal,
        codCargo,
        codEmpleado,
        idTarRuti,
      ].where((x) => x != null).length;

  FiltroBitacora get filtro => FiltroBitacora(
    desde: desde,
    hasta: hasta,
    codSucursal: codSucursal,
    codCargo: codCargo,
    codEmpleado: codEmpleado,
    idTarRuti: idTarRuti,
    cumplimiento: estado,
  );

  BitacoraCumplimientoState copyWith({
    DateTime? desde,
    DateTime? hasta,
    List<BitacoraCumplimientoEntity>? filas,
    bool? cargando,
    bool? cargado,
    bool? descargandoPdf,
    String? error,
    Object? estado = _igual,
    Object? codSucursal = _igual,
    Object? codCargo = _igual,
    Object? codEmpleado = _igual,
    Object? idTarRuti = _igual,
  }) {
    return BitacoraCumplimientoState(
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      filas: filas ?? this.filas,
      cargando: cargando ?? this.cargando,
      cargado: cargado ?? this.cargado,
      descargandoPdf: descargandoPdf ?? this.descargandoPdf,
      // De un solo uso: si se arrastrara, reaparecería en cada cambio.
      error: error,
      estado:
          identical(estado, _igual) ? this.estado : estado as Cumplimiento?,
      codSucursal:
          identical(codSucursal, _igual)
              ? this.codSucursal
              : codSucursal as int?,
      codCargo: identical(codCargo, _igual) ? this.codCargo : codCargo as int?,
      codEmpleado:
          identical(codEmpleado, _igual)
              ? this.codEmpleado
              : codEmpleado as int?,
      idTarRuti:
          identical(idTarRuti, _igual) ? this.idTarRuti : idTarRuti as int?,
    );
  }
}

class BitacoraCumplimientoNotifier
    extends StateNotifier<BitacoraCumplimientoState> {
  final BitacoraTareasRepository _repo;

  BitacoraCumplimientoNotifier(this._repo, {DateTime? hoy})
    : super(BitacoraCumplimientoState.inicial(hoy ?? DateTime.now())) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    final desde = state.desde;
    final hasta = state.hasta;
    state = state.copyWith(cargando: true);
    try {
      final filas = await _repo.cumplimiento(desde: desde, hasta: hasta);
      if (!mounted) return;
      // Si mientras tanto se eligió otro rango, esta respuesta ya no es la que
      // se está mirando.
      if (state.desde != desde || state.hasta != hasta) return;
      state = state.copyWith(filas: filas, cargando: false, cargado: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        error: 'No se pudo leer la bitácora. ${_texto(e)}',
      );
    }
  }

  Future<void> cambiarRango(DateTime desde, DateTime hasta) async {
    final d = _soloDia(desde);
    final h = _soloDia(hasta);
    if (h.difference(d).inDays > 366) {
      state = state.copyWith(error: 'El rango no puede pasar de un año.');
      return;
    }
    // Sucursal, cargo, persona y tarea se sueltan: sus opciones salen de las
    // filas del rango, y en el rango nuevo pueden no existir. El estado se
    // conserva porque existe siempre.
    state = state.copyWith(
      desde: d,
      hasta: h,
      filas: const [],
      cargado: false,
      codSucursal: null,
      codCargo: null,
      codEmpleado: null,
      idTarRuti: null,
    );
    await cargar();
  }

  void filtrarEstado(Cumplimiento? c) => state = state.copyWith(estado: c);
  void filtrarSucursal(int? v) => state = state.copyWith(codSucursal: v);
  void filtrarCargo(int? v) => state = state.copyWith(codCargo: v);
  void filtrarPersona(int? v) => state = state.copyWith(codEmpleado: v);
  void filtrarTarea(int? v) => state = state.copyWith(idTarRuti: v);

  void limpiarFiltros() =>
      state = state.copyWith(
        estado: null,
        codSucursal: null,
        codCargo: null,
        codEmpleado: null,
        idTarRuti: null,
      );

  /// El PDF con los mismos filtros que la pantalla. Nulo si falló; el motivo
  /// queda en `error`.
  Future<Uint8List?> pdf() async {
    if (state.descargandoPdf) return null;
    state = state.copyWith(descargandoPdf: true);
    try {
      final bytes = await _repo.cumplimientoPdf(state.filtro);
      if (mounted) state = state.copyWith(descargandoPdf: false);
      return bytes;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(descargandoPdf: false, error: _texto(e));
      }
      return null;
    }
  }
}

final bitacoraCumplimientoProvider = StateNotifierProvider.autoDispose<
  BitacoraCumplimientoNotifier,
  BitacoraCumplimientoState
>((ref) => BitacoraCumplimientoNotifier(ref.watch(bitacoraTareasRepoProvider)));

// GENERACIÓN: CORRIDAS

class CorridaGeneracion {
  final DateTime corrida;

  /// Sin "Generadas", en el orden en que el generador evalúa.
  final List<ResumenGeneracionEntity> motivos;
  final int generadas;

  const CorridaGeneracion({
    required this.corrida,
    required this.motivos,
    required this.generadas,
  });

  int get maximo =>
      motivos.fold<int>(0, (m, x) => x.cantidad > m ? x.cantidad : m);
}

List<CorridaGeneracion> agruparCorridas(List<ResumenGeneracionEntity> filas) {
  final porCorrida = <DateTime, List<ResumenGeneracionEntity>>{};
  for (final f in filas) {
    porCorrida.putIfAbsent(f.corrida, () => []).add(f);
  }
  return [
    for (final e in porCorrida.entries)
      CorridaGeneracion(
        corrida: e.key,
        generadas: e.value
            .where((m) => m.esGeneradas)
            .fold<int>(0, (s, m) => s + m.cantidad),
        motivos:
            e.value.where((m) => !m.esGeneradas).toList()
              ..sort((a, b) => a.orden.compareTo(b.orden)),
      ),
  ]..sort((a, b) => b.corrida.compareTo(a.corrida));
}

class BitacoraGeneracionState {
  final DateTime desde;
  final DateTime hasta;
  final List<ResumenGeneracionEntity> filas;
  final bool cargando;
  final bool cargado;
  final String? error;

  BitacoraGeneracionState({
    required this.desde,
    required this.hasta,
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.error,
  });

  factory BitacoraGeneracionState.inicial(DateTime hoy) {
    final h = _soloDia(hoy);
    return BitacoraGeneracionState(
      desde: DateTime(h.year, h.month, h.day - 6),
      hasta: h,
      cargando: true,
    );
  }

  late final List<CorridaGeneracion> corridas = agruparCorridas(filas);

  BitacoraGeneracionState copyWith({
    DateTime? desde,
    DateTime? hasta,
    List<ResumenGeneracionEntity>? filas,
    bool? cargando,
    bool? cargado,
    String? error,
  }) {
    return BitacoraGeneracionState(
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      filas: filas ?? this.filas,
      cargando: cargando ?? this.cargando,
      cargado: cargado ?? this.cargado,
      error: error,
    );
  }
}

class BitacoraGeneracionNotifier extends StateNotifier<BitacoraGeneracionState> {
  final BitacoraTareasRepository _repo;

  BitacoraGeneracionNotifier(this._repo, {DateTime? hoy})
    : super(BitacoraGeneracionState.inicial(hoy ?? DateTime.now())) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    final desde = state.desde;
    final hasta = state.hasta;
    state = state.copyWith(cargando: true);
    try {
      final filas = await _repo.generacion(desde: desde, hasta: hasta);
      if (!mounted) return;
      if (state.desde != desde || state.hasta != hasta) return;
      state = state.copyWith(filas: filas, cargando: false, cargado: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        error: 'No se pudo leer las corridas del generador. ${_texto(e)}',
      );
    }
  }

  Future<void> cambiarRango(DateTime desde, DateTime hasta) async {
    state = state.copyWith(
      desde: _soloDia(desde),
      hasta: _soloDia(hasta),
      filas: const [],
      cargado: false,
    );
    await cargar();
  }
}

final bitacoraGeneracionProvider = StateNotifierProvider.autoDispose<
  BitacoraGeneracionNotifier,
  BitacoraGeneracionState
>((ref) => BitacoraGeneracionNotifier(ref.watch(bitacoraTareasRepoProvider)));

// GENERACIÓN: POR QUÉ, PARA UNA PERSONA

class ResumenPorQue {
  final int generadas;
  final int fuera;
  final int sinGenerar;

  const ResumenPorQue({
    required this.generadas,
    required this.fuera,
    required this.sinGenerar,
  });

  factory ResumenPorQue.de(Iterable<DiagnosticoGeneracionEntity> filas) =>
      ResumenPorQue(
        generadas: filas.where((f) => f.existeOcurrencia).length,
        fuera: filas.where((f) => f.quedoFuera).length,
        sinGenerar: filas.where((f) => f.sinGenerar).length,
      );
}

class BitacoraPorQueState {
  /// Nula = quien consulta.
  final PersonaBuscada? persona;
  final DateTime fecha;
  final List<DiagnosticoGeneracionEntity> filas;
  final bool cargando;

  /// Si la última consulta terminó bien. Una consulta fallida deja esto en
  /// false para que la pantalla ofrezca reintentar y no muestre "sin tareas".
  final bool consultado;
  final String? error;

  BitacoraPorQueState({
    required this.fecha,
    this.persona,
    this.filas = const [],
    this.cargando = false,
    this.consultado = false,
    this.error,
  });

  late final ResumenPorQue resumen = ResumenPorQue.de(filas);

  BitacoraPorQueState copyWith({
    Object? persona = _igual,
    DateTime? fecha,
    List<DiagnosticoGeneracionEntity>? filas,
    bool? cargando,
    bool? consultado,
    String? error,
  }) {
    return BitacoraPorQueState(
      persona:
          identical(persona, _igual)
              ? this.persona
              : persona as PersonaBuscada?,
      fecha: fecha ?? this.fecha,
      filas: filas ?? this.filas,
      cargando: cargando ?? this.cargando,
      consultado: consultado ?? this.consultado,
      error: error,
    );
  }
}

class BitacoraPorQueNotifier extends StateNotifier<BitacoraPorQueState> {
  final BitacoraTareasRepository _repo;

  BitacoraPorQueNotifier(this._repo, {DateTime? hoy})
    : super(
        BitacoraPorQueState(
          fecha: _soloDia(hoy ?? DateTime.now()),
          cargando: true,
        ),
      ) {
    Future.microtask(consultar);
  }

  Future<void> consultar() async {
    final persona = state.persona;
    final fecha = state.fecha;
    state = state.copyWith(cargando: true);
    try {
      final filas = await _repo.porQue(
        codEmpleado: persona?.codEmpleado,
        fecha: fecha,
      );
      if (!mounted) return;
      if (!identical(state.persona, persona) || state.fecha != fecha) return;
      state = state.copyWith(filas: filas, cargando: false, consultado: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        filas: const [],
        cargando: false,
        consultado: false,
        error: _texto(e),
      );
    }
  }

  Future<void> elegirPersona(PersonaBuscada? persona) async {
    state = state.copyWith(
      persona: persona,
      filas: const [],
      consultado: false,
    );
    await consultar();
  }

  Future<void> cambiarFecha(DateTime fecha) async {
    state = state.copyWith(
      fecha: _soloDia(fecha),
      filas: const [],
      consultado: false,
    );
    await consultar();
  }

  /// Desde una fila de la bitácora de cumplimiento.
  Future<void> consultarPara(PersonaBuscada persona, DateTime fecha) async {
    state = state.copyWith(
      persona: persona,
      fecha: _soloDia(fecha),
      filas: const [],
      consultado: false,
    );
    await consultar();
  }
}

final bitacoraPorQueProvider = StateNotifierProvider.autoDispose<
  BitacoraPorQueNotifier,
  BitacoraPorQueState
>((ref) => BitacoraPorQueNotifier(ref.watch(bitacoraTareasRepoProvider)));
