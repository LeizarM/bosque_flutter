import 'dart:typed_data';

import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/data/repositories/cierre_operaciones_impl.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lo que muestra una sección de la revisión.
///
/// Cada una lee por su cuenta: que SAP no conteste no puede dejar la pantalla
/// entera en blanco cuando los arqueos sí se leyeron.
class PanelDatos<T> {
  final List<T> filas;
  final bool cargando;

  /// Si la última lectura terminó bien. "No se pudo leer" y "no hubo nada" son
  /// cosas distintas: solo la segunda deja dar la sección por revisada.
  final bool cargado;

  final Object? error;

  const PanelDatos({
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.error,
  });

  /// Vuelve a leer. Con [limpiar], lo que había era de otro día o de otro
  /// alcance y no se sigue mostrando mientras llega lo nuevo.
  PanelDatos<T> leyendo({required bool limpiar}) => PanelDatos<T>(
    filas: limpiar ? const [] : filas,
    cargando: true,
    cargado: !limpiar && cargado,
  );

  PanelDatos<T> conFilas(List<T> nuevas) => PanelDatos<T>(
    filas: nuevas,
    cargando: cargando,
    cargado: cargado,
    error: error,
  );
}

/// Con qué se abrió la revisión. Es la clave del provider.
///
/// No lleva permisos: **la tarea es el permiso**. Quien tiene la ocurrencia del
/// día ve y marca las cinco secciones, y el servidor comprueba lo mismo.
class AperturaCierre {
  final int idBitTarea;
  final ModoCierre modo;

  /// El día de la ocurrencia: con el que abre y el único que se puede cerrar.
  final DateTime fechaOcurrencia;

  AperturaCierre({
    required this.idBitTarea,
    required this.modo,
    required DateTime fechaOcurrencia,
  }) : fechaOcurrencia = _dia(fechaOcurrencia);

  @override
  bool operator ==(Object other) =>
      other is AperturaCierre &&
      other.idBitTarea == idBitTarea &&
      other.modo == modo &&
      other.fechaOcurrencia == fechaOcurrencia;

  @override
  int get hashCode => Object.hash(idBitTarea, modo, fechaOcurrencia);
}

class CierreOperacionesState {
  final ModoCierre modo;

  /// El día en revisión. Arranca en el de la ocurrencia.
  final DateTime fecha;
  final DateTime fechaOcurrencia;

  final bool todasSucursales;

  final PanelDatos<ArqueoDelCierre> arqueos;
  final PanelDatos<TraspasoMovCajaEntity> traspasos;
  final PanelDatos<LlegadaDelCierre> cajaFuerte;
  final PanelDatos<ChequeDelCierre> cheques;
  final PanelDatos<BitacoraCumplimientoEntity> tareas;

  /// Las filas que están viajando, para que dos toques no manden dos veces.
  final Set<String> guardando;

  /// Las secciones que no tienen nada que marcar y la persona dio por
  /// revisadas. Se vacían al cambiar de día o al releer esa sección: lo que se
  /// revisó era lo de antes.
  final Set<PanelCierre> seccionesConfirmadas;

  final bool cerrando;
  final bool descargandoPdf;

  /// De un solo uso: la pantalla los muestra y se limpian en el próximo cambio.
  final String? mensajeError;
  final String? aviso;

  /// Cuántas ocurrencias cerró el servidor. No nulo = la revisión terminó.
  final int? cerradas;

  const CierreOperacionesState({
    required this.modo,
    required this.fecha,
    required this.fechaOcurrencia,
    this.todasSucursales = false,
    this.arqueos = const PanelDatos<ArqueoDelCierre>(),
    this.traspasos = const PanelDatos<TraspasoMovCajaEntity>(),
    this.cajaFuerte = const PanelDatos<LlegadaDelCierre>(),
    this.cheques = const PanelDatos<ChequeDelCierre>(),
    this.tareas = const PanelDatos<BitacoraCumplimientoEntity>(),
    this.guardando = const {},
    this.seccionesConfirmadas = const {},
    this.cerrando = false,
    this.descargandoPdf = false,
    this.mensajeError,
    this.aviso,
    this.cerradas,
  });

