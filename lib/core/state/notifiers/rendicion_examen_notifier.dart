import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/core/utils/ultima_pregunta_storage.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

/// Quién rinde: cambia el repositorio (y con él el token), no la pantalla.
enum OrigenRendicion { empleado, postulante }

@immutable
class ClaveRendicion {
  const ClaveRendicion(this.origen, this.codExamen);

  final OrigenRendicion origen;
  final BigInt codExamen;

  @override
  bool operator ==(Object other) =>
      other is ClaveRendicion && other.origen == origen && other.codExamen == codExamen;

  @override
  int get hashCode => Object.hash(origen, codExamen);
}

@immutable
class RendicionExamenState {
  const RendicionExamenState({
    this.estado,
    this.preguntas = const [],
    this.opciones = const {},
    this.marcadas = const {},
    this.textos = const {},
    this.guardando = const {},
    this.actual = 0,
    this.segundos = 0,
    this.cargando = true,
    this.iniciando = false,
    this.entregando = false,
    this.error,
    this.aviso,
    this.avisoId = 0,
  });

  final TcpeEstadoRendicionEntity? estado;
  final List<TcpePreguntaRendicionEntity> preguntas;

  /// Opciones de cada cerrada, por `codPreguntaH`.
  final Map<BigInt, List<TcpeOpcionRendicionEntity>> opciones;

  /// Lo que marcó quien rinde, por `codPreguntaH`.
  final Map<BigInt, Set<BigInt>> marcadas;

  /// Lo que escribió en cada abierta, por `codPreguntaH`.
  final Map<BigInt, String> textos;

  /// Preguntas con una respuesta viajando al servidor.
  final Set<BigInt> guardando;
  final int actual;

  /// Lo que muestra el reloj.
  final int segundos;
  final bool cargando;
  final bool iniciando;
  final bool entregando;

  /// Error al cargar: la pantalla entera muestra el reintento.
  final Object? error;

  /// Mensaje para un aviso suelto (una respuesta que no se guardó, el tiempo
  /// vencido). [avisoId] cambia en cada uno para que la UI lo muestre una vez.
  final String? aviso;
  final int avisoId;

  EstadoExamenTcpe get estadoExamen => EstadoExamenTcpe.desde(estado?.estado);

  bool respondida(TcpePreguntaRendicionEntity p) => p.esCerrada
      ? (marcadas[p.codPreguntaH]?.isNotEmpty ?? false)
      : (textos[p.codPreguntaH] ?? '').trim().isNotEmpty;

  int get respondidas => preguntas.where(respondida).length;

  /// Índices (base 0) de las preguntas sin responder.
  List<int> get pendientes => [
    for (var i = 0; i < preguntas.length; i++)
      if (!respondida(preguntas[i])) i,
  ];

  TcpePreguntaRendicionEntity? get preguntaActual =>
      preguntas.isEmpty ? null : preguntas[actual.clamp(0, preguntas.length - 1)];

  RendicionExamenState copyWith({
    TcpeEstadoRendicionEntity? estado,
    List<TcpePreguntaRendicionEntity>? preguntas,
    Map<BigInt, List<TcpeOpcionRendicionEntity>>? opciones,
    Map<BigInt, Set<BigInt>>? marcadas,
    Map<BigInt, String>? textos,
    Set<BigInt>? guardando,
    int? actual,
    int? segundos,
    bool? cargando,
    bool? iniciando,
    bool? entregando,
    Object? error,
    bool limpiarError = false,
    String? aviso,
  }) => RendicionExamenState(
    estado: estado ?? this.estado,
    preguntas: preguntas ?? this.preguntas,
    opciones: opciones ?? this.opciones,
    marcadas: marcadas ?? this.marcadas,
    textos: textos ?? this.textos,
    guardando: guardando ?? this.guardando,
    actual: actual ?? this.actual,
    segundos: segundos ?? this.segundos,
    cargando: cargando ?? this.cargando,
    iniciando: iniciando ?? this.iniciando,
    entregando: entregando ?? this.entregando,
    error: limpiarError ? null : (error ?? this.error),
    aviso: aviso ?? this.aviso,
    avisoId: aviso != null ? avisoId + 1 : avisoId,
  );
}

