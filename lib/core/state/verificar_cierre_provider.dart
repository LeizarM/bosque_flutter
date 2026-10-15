// Destino final: lib/core/state/verificar_cierre_provider.dart
import 'dart:typed_data';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';

import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/data/repositories/firma_cierre_impl.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';
import 'package:bosque_flutter/domain/repositories/firma_cierre_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El texto del servidor, sin el "Exception: " que agrega el repositorio.
String _mensaje(Object e) => mensajeError(e);

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Sin cambios" en copyWith, para poder poner [VerificarCierreState.diaConsulta]
/// en null.
const _igual = Object();

/// Verificar Cierre (tarea 39) por responsables: una sola tarea que hacen
/// varios (archivo SQL 81). Cada uno ve y firma solo las celdas que la matriz
/// le asigna; qué celdas son, qué día revisan y las reglas de la firma las
/// decide el servidor.
class VerificarCierreState {
  final PanelDatos<CeldaCierre> celdas;
  final PanelDatos<ArqueoDelCierre> arqueos;
  final PanelDatos<TraspasoMovCajaEntity> traspasos;
  final PanelDatos<LlegadaDelCierre> cajaFuerte;
  final PanelDatos<ChequeDelCierre> cheques;
  final PanelDatos<BitacoraCumplimientoEntity> tareas;

  /// Las secciones con fuente (archivo SQL 86), por código: sus filas de
  /// todas sus celdas.
  final Map<String, PanelDatos<FilaSeccion>> generales;

  /// Filas y firmas que están viajando, para no mandar dos veces.
  final Set<String> guardando;
  final bool descargandoPdf;

  /// De un solo uso, como en la revisión de Cierre de Operaciones.
  final String? mensajeError;
  final String? aviso;

  /// Otro día, solo para consultar (archivo SQL 92). Null: el que revisa la
  /// ocurrencia, el único que se marca y se firma.
  final DateTime? diaConsulta;

  /// Las firmas de ese otro día, del tablero.
  final PanelDatos<CeldaTablero> firmasDelDia;

  const VerificarCierreState({
    this.celdas = const PanelDatos<CeldaCierre>(cargando: true),
    this.arqueos = const PanelDatos<ArqueoDelCierre>(),
    this.traspasos = const PanelDatos<TraspasoMovCajaEntity>(),
    this.cajaFuerte = const PanelDatos<LlegadaDelCierre>(),
    this.cheques = const PanelDatos<ChequeDelCierre>(),
    this.tareas = const PanelDatos<BitacoraCumplimientoEntity>(),
    this.generales = const {},
    this.guardando = const {},
    this.descargandoPdf = false,
    this.mensajeError,
    this.aviso,
    this.diaConsulta,
    this.firmasDelDia = const PanelDatos<CeldaTablero>(),
  });

  bool get consultando => diaConsulta != null;

  /// Cómo quedó esa celda el día que se consulta; null si el tablero no la trae.
  CeldaTablero? firmaDelDia(CeldaCierre c) {
    for (final t in firmasDelDia.filas) {
      if (t.nombreSeccion == c.nombreSeccion &&
          t.nombreSucursal == c.nombreSucursal) {
        return t;
      }
    }
    return null;
  }

  /// Las secciones que le tocan, en el orden de la pantalla.
  List<PanelCierre> get secciones => [
    for (final p in PanelCierre.values)
      if (celdas.filas.any((c) => c.seccion == p)) p,
  ];

  List<CeldaCierre> celdasDe(PanelCierre p) =>
      celdas.filas.where((c) => c.seccion == p).toList();

  /// Todas las secciones en el orden del servidor (el del catálogo), por código.
  List<String> get bloques => [
    for (final c in celdas.filas) c.codigo,
  ].fold<List<String>>([], (l, c) => l.contains(c) ? l : (l..add(c)));

  /// Las secciones con fuente que le tocan.
  List<String> get conFuente => [
    for (final b in bloques)
      if (celdasDeCodigo(b).first.conFuente) b,
  ];

  List<CeldaCierre> celdasDeCodigo(String codigo) =>
      celdas.filas.where((c) => c.codigo == codigo).toList();

  PanelDatos<FilaSeccion> general(String codigo) =>
      generales[codigo] ?? const PanelDatos<FilaSeccion>(cargando: true);

  bool codigoFirmado(String codigo) =>
      celdasDeCodigo(codigo).every((c) => c.firmada);