  factory CierreOperacionesState.inicial(AperturaCierre apertura) =>
      CierreOperacionesState(
        modo: apertura.modo,
        fecha: apertura.fechaOcurrencia,
        fechaOcurrencia: apertura.fechaOcurrencia,
        // Arranca leyendo: en reposo, el primer cuadro se vería como un error.
        arqueos: const PanelDatos<ArqueoDelCierre>(cargando: true),
        traspasos: const PanelDatos<TraspasoMovCajaEntity>(cargando: true),
        cajaFuerte: const PanelDatos<LlegadaDelCierre>(cargando: true),
        cheques: const PanelDatos<ChequeDelCierre>(cargando: true),
        tareas: const PanelDatos<BitacoraCumplimientoEntity>(cargando: true),
      );

  List<PanelCierre> get paneles => PanelCierre.values;

  PanelDatos<Object?> panel(PanelCierre cual) => switch (cual) {
    PanelCierre.arqueos => arqueos,
    PanelCierre.traspasos => traspasos,
    PanelCierre.cajaFuerte => cajaFuerte,
    PanelCierre.cheques => cheques,
    PanelCierre.tareas => tareas,
  };

  /// El día que se está mirando es el de la tarea.
  bool get mirandoElDiaDeLaTarea => fecha == fechaOcurrencia;

  bool get todoLeido => paneles.every((p) => panel(p).cargado);

  bool get algoFallo => paneles.any((p) => panel(p).error != null);

  int get arqueosRevisados => arqueos.filas.where((a) => a.revisado).length;
  int get arqueosSinRevisar => arqueos.filas.length - arqueosRevisados;

  int get traspasosSinRevisar =>
      traspasos.filas.where((t) => t.fueVerificado == null).length;
  int get traspasosNoCuadran =>
      traspasos.filas.where((t) => t.fueVerificado == 0).length;
  int get traspasosRevisados => traspasos.filas.length - traspasosSinRevisar;

  int get llegadasVerificadas =>
      cajaFuerte.filas.where((l) => l.verificada).length;
  int get llegadasSinVerificar => cajaFuerte.filas.length - llegadasVerificadas;

  int get chequesParaRevisar =>
      cheques.filas.where((c) => c.paraRevisar).length;

  /// Las que nadie respondió: no realizadas y las que todavía están en plazo.
  int get tareasSinHacer =>
      tareas.filas
          .where(
            (t) =>
                t.cumplimiento == Cumplimiento.noRealizada ||
                t.cumplimiento == Cumplimiento.enPlazo,
          )
          .length;

  /// Las secciones que se revisan marcando fila por fila: el visto bueno del
  /// arqueo y el de la llegada son de quien revisa. Los traspasos no están:
  /// los marca el cajero en su tarea, y aquí la sección se confirma entera.
  static bool seMarcaFilaPorFila(PanelCierre p) =>
      p == PanelCierre.arqueos || p == PanelCierre.cajaFuerte;

  /// Cuántas filas de una sección quedan sin marcar.
  int filasSinMarcar(PanelCierre p) => switch (p) {
    PanelCierre.arqueos => arqueosSinRevisar,
    PanelCierre.cajaFuerte => llegadasSinVerificar,
    // Traspasos, cheques y tareas del día son de otras personas: aquí no hay
    // nada que marcar, solo la sección que confirmar.
    PanelCierre.traspasos || PanelCierre.cheques || PanelCierre.tareas => 0,
  };

  /// La sección no tiene filas que marcar, así que se revisa con el
  /// interruptor: los cheques y las tareas de los demás, y cualquiera que haya
  /// venido vacía.
  bool necesitaConfirmacion(PanelCierre p) {
    final datos = panel(p);
    if (!datos.cargado) return false;
    if (filasSinMarcar(p) > 0) return false;
    return !(seMarcaFilaPorFila(p) && datos.filas.isNotEmpty);
  }

  /// Una sección está revisada cuando se pudo leer y, o bien se marcaron todas
  /// sus filas, o bien la persona la dio por revisada.
  bool seccionRevisada(PanelCierre p) {
    final datos = panel(p);
    if (!datos.cargado) return false;
    if (filasSinMarcar(p) > 0) return false;
    if (seMarcaFilaPorFila(p) && datos.filas.isNotEmpty) return true;
    return seccionesConfirmadas.contains(p);
  }