/// La rendición de un examen: cronómetro, respuestas al instante y entrega.
class RendicionExamenNotifier extends StateNotifier<RendicionExamenState> {
  RendicionExamenNotifier(
    this._repo,
    this.codExamen, {
    CronometroExamen? cronometro,
    Duration retrasoTexto = const Duration(milliseconds: 800),
    UltimaPreguntaStorage memoria = const UltimaPreguntaStorage(),
    Duration intervaloLatido = const Duration(seconds: 15),
  }) : _cronometro = cronometro ?? CronometroExamen(),
       _retrasoTexto = retrasoTexto,
       _memoria = memoria,
       _intervaloLatido = intervaloLatido,
       super(const RendicionExamenState()) {
    cargar();
  }

  final RendicionExamenRepository _repo;
  final BigInt codExamen;
  final CronometroExamen _cronometro;
  final Duration _retrasoTexto;
  final UltimaPreguntaStorage _memoria;
  Timer? _tic;
  Timer? _latido;
  Duration _intervaloLatido;
  DateTime? _ultimaSalida;

  /// La última pregunta vista se recupera una sola vez, en la primera carga.
  bool _posicionRestaurada = false;
  final Map<BigInt, Timer> _pendientesTexto = {};
  bool _entregaAutomaticaHecha = false;