  int get firmadas => celdas.filas.where((c) => c.firmada).length;
  int get total => celdas.filas.length;
  bool get completa => total > 0 && firmadas == total;

  bool seccionFirmada(PanelCierre p) => celdasDe(p).every((c) => c.firmada);

  /// Desde qué tareas tuyas se firma lo que falta del día que miras (archivo
  /// SQL 108): una por cada Verificar Cierre que lo revisa, sin la abierta.
  List<CeldaTablero> paraFirmarDesdeOtra(int abierta) {
    final vistas = <int>{};
    return [
      for (final c in firmasDelDia.filas)
        if (c.idBitTarea != null &&
            c.idBitTarea != abierta &&
            c.sinFirma &&
            vistas.add(c.idBitTarea!))
          c,
    ]..sort((a, b) => a.fechaTarea.compareTo(b.fechaTarea));
  }

  /// El día que revisa casi siempre es uno solo; con un feriado de una
  /// sucursal puede haber dos.
  List<DateTime> get diasRevisados =>
      {for (final c in celdas.filas) c.fechaRevisada}.toList()..sort();

  PanelDatos<Object?> panel(PanelCierre cual) => switch (cual) {
    PanelCierre.arqueos => arqueos,
    PanelCierre.traspasos => traspasos,
    PanelCierre.cajaFuerte => cajaFuerte,
    PanelCierre.cheques => cheques,
    PanelCierre.tareas => tareas,
  };

  int get arqueosRevisados => arqueos.filas.where((a) => a.revisado).length;
  int get llegadasVerificadas =>
      cajaFuerte.filas.where((l) => l.verificada).length;
  int get traspasosRevisados =>
      traspasos.filas.where((t) => t.fueVerificado != null).length;
  int get chequesParaRevisar =>
      cheques.filas.where((c) => c.paraRevisar).length;
  int get tareasSinHacer =>
      tareas.filas
          .where(
            (t) =>
                t.cumplimiento == Cumplimiento.noRealizada ||
                t.cumplimiento == Cumplimiento.enPlazo,
          )
          .length;

  VerificarCierreState copyWith({
    PanelDatos<CeldaCierre>? celdas,
    PanelDatos<ArqueoDelCierre>? arqueos,
    PanelDatos<TraspasoMovCajaEntity>? traspasos,
    PanelDatos<LlegadaDelCierre>? cajaFuerte,
    PanelDatos<ChequeDelCierre>? cheques,
    PanelDatos<BitacoraCumplimientoEntity>? tareas,
    Map<String, PanelDatos<FilaSeccion>>? generales,
    Set<String>? guardando,
    bool? descargandoPdf,
    String? mensajeError,
    String? aviso,
    Object? diaConsulta = _igual,
    PanelDatos<CeldaTablero>? firmasDelDia,
  }) => VerificarCierreState(
    celdas: celdas ?? this.celdas,
    arqueos: arqueos ?? this.arqueos,
    traspasos: traspasos ?? this.traspasos,
    cajaFuerte: cajaFuerte ?? this.cajaFuerte,
    cheques: cheques ?? this.cheques,
    tareas: tareas ?? this.tareas,
    generales: generales ?? this.generales,
    guardando: guardando ?? this.guardando,
    descargandoPdf: descargandoPdf ?? this.descargandoPdf,
    // De un solo uso: no se arrastran.
    mensajeError: mensajeError,
    aviso: aviso,
    diaConsulta:
        identical(diaConsulta, _igual)
            ? this.diaConsulta
            : diaConsulta as DateTime?,
    firmasDelDia: firmasDelDia ?? this.firmasDelDia,
  );
}

class VerificarCierreNotifier extends StateNotifier<VerificarCierreState> {
  final CierreOperacionesRepository _paneles;
  final FirmaCierreRepository _firmas;
  final int idBitTarea;

  VerificarCierreNotifier(this._paneles, this._firmas, this.idBitTarea)
    : super(const VerificarCierreState()) {
    Future.microtask(cargar);
  }

  /// Primero las celdas: deciden qué secciones se leen y de qué día.
  Future<void> cargar() async {
    if (!await _leerCeldas()) return;
    final dia = state.diaConsulta;
    await Future.wait([
      for (final p in state.secciones) recargar(p),
      for (final c in state.conFuente) recargarGeneral(c),
      if (dia != null) _leerFirmasDelDia(dia),
    ]);
  }