  /// Regla de negocio: hay que revisar TODO; solo entonces se completa.
  bool get todoRevisado => paneles.every(seccionRevisada);

  /// No se cierra un día que no se pudo leer, ni desde otro día, ni con algo
  /// sin revisar.
  bool get puedeCerrar =>
      mirandoElDiaDeLaTarea && todoRevisado && !cerrando && cerradas == null;

  /// Lo que falta para poder cerrar, en palabras.
  List<String> get faltaParaCerrar => [
    for (final p in paneles)
      if (!seccionRevisada(p)) _queFalta(p),
  ];

  String _queFalta(PanelCierre p) {
    final datos = panel(p);
    final nombre = _nombreDe(p);
    if (!datos.cargado) return 'leer $nombre';
    final sinMarcar = filasSinMarcar(p);
    if (sinMarcar > 0) {
      return switch (p) {
        PanelCierre.arqueos => _cuantos(
          sinMarcar,
          'arqueo por revisar',
          'arqueos por revisar',
        ),
        _ => _cuantos(
          sinMarcar,
          'llegada por verificar',
          'llegadas por verificar',
        ),
      };
    }
    return 'confirmar $nombre';
  }

  static String _nombreDe(PanelCierre p) => switch (p) {
    PanelCierre.arqueos => 'los arqueos',
    PanelCierre.traspasos => 'los traspasos',
    PanelCierre.cajaFuerte => 'la caja fuerte',
    PanelCierre.cheques => 'los cheques',
    PanelCierre.tareas => 'las tareas del día',
  };

  CierreOperacionesState copyWith({
    DateTime? fecha,
    bool? todasSucursales,
    PanelDatos<ArqueoDelCierre>? arqueos,
    PanelDatos<TraspasoMovCajaEntity>? traspasos,
    PanelDatos<LlegadaDelCierre>? cajaFuerte,
    PanelDatos<ChequeDelCierre>? cheques,
    PanelDatos<BitacoraCumplimientoEntity>? tareas,
    Set<String>? guardando,
    Set<PanelCierre>? seccionesConfirmadas,
    bool? cerrando,
    bool? descargandoPdf,
    String? mensajeError,
    String? aviso,
    int? cerradas,
  }) => CierreOperacionesState(
    modo: modo,
    fecha: fecha ?? this.fecha,
    fechaOcurrencia: fechaOcurrencia,
    todasSucursales: todasSucursales ?? this.todasSucursales,
    arqueos: arqueos ?? this.arqueos,
    traspasos: traspasos ?? this.traspasos,
    cajaFuerte: cajaFuerte ?? this.cajaFuerte,
    cheques: cheques ?? this.cheques,
    tareas: tareas ?? this.tareas,
    guardando: guardando ?? this.guardando,
    seccionesConfirmadas: seccionesConfirmadas ?? this.seccionesConfirmadas,
    cerrando: cerrando ?? this.cerrando,
    descargandoPdf: descargandoPdf ?? this.descargandoPdf,
    // mensajeError y aviso NO se arrastran: son de un solo uso. Con `??` un
    // error viejo reaparecería en la próxima lectura.
    mensajeError: mensajeError,
    aviso: aviso,
    cerradas: cerradas ?? this.cerradas,
  );
}

String _cuantos(int n, String uno, String varios) =>
    n == 1 ? '1 $uno' : '$n $varios';

class CierreOperacionesNotifier extends StateNotifier<CierreOperacionesState> {
  final CierreOperacionesRepository _repo;
  final AperturaCierre apertura;

  CierreOperacionesNotifier(this._repo, this.apertura)
    : super(CierreOperacionesState.inicial(apertura)) {
    Future.microtask(cargar);
  }

  int get _id => apertura.idBitTarea;

  /// Las secciones que dependen de la sucursal, o sea las que cambia el
  /// interruptor "todas las sucursales".
  static bool _porSucursal(PanelCierre p) =>
      p == PanelCierre.arqueos ||
      p == PanelCierre.cajaFuerte ||
      p == PanelCierre.tareas;

  Future<void> cargar() => _leer(state.paneles, limpiar: false);