  /// Las respuestas que siguen viajando: la entrega espera a que terminen.
  final Set<Future<void>> _enVuelo = {};

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final estado = await _repo.estadoExamen(codExamen);
      if (!mounted) return;
      if (estado == null) {
        state = state.copyWith(cargando: false, error: 'No encontramos este examen entre los tuyos.');
        return;
      }
      if (EstadoExamenTcpe.desde(estado.estado) == EstadoExamenTcpe.enCurso && estado.esOnline) {
        final ultima = _posicionRestaurada ? Future<BigInt?>.value() : _memoria.leer(codExamen);
        final r = await Future.wait([
          _repo.preguntasExamen(codExamen),
          _repo.opcionesExamen(codExamen),
        ]);
        final codUltima = await ultima;
        if (!mounted) return;
        final preguntas = (r[0] as List<TcpePreguntaRendicionEntity>).toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));
        final opciones = <BigInt, List<TcpeOpcionRendicionEntity>>{};
        final marcadas = <BigInt, Set<BigInt>>{};
        for (final o in r[1] as List<TcpeOpcionRendicionEntity>) {
          final cod = o.codPreguntaH;
          if (cod == null) continue;
          opciones.putIfAbsent(cod, () => []).add(o);
          if (o.marcada) marcadas.putIfAbsent(cod, () => <BigInt>{}).add(o.codRsptaOpH);
        }
        final textos = {
          for (final p in preguntas)
            if (!p.esCerrada) p.codPreguntaH: p.respuestaU ?? '',
        };
        var actual = state.actual;
        if (!_posicionRestaurada) {
          _posicionRestaurada = true;
          final i = preguntas.indexWhere((p) => p.codPreguntaH == codUltima);
          if (i >= 0) actual = i;
        }
        _cronometro.sincronizar(estado.segundosRestantes);
        state = state.copyWith(
          estado: estado,
          preguntas: preguntas,
          opciones: opciones,
          marcadas: marcadas,
          textos: textos,
          segundos: _cronometro.restantes,
          cargando: false,
          actual: actual.clamp(0, preguntas.isEmpty ? 0 : preguntas.length - 1),
        );
        _arrancarReloj();
        _arrancarLatido();
        _enviarLatido();
      } else {
        _detenerReloj();
        if (EstadoExamenTcpe.desde(estado.estado).cerrado) _memoria.olvidar(codExamen);
        state = state.copyWith(estado: estado, cargando: false);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, error: e);
    }
  }

  Future<void> iniciar() async {
    if (state.iniciando) return;
    state = state.copyWith(iniciando: true);
    try {
      await _repo.iniciarExamen(codExamen);
      if (!mounted) return;
      state = state.copyWith(iniciando: false);
      await cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(iniciando: false);
      // Fuera de la ventana o ya vencido (el SP lo entregó): se recarga para mostrar
      // cómo quedó, sin depender del texto del mensaje.
      await cargar();
      if (mounted) state = state.copyWith(aviso: '$e');
    }
  }

  void irA(int indice) {
    if (state.preguntas.isEmpty) return;
    _guardarTextoAhora(state.preguntaActual?.codPreguntaH);
    state = state.copyWith(actual: indice.clamp(0, state.preguntas.length - 1));
    final p = state.preguntaActual;
    if (p != null && !_cerrado) {
      _memoria.guardar(codExamen, p.codPreguntaH);
      _enviarLatido();
    }
  }

  /// Cada cuánto avisa que sigue activo: `segundosLatido` de la configuración.
  void ajustarLatido(Duration intervalo) {
    if (intervalo == _intervaloLatido || intervalo <= Duration.zero) return;
    _intervaloLatido = intervalo;
    if (_latido != null) _arrancarLatido();
  }

  /// Salió de la pestaña o de la app (web: `visibilitychange`/`blur`; móvil:
  /// ciclo de vida). Avisos seguidos de la misma salida cuentan una vez.
  void salioDePestana() {
    if (state.estadoExamen != EstadoExamenTcpe.enCurso || _cerrado) return;
    final ahora = DateTime.now();
    final previa = _ultimaSalida;
    if (previa != null && ahora.difference(previa) < const Duration(seconds: 3)) return;
    _ultimaSalida = ahora;
    _enviarLatido(salioPestana: true);
  }

  /// `Rendir` A: la pregunta que ve y si salió. Los segundos que vuelven
  /// sincronizan el reloj; un latido perdido no se avisa, lo repone el siguiente.
  Future<void> _enviarLatido({bool salioPestana = false}) async {
    if (!mounted || state.estadoExamen != EstadoExamenTcpe.enCurso || _cerrado) return;
    try {
      final segundos = await _repo.latido(
        codExamen: codExamen,
        codPreguntaH: state.preguntaActual?.codPreguntaH,
        salioPestana: salioPestana,
      );
      if (!mounted || _cerrado) return;
      if (segundos != null) _resincronizar(segundos);
    } catch (e) {
      if (mounted && esTiempoVencido(e)) await _cerrarPorTiempo('$e');
    }
  }

  void _arrancarLatido() {
    _latido?.cancel();
    _latido = Timer.periodic(_intervaloLatido, (_) => _enviarLatido());
  }

  void siguiente() => irA(state.actual + 1);
  void anterior() => irA(state.actual - 1);

  /// Marca o desmarca una opción y la guarda al instante.
  void alternarOpcion(BigInt codPreguntaH, BigInt codRsptaOpH) {
    if (_cerrado) return;
    final previas = state.marcadas[codPreguntaH] ?? const <BigInt>{};
    final nuevas = {...previas};
    if (!nuevas.remove(codRsptaOpH)) nuevas.add(codRsptaOpH);
    state = state.copyWith(marcadas: {...state.marcadas, codPreguntaH: nuevas});
    _responder(codPreguntaH, opciones: nuevas.toList(), alFallar: () {
      state = state.copyWith(marcadas: {...state.marcadas, codPreguntaH: previas});
    });
  }

  /// El texto de una abierta: se guarda tras una pausa corta al escribir.
  void escribir(BigInt codPreguntaH, String texto) {
    if (_cerrado) return;
    state = state.copyWith(textos: {...state.textos, codPreguntaH: texto});
    _pendientesTexto.remove(codPreguntaH)?.cancel();
    _pendientesTexto[codPreguntaH] = Timer(_retrasoTexto, () => _guardarTextoAhora(codPreguntaH));
  }

  void _guardarTextoAhora(BigInt? codPreguntaH) {
    if (codPreguntaH == null) return;
    final t = _pendientesTexto.remove(codPreguntaH);
    if (t == null) return;
    t.cancel();
    _responder(codPreguntaH, respuestaU: state.textos[codPreguntaH] ?? '');
  }

  bool get _cerrado => state.entregando || state.estadoExamen.cerrado;

  void _responder(
    BigInt codPreguntaH, {
    List<BigInt>? opciones,
    String? respuestaU,
    VoidCallback? alFallar,
  }) {
    late final Future<void> vuelo;
    vuelo = () async {
      state = state.copyWith(guardando: {...state.guardando, codPreguntaH});
      try {
        final segundos = await _repo.responderPregunta(
          codExamen: codExamen,
          codPreguntaH: codPreguntaH,
          opciones: opciones,
          respuestaU: respuestaU,
        );
        if (!mounted) return;
        if (segundos != null) _resincronizar(segundos);
      } catch (e) {
        if (!mounted) return;
        if (esTiempoVencido(e) || await _servidorLoCerro()) {
          await _cerrarPorTiempo('$e');
        } else {
          alFallar?.call();
          state = state.copyWith(aviso: 'No se guardó tu respuesta: $e');
        }
      } finally {
        if (mounted) {
          state = state.copyWith(guardando: {...state.guardando}..remove(codPreguntaH));
        }
        _enVuelo.remove(vuelo);
      }
    }();
    _enVuelo.add(vuelo);
  }

  /// Tras un error, el estado del servidor decide si ya se entregó: no depende
  /// del texto del mensaje, que vive en SQL y puede cambiar.
  Future<bool> _servidorLoCerro() async {
    final e = await _repo.estadoExamen(codExamen).catchError((_) => null);
    return mounted && e != null && EstadoExamenTcpe.desde(e.estado).cerrado;
  }

  /// El reloj vuelve a contar desde lo que dijo el servidor.
  void _resincronizar(int segundosServidor) {
    _cronometro.sincronizar(segundosServidor);
    state = state.copyWith(segundos: _cronometro.restantes);
  }

  /// Entrega el examen. Primero manda los textos que esperaban la pausa y
  /// espera las respuestas que están viajando.
  Future<bool> entregar() async {
    if (state.entregando) return false;
    state = state.copyWith(entregando: true);
    for (final cod in _pendientesTexto.keys.toList()) {
      _guardarTextoAhora(cod);
    }
    try {
      await Future.wait(_enVuelo.toList());
      if (!mounted) return false;
      if (!state.estadoExamen.cerrado) await _repo.finalizarExamen(codExamen);
      _detenerReloj();
      _memoria.olvidar(codExamen);
      final estado = await _repo.estadoExamen(codExamen);
      if (!mounted) return true;
      state = state.copyWith(estado: estado, entregando: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Si ya estaba entregado (vencido en el servidor), cuenta como entregado.
      final estado = await _repo.estadoExamen(codExamen).catchError((_) => null);
      if (!mounted) return false;
      if (estado != null && EstadoExamenTcpe.desde(estado.estado).cerrado) {
        _detenerReloj();
        _memoria.olvidar(codExamen);
        state = state.copyWith(estado: estado, entregando: false);
        return true;
      }
      state = state.copyWith(entregando: false, aviso: 'No se pudo entregar: $e');
      return false;
    }
  }

  /// El servidor ya entregó el examen: no se reintenta nada, se muestra cómo
  /// quedó. Si no se puede leer el estado, se da por entregado igual.
  Future<void> _cerrarPorTiempo(String mensaje) async {
    if (_entregaAutomaticaHecha && state.estadoExamen.cerrado) return;
    _entregaAutomaticaHecha = true;
    _detenerReloj();
    _memoria.olvidar(codExamen);
    _pendientesTexto
      ..forEach((_, t) => t.cancel())
      ..clear();
    final estado = await _repo.estadoExamen(codExamen).catchError((_) => null);
    if (!mounted) return;
    final cerrado =
        estado != null && EstadoExamenTcpe.desde(estado.estado).cerrado
            ? estado
            : state.estado?.copyWith(estado: EstadoExamenTcpe.porRevisar.codigo, segundosRestantes: 0);
    state = state.copyWith(estado: cerrado, segundos: 0, aviso: mensaje);
  }

  void _arrancarReloj() {
    _tic?.cancel();
    _tic = Timer.periodic(const Duration(seconds: 1), (_) => _alTic());
  }

  void _detenerReloj() {
    _tic?.cancel();
    _tic = null;
    _latido?.cancel();
    _latido = null;
  }

  void _alTic() {
    if (!mounted) return;
    final s = _cronometro.restantes;
    if (s != state.segundos) state = state.copyWith(segundos: s);
    if (s == 0 && !_entregaAutomaticaHecha && !state.estadoExamen.cerrado) {
      _entregaAutomaticaHecha = true;
      _detenerReloj();
      entregar().then((ok) {
        if (ok && mounted) {
          state = state.copyWith(aviso: 'Se terminó el tiempo: el examen se entregó automáticamente.');
        }
      });
    }
  }

  @override
  void dispose() {
    _detenerReloj();
    // Un texto a medio guardar se manda igual: el examen sigue corriendo.
    for (final e in _pendientesTexto.entries.toList()) {
      e.value.cancel();
      _repo
          .responderPregunta(
            codExamen: codExamen,
            codPreguntaH: e.key,
            respuestaU: state.textos[e.key] ?? '',
          )
          .catchError((_) => null);
    }
    _pendientesTexto.clear();
    super.dispose();
  }
}

/// El backend corta con este mensaje cuando se pasó la hora límite.
bool esTiempoVencido(Object e) {
  final t = '$e'.toLowerCase();
  return t.contains('terminó el tiempo') ||
      t.contains('termino el tiempo') ||
      t.contains('se entregó automáticamente') ||
      t.contains('se entrego automaticamente');
}