  /// Mira otro día, solo para consultar (archivo SQL 92); null o cualquiera
  /// de los días que revisa la ocurrencia vuelven a lo que se firma (con el
  /// saldo de caja chica, que revisa el mismo día, son dos). Lo de antes era
  /// de otro día: se limpia mientras se lee.
  Future<void> consultarDia(DateTime? dia) async {
    final propios = state.diasRevisados;
    final nuevo =
        dia == null || propios.any((p) => _mismoDia(dia, p))
            ? null
            : DateTime(dia.year, dia.month, dia.day);
    if (nuevo == state.diaConsulta) return;
    state = state.copyWith(
      diaConsulta: nuevo,
      arqueos: const PanelDatos<ArqueoDelCierre>(cargando: true),
      traspasos: const PanelDatos<TraspasoMovCajaEntity>(cargando: true),
      cajaFuerte: const PanelDatos<LlegadaDelCierre>(cargando: true),
      cheques: const PanelDatos<ChequeDelCierre>(cargando: true),
      tareas: const PanelDatos<BitacoraCumplimientoEntity>(cargando: true),
      generales: const {},
      firmasDelDia: const PanelDatos<CeldaTablero>(),
    );
    await Future.wait([
      for (final p in state.secciones) recargar(p),
      for (final c in state.conFuente) recargarGeneral(c),
      if (nuevo != null) _leerFirmasDelDia(nuevo),
    ]);
  }

  /// Cómo quedaron las firmas de ese día, del tablero (solo trae las celdas
  /// de quien mira). Un día se revisa en la ocurrencia de un día hábil
  /// posterior: se piden diez días desde ahí.
  Future<void> _leerFirmasDelDia(DateTime dia) async {
    state = state.copyWith(
      firmasDelDia: const PanelDatos<CeldaTablero>(cargando: true),
    );
    try {
      final filas = await _firmas.tablero(
        desde: dia,
        hasta: dia.add(const Duration(days: 10)),
      );
      if (!mounted || state.diaConsulta != dia) return;
      state = state.copyWith(
        firmasDelDia: PanelDatos<CeldaTablero>(
          filas: [
            for (final f in filas)
              if (_mismoDia(f.fechaRevisada, dia)) f,
          ],
          cargado: true,
        ),
      );
    } catch (e) {
      if (mounted && state.diaConsulta == dia) {
        state = state.copyWith(firmasDelDia: PanelDatos<CeldaTablero>(error: e));
      }
    }
  }

  /// Las filas de una sección con fuente: se lee cada celda (cada sucursal)
  /// y se juntan. Si una falla, la sección muestra el motivo del servidor.
  Future<void> recargarGeneral(String codigo) async {
    final celdas = state.celdasDeCodigo(codigo);
    if (celdas.isEmpty) return;
    final dia = state.diaConsulta;
    _ponerGeneral(codigo, state.general(codigo).leyendo(limpiar: false));
    try {
      final filas = <FilaSeccion>[];
      for (final c in celdas) {
        filas.addAll(await _firmas.filasSeccion(idBitTarea, c, fecha: dia));
      }
      // Si mientras tanto cambió el día, esta lectura ya no sirve.
      if (mounted && state.diaConsulta == dia) {
        _ponerGeneral(
          codigo,
          PanelDatos<FilaSeccion>(filas: filas, cargado: true),
        );
      }
    } catch (e) {
      if (mounted && state.diaConsulta == dia) {
        _ponerGeneral(codigo, PanelDatos<FilaSeccion>(error: e));
      }
    }
  }

  void _ponerGeneral(String codigo, PanelDatos<FilaSeccion> datos) {
    state = state.copyWith(generales: {...state.generales, codigo: datos});
  }

  /// Marca o desmarca una fila de una sección con fuente. Como con los
  /// arqueos, el servidor puede firmar o anular la celda.
  Future<void> marcarFila(
    CeldaCierre celda,
    FilaSeccion fila, {
    bool revisada = true,
  }) => _marcar('fila:${celda.codigo}:${fila.id}', () async {
    await _firmas.marcarFila(idBitTarea, celda, fila, revisada: revisada);
    if (!mounted) return;
    final datos = state.general(celda.codigo);
    _ponerGeneral(
      celda.codigo,
      datos.conFilas([
        for (final f in datos.filas) f.id == fila.id ? f.conMarca(revisada) : f,
      ]),
    );
  });