  Future<void> recargar(PanelCierre panel) => _leer([panel], limpiar: false);

  /// El "Desplegar" con otra fecha del sistema anterior.
  Future<void> cambiarFecha(DateTime fecha) async {
    final dia = _dia(fecha);
    if (dia == state.fecha) return;
    // Lo revisado era lo del día anterior.
    state = state.copyWith(fecha: dia, seccionesConfirmadas: const {});
    await _leer(state.paneles, limpiar: true);
  }

  /// El checkbox "Mostrar otras sucursales" (chkSuc del sistema anterior).
  Future<void> alternarTodasSucursales(bool todas) async {
    if (todas == state.todasSucursales) return;
    state = state.copyWith(
      todasSucursales: todas,
      seccionesConfirmadas:
          {...state.seccionesConfirmadas}..removeWhere(_porSucursal),
    );
    await _leer(state.paneles.where(_porSucursal).toList(), limpiar: true);
  }

  /// Da una sección por revisada (o le quita la marca). Solo las que no tienen
  /// filas para marcar.
  void confirmarSeccion(PanelCierre panel, bool revisada) {
    if (!state.necesitaConfirmacion(panel)) return;
    final confirmadas = {...state.seccionesConfirmadas};
    if (revisada) {
      confirmadas.add(panel);
    } else {
      confirmadas.remove(panel);
    }
    state = state.copyWith(seccionesConfirmadas: confirmadas);
  }

  Future<void> _leer(List<PanelCierre> paneles, {required bool limpiar}) =>
      Future.wait([for (final p in paneles) _leerUno(p, limpiar: limpiar)]);

  Future<void> _leerUno(PanelCierre panel, {required bool limpiar}) {
    final fecha = state.fecha;
    final todas = state.todasSucursales;
    return switch (panel) {
      PanelCierre.arqueos => _leerPanel<ArqueoDelCierre>(
        panel,
        limpiar: limpiar,
        de: (s) => s.arqueos,
        con: (s, p) => s.copyWith(arqueos: p),
        leer: () => _repo.arqueos(_id, fecha: fecha, todasSucursales: todas),
      ),
      PanelCierre.traspasos => _leerPanel<TraspasoMovCajaEntity>(
        panel,
        limpiar: limpiar,
        de: (s) => s.traspasos,
        con: (s, p) => s.copyWith(traspasos: p),
        leer: () => _repo.traspasos(fecha: fecha),
      ),
      PanelCierre.cajaFuerte => _leerPanel<LlegadaDelCierre>(
        panel,
        limpiar: limpiar,
        de: (s) => s.cajaFuerte,
        con: (s, p) => s.copyWith(cajaFuerte: p),
        leer: () => _repo.cajaFuerte(_id, fecha: fecha, todasSucursales: todas),
      ),
      PanelCierre.cheques => _leerPanel<ChequeDelCierre>(
        panel,
        limpiar: limpiar,
        de: (s) => s.cheques,
        con: (s, p) => s.copyWith(cheques: p),
        leer: () => _repo.cheques(_id, fecha: fecha),
      ),
      PanelCierre.tareas => _leerPanel<BitacoraCumplimientoEntity>(
        panel,
        limpiar: limpiar,
        de: (s) => s.tareas,
        con: (s, p) => s.copyWith(tareas: p),
        leer: () => _repo.tareas(_id, fecha: fecha, todasSucursales: todas),
      ),
    };
  }

  Future<void> _leerPanel<T>(
    PanelCierre panel, {
    required bool limpiar,
    required PanelDatos<T> Function(CierreOperacionesState) de,
    required CierreOperacionesState Function(
      CierreOperacionesState,
      PanelDatos<T>,
    )
    con,
    required Future<List<T>> Function() leer,
  }) async {
    final fecha = state.fecha;
    final todas = state.todasSucursales;
    // Una respuesta que llega tarde, cuando ya se cambió de día o de alcance,
    // se descarta: si no, la lista diría un día y el encabezado otro.
    bool vigente() =>
        mounted &&
        state.fecha == fecha &&
        (!_porSucursal(panel) || state.todasSucursales == todas);

    // Releer una sección deja sin efecto lo que se dio por revisado en ella:
    // puede haber llegado algo nuevo.
    state = con(
      state.copyWith(
        seccionesConfirmadas:
            {...state.seccionesConfirmadas}..remove(panel),
      ),
      de(state).leyendo(limpiar: limpiar),
    );
    try {
      final filas = await leer();
      if (vigente()) {
        state = con(state, PanelDatos<T>(filas: filas, cargado: true));
      }
    } catch (e) {
      if (vigente()) state = con(state, PanelDatos<T>(error: e));
    }
  }

  /// El visto bueno a un arqueo.
  Future<void> marcarArqueoRevisado(int idAC) async {
    final clave = 'arqueo:$idAC';
    if (state.guardando.contains(clave)) return;
    state = state.copyWith(guardando: {...state.guardando, clave});
    try {
      await _repo.marcarArqueoRevisado(idAC, idBitTarea: _id);
      if (!mounted) return;
      state = state.copyWith(
        guardando: _sin(clave),
        arqueos: state.arqueos.conFilas([
          for (final a in state.arqueos.filas)
            a.idAC == idAC ? a.comoRevisado() : a,
        ]),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        guardando: _sin(clave),
        mensajeError: textoParaUsuario(e),
      );
    }
  }

  /// La verificación de una llegada a caja fuerte.
  Future<void> marcarLlegadaVerificada(int idRp) async {
    final clave = 'llegada:$idRp';
    if (state.guardando.contains(clave)) return;
    state = state.copyWith(guardando: {...state.guardando, clave});
    try {
      await _repo.marcarLlegadaVerificada(idRp, idBitTarea: _id);
      if (!mounted) return;
      state = state.copyWith(
        guardando: _sin(clave),
        cajaFuerte: state.cajaFuerte.conFilas([
          for (final l in state.cajaFuerte.filas)
            l.idRp == idRp ? l.comoVerificada() : l,
        ]),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        guardando: _sin(clave),
        mensajeError: textoParaUsuario(e),
      );
    }
  }

  Future<void> cerrar() async {
    if (!state.puedeCerrar) return;
    state = state.copyWith(cerrando: true);
    try {
      final cantidad = await _repo.cerrar(
        _id,
        modo: state.modo,
        fecha: state.fechaOcurrencia,
      );
      if (!mounted) return;
      state = state.copyWith(cerrando: false, cerradas: cantidad);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cerrando: false, mensajeError: textoParaUsuario(e));
    }
  }

  /// El PDF consolidado del día (RptCierreOperaciones).
  Future<Uint8List?> pdfCierre() => _pdf(
    () => _repo.pdfCierre(
      _id,
      fecha: state.fecha,
      todasSucursales: state.todasSucursales,
    ),
  );

  /// El PDF de caja fuerte (RptCajaFuerteCO).
  Future<Uint8List?> pdfCajaFuerte() => _pdf(
    () => _repo.pdfCajaFuerte(
      _id,
      fecha: state.fecha,
      todasSucursales: state.todasSucursales,
    ),
  );

  /// El comprobante de un arqueo (RptArqueoDeCaja).
  Future<Uint8List?> pdfArqueo(int idAC) => _pdf(() => _repo.pdfArqueo(idAC));

  Future<Uint8List?> _pdf(Future<Uint8List> Function() generar) async {
    if (state.descargandoPdf) return null;
    state = state.copyWith(descargandoPdf: true);
    try {
      final bytes = await generar();
      if (mounted) state = state.copyWith(descargandoPdf: false);
      return bytes;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          descargandoPdf: false,
          mensajeError: textoParaUsuario(e),
        );
      }
      return null;
    }
  }

  Set<String> _sin(String clave) => {...state.guardando}..remove(clave);
}

/// Se expone para poder reemplazarlo en las pruebas.
final cierreOperacionesRepoProvider = Provider<CierreOperacionesRepository>(
  (ref) => CierreOperacionesImpl(),
);

/// `family` por apertura: la ocurrencia, el modo y su día.
final cierreOperacionesProvider = StateNotifierProvider.autoDispose.family<
  CierreOperacionesNotifier,
  CierreOperacionesState,
  AperturaCierre
>(
  (ref, apertura) => CierreOperacionesNotifier(
    ref.read(cierreOperacionesRepoProvider),
    apertura,
  ),
);