  Future<bool> _leerCeldas() async {
    state = state.copyWith(celdas: state.celdas.leyendo(limpiar: false));
    try {
      final celdas = await _firmas.misSecciones(idBitTarea);
      if (!mounted) return false;
      state = state.copyWith(
        celdas: PanelDatos<CeldaCierre>(filas: celdas, cargado: true),
      );
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(celdas: PanelDatos<CeldaCierre>(error: e));
      }
      return false;
    }
  }

  Future<void> recargar(PanelCierre panel) {
    final celdas = state.celdasDe(panel);
    if (celdas.isEmpty) return Future.value();
    final otro = state.diaConsulta;
    final dia = otro ?? celdas.first.fechaRevisada;
    return switch (panel) {
      PanelCierre.arqueos => _leer<ArqueoDelCierre>(
        de: (s) => s.arqueos,
        con: (s, p) => s.copyWith(arqueos: p),
        leer:
            () => _porSucursal(
              celdas,
              otro,
              (f) =>
                  _paneles.arqueos(idBitTarea, fecha: f, todasSucursales: true),
              (a) => a.sucursal,
            ),
      ),
      PanelCierre.cajaFuerte => _leer<LlegadaDelCierre>(
        de: (s) => s.cajaFuerte,
        con: (s, p) => s.copyWith(cajaFuerte: p),
        leer:
            () => _porSucursal(
              celdas,
              otro,
              (f) => _paneles.cajaFuerte(
                idBitTarea,
                fecha: f,
                todasSucursales: true,
              ),
              (l) => l.sucursal,
            ),
      ),
      PanelCierre.traspasos => _leer<TraspasoMovCajaEntity>(
        de: (s) => s.traspasos,
        con: (s, p) => s.copyWith(traspasos: p),
        leer: () => _paneles.traspasos(fecha: dia),
      ),
      PanelCierre.cheques => _leer<ChequeDelCierre>(
        de: (s) => s.cheques,
        con: (s, p) => s.copyWith(cheques: p),
        leer: () => _paneles.cheques(idBitTarea, fecha: dia),
      ),
      PanelCierre.tareas => _leer<BitacoraCumplimientoEntity>(
        de: (s) => s.tareas,
        con: (s, p) => s.copyWith(tareas: p),
        leer:
            () =>
                _paneles.tareas(idBitTarea, fecha: dia, todasSucursales: true),
      ),
    };
  }

  /// Arqueos y caja fuerte: cada celda es una sucursal y su día ([otro], si
  /// se mira otro). Se lee cada día una vez y se dejan solo las filas de las
  /// sucursales que le tocan.
  Future<List<T>> _porSucursal<T>(
    List<CeldaCierre> celdas,
    DateTime? otro,
    Future<List<T>> Function(DateTime fecha) leer,
    String? Function(T fila) sucursalDe,
  ) async {
    final porDia = <DateTime, Set<String>>{};
    for (final c in celdas) {
      porDia.putIfAbsent(otro ?? c.fechaRevisada, () => {}).add(c.nombreSucursal);
    }
    final filas = <T>[];
    for (final entrada in porDia.entries) {
      final delDia = await leer(entrada.key);
      filas.addAll(delDia.where((f) => entrada.value.contains(sucursalDe(f))));
    }
    return filas;
  }

  Future<void> _leer<T>({
    required PanelDatos<T> Function(VerificarCierreState) de,
    required VerificarCierreState Function(VerificarCierreState, PanelDatos<T>)
    con,
    required Future<List<T>> Function() leer,
  }) async {
    final dia = state.diaConsulta;
    state = con(state, de(state).leyendo(limpiar: false));
    try {
      final filas = await leer();
      // Si mientras tanto cambió el día, esta lectura ya no sirve.
      if (mounted && state.diaConsulta == dia) {
        state = con(state, PanelDatos<T>(filas: filas, cargado: true));
      }
    } catch (e) {
      if (mounted && state.diaConsulta == dia) {
        state = con(state, PanelDatos<T>(error: e));
      }
    }
  }

  /// El visto bueno de un arqueo, o quitarlo (ver [CierreOperacionesNotifier]).
  Future<void> marcarArqueoRevisado(int idAC, {bool revisado = true}) =>
      _marcar('arqueo:$idAC', () async {
        await _paneles.marcarArqueoRevisado(
          idAC,
          idBitTarea: idBitTarea,
          revisado: revisado,
        );
        state = state.copyWith(
          arqueos: state.arqueos.conFilas([
            for (final a in state.arqueos.filas)
              a.idAC == idAC
                  ? (revisado ? a.comoRevisado() : a.comoSinRevisar())
                  : a,
          ]),
        );
      });

  Future<void> marcarLlegadaVerificada(int idRp, {bool verificada = true}) =>
      _marcar('llegada:$idRp', () async {
        await _paneles.marcarLlegadaVerificada(
          idRp,
          idBitTarea: idBitTarea,
          verificada: verificada,
        );
        state = state.copyWith(
          cajaFuerte: state.cajaFuerte.conFilas([
            for (final l in state.cajaFuerte.filas)
              l.idRp == idRp
                  ? (verificada ? l.comoVerificada() : l.comoSinVerificar())
                  : l,
          ]),
        );
      });

  /// Marcar puede firmar o anular la celda en el servidor (archivo SQL 81):
  /// se vuelven a leer las celdas y se avisa qué cambió.
  Future<void> _marcar(String clave, Future<void> Function() hacer) async {
    if (state.guardando.contains(clave)) return;
    state = state.copyWith(guardando: {...state.guardando, clave});
    final antes = {for (final c in state.celdas.filas) c.clave: c.firmada};
    try {
      await hacer();
      if (!mounted) return;
      await _leerCeldas();
      if (!mounted) return;
      final ahora = state.celdas.filas;
      final firmada = ahora.where((c) => c.firmada && antes[c.clave] == false);
      final anulada = ahora.where((c) => !c.firmada && antes[c.clave] == true);
      state = state.copyWith(
        guardando: _sin(clave),
        aviso:
            firmada.isNotEmpty
                ? 'Quedó todo revisado: se firmó ${_nombre(firmada.first)}.'
                : anulada.isNotEmpty
                ? 'Se anuló la firma de ${_nombre(anulada.first)}: '
                    'vuelve a quedar sin firmar.'
                : null,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          guardando: _sin(clave),
          mensajeError: _mensaje(e),
        );
      }
    }
  }

  /// Firma una celda. Devuelve el motivo si el servidor no la aceptó, para
  /// mostrarlo en el mismo diálogo sin perder lo escrito.
  Future<String?> firmar(CeldaCierre celda, {String? obs}) =>
      _escribir('firma:${celda.clave}', 'Sección firmada.', () {
        return _firmas.firmar(idBitTarea, celda, obs: obs);
      });

  Future<String?> anular(CeldaCierre celda, {required String motivo}) {
    final idFC = celda.idFC;
    if (idFC == null) return Future.value(null);
    return _escribir('firma:${celda.clave}', 'Firma anulada.', () {
      return _firmas.anular(idFC, motivo: motivo);
    });
  }

  Future<String?> _escribir(
    String clave,
    String aviso,
    Future<void> Function() hacer,
  ) async {
    if (state.guardando.contains(clave)) return null;
    state = state.copyWith(guardando: {...state.guardando, clave});
    try {
      await hacer();
      if (!mounted) return null;
      state = state.copyWith(guardando: _sin(clave), aviso: aviso);
      await _leerCeldas();
      return null;
    } catch (e) {
      if (mounted) state = state.copyWith(guardando: _sin(clave));
      return _mensaje(e);
    }
  }

  /// El comprobante de un arqueo (RptArqueoDeCaja).
  Future<Uint8List?> pdfArqueo(int idAC) async {
    if (state.descargandoPdf) return null;
    state = state.copyWith(descargandoPdf: true);
    try {
      final bytes = await _paneles.pdfArqueo(idAC);
      if (mounted) state = state.copyWith(descargandoPdf: false);
      return bytes;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          descargandoPdf: false,
          mensajeError: _mensaje(e),
        );
      }
      return null;
    }
  }

  Set<String> _sin(String clave) => {...state.guardando}..remove(clave);

  static String _nombre(CeldaCierre c) =>
      '${c.nombreSeccion.toLowerCase()} de ${c.nombreSucursal}';
}

/// Se expone para poder reemplazarlo en las pruebas.
final firmaCierreRepoProvider = Provider<FirmaCierreRepository>(
  (ref) => FirmaCierreImpl(),
);

/// `family` por ocurrencia de la 39.
final verificarCierreProvider = StateNotifierProvider.autoDispose
    .family<VerificarCierreNotifier, VerificarCierreState, int>(
      (ref, idBitTarea) => VerificarCierreNotifier(
        ref.read(cierreOperacionesRepoProvider),
        ref.read(firmaCierreRepoProvider),
        idBitTarea,
      ),
    );
