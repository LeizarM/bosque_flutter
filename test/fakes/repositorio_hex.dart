// Repositorios falsos del módulo Horas Extras y datos de ejemplo: sin backend
// ni login. Guardan cada llamada con sus argumentos y responden lo programado
// (un valor o una excepción, por ejemplo un `ErrorHex`) o los datos de abajo.
import 'dart:async';
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_jornada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_segmento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_asignacion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GUION: REGISTRO DE LLAMADAS Y RESPUESTAS PROGRAMADAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una llamada a un falso: el nombre del método y sus argumentos.
typedef LlamadaHex = ({String metodo, Map<String, Object?> args});

/// Registro y guion que comparten los tres falsos. [programar] fija las
/// respuestas de un método en orden; la última se repite. Una respuesta que
/// no es del tipo del método se lanza (así se programa un `ErrorHex`).
mixin GuionHex {
  final List<LlamadaHex> llamadas = [];
  final Map<String, List<Object?>> _guion = {};

  /// Si no es nulo, cada escritura espera a que se complete antes de
  /// responder: deja una escritura «en curso» para probar el doble toque.
  Completer<void>? pausa;

  void programar(String metodo, List<Object?> respuestas) {
    assert(respuestas.isNotEmpty, 'Programa al menos una respuesta.');
    _guion[metodo] = [...respuestas];
  }

  /// Los argumentos de cada llamada a [metodo], en orden.
  List<Map<String, Object?>> argumentosDe(String metodo) => [
    for (final l in llamadas)
      if (l.metodo == metodo) l.args,
  ];

  int vecesDe(String metodo) => argumentosDe(metodo).length;

  Future<T> _leer<T>(
    String metodo,
    Map<String, Object?> args,
    T Function() porDefecto,
  ) async {
    llamadas.add((metodo: metodo, args: args));
    return _responder(metodo, porDefecto);
  }

  Future<HexRespuesta> _escribir(
    String metodo,
    Map<String, Object?> args,
  ) async {
    llamadas.add((metodo: metodo, args: args));
    final espera = pausa;
    if (espera != null) await espera.future;
    return _responder<HexRespuesta>(
      metodo,
      () => (id: BigInt.one, mensaje: 'Listo.'),
    );
  }

  T _responder<T>(String metodo, T Function() porDefecto) {
    final cola = _guion[metodo];
    if (cola == null) return porDefecto();
    final r = cola.length > 1 ? cola.removeAt(0) : cola.first;
    if (r is T) return r;
    if (r is Exception || r is Error) throw r!;
    // Ni del tipo del método ni una excepción: un error de la prueba.
    throw StateError(
      'programar("$metodo"): ${r == null ? 'null' : r.runtimeType} no es una '
      'respuesta válida; se esperaba $T o una excepción.',
    );
  }
}

/// Una página como la del servidor: filtra por estado y recorta.
PaginaHex<HexReporteEntity> _pagina(FiltroReportesHex f) {
  final todas = [
    for (final r in reportesFalsos)
      if (f.estado == null || r.estado == f.estado) r,
  ];
  final desde = ((f.pagina - 1) * f.tamano).clamp(0, todas.length);
  final hasta = (desde + f.tamano).clamp(0, todas.length);
  return (filas: todas.sublist(desde, hasta), total: todas.length);
}

// ═══════════════════════════════════════════════════════════════════════════
// FALSOS
// ═══════════════════════════════════════════════════════════════════════════

class HexReporteFalso with GuionHex implements HexReporteRepository {
  @override
  Future<HexLeyendaCodigosEntity?> leyendaCodigos() => _leer(
    'leyendaCodigos',
    const {},
    () => HexLeyendaCodigosEntity(
      tramos: tramosFalsos.where((t) => t.esVigente).toList(),
      comidas: comidasFalsas.where((c) => c.esVigente).toList(),
    ),
  );

  @override
  Future<PaginaHex<HexReporteEntity>> misReportes(FiltroReportesHex f) =>
      _leer('misReportes', {'filtro': f}, () => _pagina(f));

  @override
  Future<HexRespuesta> marcar({
    required String tipoMarca,
    required PosicionHex posicion,
  }) => _escribir('marcar', {'tipoMarca': tipoMarca, 'posicion': posicion});

  @override
  Future<HexVistaMarcacionEntity?> hoy() =>
      _leer('hoy', const {}, () => vistaMarcacionFalsa);

  @override
  Future<HexRespuesta> actualizar({
    required BigInt idReporte,
    String? motivo,
  }) => _escribir('actualizar', {'idReporte': idReporte, 'motivo': motivo});

  @override
  Future<HexRespuesta> anular({
    required BigInt idReporte,
    String? observacion,
  }) =>
      _escribir('anular', {'idReporte': idReporte, 'observacion': observacion});

  @override
  Future<HexReporteEntity?> detalle(BigInt idReporte) => _leer(
    'detalle',
    {'idReporte': idReporte},
    () => reportesFalsos.where((r) => r.idReporte == idReporte).firstOrNull,
  );

  @override
  Future<List<HexRequisitoMarcaEntity>> requisitosMarca() =>
      _leer('requisitosMarca', const {}, () => requisitosFalsos);

  @override
  Future<List<HexReporteLineaEntity>> lineas(BigInt idReporte) => _leer(
    'lineas',
    {'idReporte': idReporte},
    () => lineasFalsas.where((l) => l.idReporte == idReporte).toList(),
  );

  @override
  Future<List<HexReporteTramoEntity>> tramos(BigInt idReporte) => _leer(
    'tramos',
    {'idReporte': idReporte},
    () => tramosReporteFalsos[idReporte] ?? const [],
  );

  @override
  Future<List<HexReporteEventoEntity>> historial(BigInt idReporte) => _leer(
    'historial',
    {'idReporte': idReporte},
    () => historialesFalsos[idReporte] ?? const [],
  );

  @override
  Future<HexRolesEntity?> misRoles() => _leer(
    'misRoles',
    const {},
    () =>
        const HexRolesEntity(esEncargado: true, esJefe: true, sucursales: '1'),
  );

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaEncargado(FiltroReportesHex f) =>
      _leer('bandejaEncargado', {'filtro': f}, () => _pagina(f));

  @override
  Future<HexRespuesta> corregirHora({
    required BigInt idReporte,
    DateTime? inicio,
    DateTime? fin,
    required String observacion,
  }) => _escribir('corregirHora', {
    'idReporte': idReporte,
    'inicio': inicio,
    'fin': fin,
    'observacion': observacion,
  });

  @override
  Future<HexRespuesta> vistoBueno({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  }) => _escribir('vistoBueno', {
    'idReporte': idReporte,
    'observacion': observacion,
    // Como el cuerpo real: `confirmado` solo en el reenvío (adenda D37).
    if (confirmado) 'confirmado': true,
  });

  @override
  Future<HexRespuesta> rechazarEncargado({
    required BigInt idReporte,
    required String observacion,
  }) => _escribir('rechazarEncargado', {
    'idReporte': idReporte,
    'observacion': observacion,
  });

  /// D43: por defecto ninguna (el 204): la revisión no muestra el botón.
  @override
  Future<List<HexJornadaPasadaEntity>> jornadasPasadas() =>
      _leer('jornadasPasadas', const {}, () => const []);

  @override
  Future<HexRespuesta> crearReportePasado(HexReportePasadoEntity reporte) =>
      _escribir('crearReportePasado', {
        'codEmpleado': reporte.codEmpleado,
        'fechaJornada': reporte.fechaJornada,
        'inicio': reporte.inicio,
        'fin': reporte.fin,
        'observacion': reporte.observacion,
      });

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaJefe(FiltroReportesHex f) =>
      _leer('bandejaJefe', {'filtro': f}, () => _pagina(f));

  /// D45: como la del jefe, de todos los estados si el filtro no trae uno.
  @override
  Future<PaginaHex<HexReporteEntity>> bandejaObservador(FiltroReportesHex f) =>
      _leer('bandejaObservador', {'filtro': f}, () => _pagina(f));

  @override
  Future<HexRespuesta> aprobar({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  }) => _escribir('aprobar', {
    'idReporte': idReporte,
    'observacion': observacion,
    // Como el cuerpo real: `confirmado` solo en el reenvío (adenda D37).
    if (confirmado) 'confirmado': true,
  });

  @override
  Future<HexRespuesta> aprobarGrupo({
    required BigInt codEncargado,
    required int anio,
    required int mes,
    String? observacion,
  }) => _escribir('aprobarGrupo', {
    'codEncargado': codEncargado,
    'anio': anio,
    'mes': mes,
    'observacion': observacion,
  });

  @override
  Future<HexRespuesta> rechazarJefe({
    required BigInt idReporte,
    required String observacion,
  }) => _escribir('rechazarJefe', {
    'idReporte': idReporte,
    'observacion': observacion,
  });
}

class HexPlanillaFalso with GuionHex implements HexPlanillaRepository {
  @override
  Future<List<HexPlanillaEntity>> planillas({BigInt? idPlanilla}) => _leer(
    'planillas',
    {'idPlanilla': idPlanilla},
    () => [
      for (final p in planillasFalsas)
        if (idPlanilla == null || p.idPlanilla == idPlanilla) p,
    ],
  );

  @override
  Future<List<HexPendienteEntity>> pendientes() =>
      _leer('pendientes', const {}, () => const []);

  @override
  Future<List<HexPrevistaEmpleadoEntity>> vistaPrevia(CombinacionHex c) =>
      _leer('vistaPrevia', {'combinacion': c}, () => const []);

  @override
  Future<List<HexPrevistaLineaEntity>> vistaPreviaLineas(CombinacionHex c) =>
      _leer('vistaPreviaLineas', {'combinacion': c}, () => const []);

  @override
  Future<List<HexAvisoEntity>> avisos(CombinacionHex c) =>
      _leer('avisos', {'combinacion': c}, () => const []);

  @override
  Future<HexRespuesta> ejecutar(CombinacionHex c, {String? observacion}) =>
      _escribir('ejecutar', {'combinacion': c, 'observacion': observacion});

  @override
  Future<List<HexPlanillaEmpleadoEntity>> empleados(BigInt idPlanilla) =>
      _leer('empleados', {'idPlanilla': idPlanilla}, () => const []);

  @override
  Future<List<HexPlanillaDetalleEntity>> detalle(
    BigInt idPlanilla, {
    BigInt? codEmpleado,
  }) => _leer('detalle', {
    'idPlanilla': idPlanilla,
    'codEmpleado': codEmpleado,
  }, () => const []);

  @override
  Future<List<HexCodigoLeyendaEntity>> leyenda(BigInt idPlanilla) =>
      _leer('leyenda', {'idPlanilla': idPlanilla}, () => const []);

  /// La cabecera de un PDF: suficiente para el visor, sin generar nada.
  @override
  Future<Uint8List> pdf(BigInt idPlanilla) => _leer('pdf', {
    'idPlanilla': idPlanilla,
  }, () => Uint8List.fromList('%PDF-1.4'.codeUnits));

  @override
  Future<HexRespuesta> anular(BigInt idPlanilla, String observacion) =>
      _escribir('anular', {
        'idPlanilla': idPlanilla,
        'observacion': observacion,
      });

  @override
  Future<List<HexPlanillaFirmaEntity>> pendientesFirma(CombinacionHex c) =>
      _leer('pendientesFirma', {'combinacion': c}, () => const []);

  @override
  Future<HexRespuesta> ejecutarLote(int anio, int mes, {String? observacion}) =>
      _escribir('ejecutarLote', {
        'anio': anio,
        'mes': mes,
        'observacion': observacion,
      });

  @override
  Future<HexRespuesta> anularLote(BigInt idLote, String observacion) =>
      _escribir('anularLote', {'idLote': idLote, 'observacion': observacion});

  @override
  Future<Uint8List> pdfLote(BigInt idLote) => _leer('pdfLote', {
    'idLote': idLote,
  }, () => Uint8List.fromList('%PDF-1.4'.codeUnits));
}

/// Asignación de horas extra (D37): por defecto, [asignablesFalsos] y
/// [asignacionesFalsas].
class HexAsignacionFalso with GuionHex implements HexAsignacionRepository {
  @override
  Future<List<HexAsignableEntity>> asignables(DateTime? fechaJornada) => _leer(
    'asignables',
    {'fechaJornada': fechaJornada},
    () => asignablesFalsos,
  );

  @override
  Future<HexRespuesta> asignar({
    required List<BigInt> codEmpleados,
    required DateTime fechaJornada,
    required String motivo,
    bool confirmado = false,
  }) => _escribir('asignar', {
    'codEmpleados': codEmpleados,
    'fechaJornada': fechaJornada,
    'motivo': motivo,
    'confirmado': confirmado,
  });

  @override
  Future<HexRespuesta> quitar({
    required BigInt idAsignacion,
    String? observacion,
  }) => _escribir('quitar', {
    'idAsignacion': idAsignacion,
    'observacion': observacion,
  });

  @override
  Future<PaginaHex<HexAsignacionEntity>> historial(FiltroAsignacionesHex f) =>
      _leer('historial', {'filtro': f}, () {
        final todas = [
          for (final a in asignacionesFalsas)
            if (f.estado == null || a.estado == f.estado) a,
        ];
        return (filas: todas, total: todas.length);
      });

  /// Por defecto sin faltas (el 204): la bandeja de revisión no las muestra.
  @override
  Future<List<HexAsignacionFaltaEntity>> faltas({DateTime? desde}) =>
      _leer('faltas', {'desde': desde}, () => const []);
}

class HexConfiguracionFalso
    with GuionHex
    implements HexConfiguracionRepository {
  @override
  Future<List<HexParametroEntity>> parametros({String? clave}) => _leer(
    'parametros',
    {'clave': clave},
    () => [
      for (final p in parametrosFalsos)
        if (clave == null || p.clave == clave) p,
    ],
  );

  @override
  Future<HexRespuesta> nuevaVigenciaParametro(HexParametroEntity p) =>
      _escribir('nuevaVigenciaParametro', {'parametro': p});

  @override
  Future<HexRespuesta> editarLeyendaParametro(BigInt id, String leyenda) =>
      _escribir('editarLeyendaParametro', {'id': id, 'leyenda': leyenda});

  @override
  Future<HexRespuesta> eliminarParametro(BigInt id) =>
      _escribir('eliminarParametro', {'id': id});

  @override
  Future<List<HexParametroClaveEntity>> catalogoParametros() =>
      _leer('catalogoParametros', const {}, () => catalogoFalso);

  /// Por defecto, las empresas con organigrama como las devuelve el SP.
  @override
  Future<List<HexParametroOpcionEntity>> opcionesParametro(String clave) =>
      _leer('opcionesParametro', {'clave': clave}, () => opcionesFalsas);

  @override
  Future<HexRespuesta> dejarDeUsarParametro(
    BigInt idParametro,
    DateTime sinUsoDesde,
  ) => _escribir('dejarDeUsarParametro', {
    'idParametro': idParametro,
    'sinUsoDesde': sinUsoDesde,
  });

  @override
  Future<List<HexTramoEntity>> tramos({String? tipoDia, String? codigo}) =>
      _leer(
        'tramos',
        {'tipoDia': tipoDia, 'codigo': codigo},
        () => [
          for (final t in tramosFalsos)
            if ((tipoDia == null || t.tipoDia == tipoDia) &&
                (codigo == null || t.codigo == codigo))
              t,
        ],
      );

  @override
  Future<HexRespuesta> nuevaVigenciaTramo(
    HexTramoEntity t, {
    bool confirmado = false,
  }) => _escribir('nuevaVigenciaTramo', {'tramo': t, 'confirmado': confirmado});

  /// Por defecto, el mapa de hoy con el hueco de 20:00 a 20:01; con una
  /// propuesta completa, el día hábil sin hueco y la propuesta marcada.
  @override
  Future<List<HexTramoMapaEntity>> mapaTramos({
    String? tipoDia,
    DateTime? fecha,
    String? codigo,
    String? horaDesde,
    String? horaHasta,
  }) {
    final conPropuesta =
        codigo != null && horaDesde != null && horaHasta != null;
    return _leer(
      'mapaTramos',
      {
        'tipoDia': tipoDia,
        'fecha': fecha,
        'codigo': codigo,
        'horaDesde': horaDesde,
        'horaHasta': horaHasta,
      },
      () => [
        for (final m
            in conPropuesta ? mapaTramosPropuestoFalso : mapaTramosFalso)
          if (tipoDia == null || m.tipoDia == tipoDia) m,
      ],
    );
  }

  /// Por defecto, el caso de Manuel: 15:00–21:36 con cena, 149,40 Bs.
  @override
  Future<HexSimulacionEntity> simularJornada({
    required BigInt codEmpleado,
    required DateTime fechaJornada,
    DateTime? inicio,
    DateTime? fin,
  }) => _leer('simularJornada', {
    'codEmpleado': codEmpleado,
    'fechaJornada': fechaJornada,
    'inicio': inicio,
    'fin': fin,
  }, () => simulacionManuelFalsa);

  @override
  Future<HexRespuesta> editarLeyendaTramo(BigInt id, String leyenda) =>
      _escribir('editarLeyendaTramo', {'id': id, 'leyenda': leyenda});

  @override
  Future<HexRespuesta> eliminarTramo(BigInt id) =>
      _escribir('eliminarTramo', {'id': id});

  @override
  Future<List<HexComidaEntity>> comidas({String? codigo}) => _leer(
    'comidas',
    {'codigo': codigo},
    () => [
      for (final c in comidasFalsas)
        if (codigo == null || c.codigo == codigo) c,
    ],
  );

  @override
  Future<HexRespuesta> nuevaVigenciaComida(HexComidaEntity c) =>
      _escribir('nuevaVigenciaComida', {'comida': c});

  @override
  Future<HexRespuesta> periodoComida(HexComidaEntity c, {DateTime? hasta}) =>
      _escribir('periodoComida', {'comida': c, 'hasta': hasta});

  @override
  Future<HexRespuesta> editarLeyendaComida(
    BigInt id, {
    String? leyenda,
    String? leyendaDoble,
  }) => _escribir('editarLeyendaComida', {
    'id': id,
    'leyenda': leyenda,
    'leyendaDoble': leyendaDoble,
  });

  @override
  Future<HexRespuesta> eliminarComida(BigInt id) =>
      _escribir('eliminarComida', {'id': id});

  @override
  Future<List<HexAprobadorEntity>> aprobadores({
    BigInt? codEmpleado,
    int? nivel,
  }) => _leer(
    'aprobadores',
    {'codEmpleado': codEmpleado, 'nivel': nivel},
    () => [
      for (final a in aprobadoresFalsos)
        if ((codEmpleado == null || a.codEmpleadoAprobador == codEmpleado) &&
            (nivel == null || a.nivel == nivel))
          a,
    ],
  );

  @override
  Future<List<HexRamaEmpleadoEntity>> ramaAprobador(BigInt codEmpleado) =>
      _leer('ramaAprobador', {'codEmpleado': codEmpleado}, () => ramaFalsa);

  @override
  Future<List<HexEncargadoOpcionEntity>> encargadosParaJefe() =>
      _leer('encargadosParaJefe', const {}, () => encargadosFalsos);

  @override
  Future<HexRespuesta> asignarAprobador(HexAprobadorEntity a) =>
      _escribir('asignarAprobador', {'aprobador': a});

  @override
  Future<HexRespuesta> cerrarAprobador(BigInt id, {DateTime? vigenteHasta}) =>
      _escribir('cerrarAprobador', {'id': id, 'vigenteHasta': vigenteHasta});

  @override
  Future<HexRespuesta> eliminarAprobador(BigInt id) =>
      _escribir('eliminarAprobador', {'id': id});

  /// Como el SP: la entidad (y el registro, si viene) y la página pedida.
  @override
  Future<PaginaHex<HexConfiguracionEventoEntity>> historial(
    FiltroHistorialHex f,
  ) => _leer('historial', {'filtro': f}, () {
    final todas = [
      for (final e in historialConfiguracionFalso)
        if (e.entidad == f.entidad &&
            (f.idRegistro == null || e.idRegistro == f.idRegistro))
          e,
    ];
    final desde = ((f.pagina - 1) * f.tamano).clamp(0, todas.length);
    final hasta = (desde + f.tamano).clamp(0, todas.length);
    return (filas: todas.sublist(desde, hasta), total: todas.length);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DE EJEMPLO (los de `sql/datos/01_thex_parametros_iniciales.sql`)
// ═══════════════════════════════════════════════════════════════════════════

final DateTime _desde2026 = DateTime(2026, 1, 1);

/// `reporte/hoy` con una asignación activa y las dos teclas habilitadas.
final vistaMarcacionFalsa = HexVistaMarcacionEntity(
  vistaHabilitada: true,
  textoVista:
      'ROJAS VARGAS LUIS te asignó horas extra para la jornada del '
      '23/10/2026.',
  fechaJornadaAsignada: DateTime(2026, 10, 23),
  idAsignacion: BigInt.from(12),
  nombreAsignador: 'Rojas Vargas Luis',
  puedeMarcarEntrada: true,
  textoMarcarEntrada: 'Puedes marcar tu entrada antes de tu horario.',
  puedeMarcarSalida: true,
  textoMarcarSalida: 'Puedes marcar tu salida hasta las 06:00.',
  fechaJornadaSalida: DateTime(2026, 10, 23),
  tipoSalida: 'DESPUES',
  motivoAsignacion: 'Inventario de fin de mes',
);

/// Tres asignables: uno libre, uno con aviso de vacación y uno ya asignado
/// con reporte vivo (no se puede quitar).
final asignablesFalsos = <HexAsignableEntity>[
  HexAsignableEntity(
    codEmpleado: BigInt.from(191),
    nombreEmpleado: 'Apaza Mamani Pedro',
    cargo: 'Operario de planta',
    nombreSucursal: 'Planta El Alto',
    fechaJornada: DateTime(2026, 11, 5),
    puedeAsignar: true,
    textoEstado: 'Sin asignar',
  ),
  HexAsignableEntity(
    codEmpleado: BigInt.from(203),
    nombreEmpleado: 'Mamani Sossa Rosa',
    cargo: 'Operaria de planta',
    nombreSucursal: 'Planta El Alto',
    fechaJornada: DateTime(2026, 11, 5),
    tipoAviso: 'VACACION',
    aviso: 'MAMANI SOSSA está de vacaciones el 05/11/2026',
    puedeAsignar: true,
    textoEstado: 'Sin asignar',
  ),
  HexAsignableEntity(
    codEmpleado: BigInt.from(204),
    nombreEmpleado: 'Quispe Limachi Juan',
    cargo: 'Montacarguista',
    nombreSucursal: 'Planta El Alto',
    fechaJornada: DateTime(2026, 11, 5),
    idAsignacion: BigInt.from(30),
    estaAsignado: true,
    nombreAsignador: 'Rojas Vargas Luis',
    cantidadReportes: 1,
    idReporte: BigInt.from(101),
    estadoReporte: 'REPORTADO',
    estadoReporteTexto: 'Reportado',
    textoEstado: 'Asignado por Rojas Vargas Luis',
    motivo: 'Descarga de contenedor',
  ),
];

/// Una asignación activa que se puede quitar y una ya quitada.
final asignacionesFalsas = <HexAsignacionEntity>[
  HexAsignacionEntity(
    idAsignacion: BigInt.from(31),
    codEmpleado: BigInt.from(191),
    nombreEmpleado: 'Apaza Mamani Pedro',
    fechaJornada: DateTime(2026, 11, 5),
    estado: 'ACTIVA',
    estadoTexto: 'Asignada',
    nombreAsignador: 'Rojas Vargas Luis',
    motivo: 'Inventario de fin de mes',
    fechaAsignacion: DateTime(2026, 11, 4, 17, 30),
    puedeQuitar: true,
    totalFilas: 2,
  ),
  HexAsignacionEntity(
    idAsignacion: BigInt.from(28),
    codEmpleado: BigInt.from(203),
    nombreEmpleado: 'Mamani Sossa Rosa',
    fechaJornada: DateTime(2026, 11, 3),
    estado: 'QUITADA',
    estadoTexto: 'Quitada',
    nombreAsignador: 'Rojas Vargas Luis',
    motivo: 'Carga de camión a Santa Cruz',
    fechaAsignacion: DateTime(2026, 11, 2, 16),
    fechaQuitada: DateTime(2026, 11, 3, 9, 15),
    nombreQuita: 'Rojas Vargas Luis',
    totalFilas: 2,
  ),
];
final BigInt _sucursal = BigInt.one;

/// Los cuatro requisitos de `p_list_thex_Reporte` S, todos cumplidos.
const requisitosFalsos = <HexRequisitoMarcaEntity>[
  HexRequisitoMarcaEntity(
    requisito: 'RELACION',
    cumple: true,
    bloquea: true,
    titulo: 'Relación laboral activa',
    detalle: 'Activa desde el 01/03/2020',
    orden: 1,
  ),
  HexRequisitoMarcaEntity(
    requisito: 'CARGO',
    cumple: true,
    bloquea: true,
    titulo: 'Cargo con sucursal',
    detalle: 'Planta El Alto',
    orden: 2,
  ),
  HexRequisitoMarcaEntity(
    requisito: 'INICIO',
    cumple: true,
    bloquea: true,
    titulo: 'Módulo iniciado',
    detalle: 'Desde el 01/10/2026',
    orden: 3,
  ),
  HexRequisitoMarcaEntity(
    requisito: 'HORARIO',
    cumple: true,
    bloquea: true,
    titulo: 'Horario asignado en el biométrico',
    detalle: 'Hoy: 09:00 a 18:00',
    orden: 4,
  ),
];

/// Cuatro reportes con los casos que la UI distingue: cruce de medianoche,
/// monto provisional, hora editada, aviso de biométrico y una salida
/// pendiente de biométrico sin monto calculado.
final reportesFalsos = <HexReporteEntity>[
  HexReporteEntity(
    idReporte: BigInt.from(101),
    codEmpleado: BigInt.from(20),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 23),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    tipoDiaTexto: 'Hábil',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 23, 18),
    fin: DateTime(2026, 10, 24, 1, 30),
    origenInicio: 'HORARIO',
    origenFin: 'BIOMETRICO',
    motivo: 'Descarga de bobinas del contenedor 14.',
    horasPagables: 7.5,
    montoHoras: 1234.5,
    montoComidas: 30,
    montoTotal: 1264.5,
    comidas: 'C,DC',
    costoHora: 20,
    verMontos: true,
    puedeVerDetalle: true,
    verHistorial: true,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    puedeAnular: true,
    puedeEditarMotivo: true,
    totalFilas: 4,
    textoPendiente: 'Espera el visto bueno de Rojas Vargas Luis',
  ),
  HexReporteEntity(
    idReporte: BigInt.from(102),
    codEmpleado: BigInt.from(21),
    nombreEmpleado: 'Condori Huanca María Fernanda de los Ángeles',
    fechaJornada: DateTime(2026, 10, 25),
    tipo: 'SIN_HORARIO',
    tipoTexto: 'Sin horario',
    tipoDia: 'DOMINGO',
    tipoDiaTexto: 'Domingo',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 25, 8),
    fin: DateTime(2026, 10, 25, 11),
    origenInicio: 'APP',
    origenFin: 'EDITADO',
    motivo: 'Inventario de fin de mes en el depósito central.',
    horasPagables: 3,
    montoHoras: 120,
    montoComidas: 0,
    montoTotal: 120,
    costoHora: 20,
    verMontos: true,
    puedeVerDetalle: true,
    verHistorial: true,
    esProvisional: true,
    estado: 'VISTO_BUENO',
    estadoTexto: 'Con visto bueno',
    esEditado: true,
    avisoBiometrico: true,
    puedeAprobar: true,
    puedeRechazar: true,
    totalFilas: 4,
    codEncargado: BigInt.from(7),
    nombreEncargado: 'Rojas Vargas Luis',
  ),
  HexReporteEntity(
    idReporte: BigInt.from(103),
    codEmpleado: BigInt.from(22),
    nombreEmpleado: 'Choque Flores Pedro',
    fechaJornada: DateTime(2026, 10, 12),
    tipo: 'ANTES',
    tipoTexto: 'Antes del horario',
    tipoDia: 'FERIADO',
    tipoDiaTexto: 'Feriado',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 12, 5, 30),
    fin: DateTime(2026, 10, 12, 8),
    origenInicio: 'EDITADO',
    origenFin: 'HORARIO',
    horasPagables: 2.5,
    montoHoras: 100,
    montoComidas: 10,
    montoTotal: 110,
    comidas: 'D',
    costoHora: 20,
    verMontos: true,
    puedeVerDetalle: true,
    verHistorial: true,
    estado: 'APROBADO',
    estadoTexto: 'Aprobado',
    esEditado: true,
    totalFilas: 4,
  ),
  HexReporteEntity(
    idReporte: BigInt.from(104),
    codEmpleado: BigInt.from(20),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 30),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    tipoDiaTexto: 'Hábil',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 30, 18),
    origenInicio: 'HORARIO',
    costoHora: 20,
    verMontos: true,
    puedeVerDetalle: true,
    verHistorial: true,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    puedeAnular: true,
    puedeEditarMotivo: true,
    totalFilas: 4,
  ),
];

/// Desglose del reporte de domingo (102) y del de día hábil (101).
final lineasFalsas = <HexReporteLineaEntity>[
  HexReporteLineaEntity(
    idReporte: BigInt.from(102),
    concepto: 'TRAMO',
    codigo: 'HD',
    leyenda: 'Hora doble de domingo',
    minutos: 180,
    cantidad: 3,
    multiplicador: 2,
    valorUnitario: 40,
    monto: 120,
  ),
  HexReporteLineaEntity(
    idReporte: BigInt.from(101),
    concepto: 'TRAMO',
    codigo: 'HS',
    leyenda: 'Hora extra simple',
    minutos: 120,
    cantidad: 2,
    multiplicador: 1,
    valorUnitario: 20,
    monto: 40,
  ),
  HexReporteLineaEntity(
    idReporte: BigInt.from(101),
    concepto: 'COMIDA',
    codigo: 'DC',
    leyenda: 'Doble cena',
    cantidad: 1,
    valorUnitario: 30,
    monto: 30,
  ),
];

/// Tramos por reporte (D36); ninguno por defecto: cada prueba los programa.
final tramosReporteFalsos = <BigInt, List<HexReporteTramoEntity>>{};

/// El ejemplo del usuario: 18:30 → 21:00 en día hábil con cena 18:00-20:00.
const resumenCenaD36 = '2 h 30 min en total (2 h con comida · 0,50 h pagadas)';
final tramosCenaD36 = <HexReporteTramoEntity>[
  HexReporteTramoEntity(
    orden: 1,
    desde: DateTime(2026, 10, 23, 18, 30),
    hasta: DateTime(2026, 10, 23, 19, 30),
    horaDesde: '18:30',
    horaHasta: '19:30',
    minutos: 60,
    duracionTexto: '1 h',
    clase: 'COMIDA',
    codigo: 'C',
    leyenda: 'Cena',
    textoPago: 'Gana la cena: se paga solo con la comida',
    resumen: resumenCenaD36,
  ),
  HexReporteTramoEntity(
    orden: 2,
    desde: DateTime(2026, 10, 23, 19, 30),
    hasta: DateTime(2026, 10, 23, 20, 30),
    horaDesde: '19:30',
    horaHasta: '20:30',
    minutos: 60,
    duracionTexto: '1 h',
    clase: 'COMIDA',
    codigo: 'DC',
    leyenda: 'Doble cena',
    textoPago: 'La cena pasa a doble cena: se paga solo con la comida',
    resumen: resumenCenaD36,
  ),
  HexReporteTramoEntity(
    orden: 3,
    desde: DateTime(2026, 10, 23, 20, 30),
    hasta: DateTime(2026, 10, 23, 21),
    horaDesde: '20:30',
    horaHasta: '21:00',
    minutos: 30,
    duracionTexto: '30 min',
    clase: 'HORA',
    codigo: 'H50',
    leyenda: 'Hora con recargo del 50 %',
    textoPago: 'Se paga como hora: ×1,5 (recargo del 50 %)',
    resumen: resumenCenaD36,
  ),
];

/// Historial por reporte (solo el 102 tiene), con los textos que arma el SP.
final historialesFalsos = <BigInt, List<HexReporteEventoEntity>>{
  BigInt.from(102): _historial102,
};

final _historial102 = <HexReporteEventoEntity>[
  HexReporteEventoEntity(
    idEvento: BigInt.from(1),
    tipo: 'MARCA_APP',
    tipoTexto: 'Marca por app',
    codEmpleadoActor: BigInt.from(21),
    nombreActor: 'Condori Huanca María Fernanda de los Ángeles',
    valorNuevo: 'Entrada por app: 25/10/2026 08:00',
    fecha: DateTime(2026, 10, 25, 8),
  ),
  HexReporteEventoEntity(
    idEvento: BigInt.from(2),
    tipo: 'EDICION',
    tipoTexto: 'Edición de hora',
    codEmpleadoActor: BigInt.from(7),
    nombreActor: 'Rojas Vargas Luis',
    valorAnterior: 'Fin: sin hora',
    valorNuevo: 'Fin: 25/10/2026 11:00 (EDITADO)',
    observacion: 'Salió a las 11:00; el biométrico no registró la salida.',
    fecha: DateTime(2026, 10, 26, 9, 15),
  ),
];

final planillasFalsas = <HexPlanillaEntity>[
  HexPlanillaEntity(
    idPlanilla: BigInt.from(5),
    codEmpresa: BigInt.from(2),
    anio: 2026,
    mes: 9,
    periodoTexto: 'Septiembre de 2026',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    estado: 'EJECUTADA',
    estadoTexto: 'Ejecutada',
    fechaEjecucion: DateTime(2026, 10, 3, 10, 20),
    codEmpleadoEjecutor: BigInt.from(30),
    nombreEjecutor: 'Gutiérrez Paz Ana',
    totalHoras: 8420.5,
    totalComidas: 615,
    total: 9035.5,
    cantidadEmpleados: 14,
    cantidadReportes: 37,
  ),
  HexPlanillaEntity(
    idPlanilla: BigInt.from(4),
    codEmpresa: BigInt.from(2),
    anio: 2026,
    mes: 8,
    periodoTexto: 'Agosto de 2026',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    estado: 'ANULADA',
    estadoTexto: 'Anulada',
    fechaEjecucion: DateTime(2026, 9, 2, 9),
    codEmpleadoEjecutor: BigInt.from(30),
    nombreEjecutor: 'Gutiérrez Paz Ana',
    totalHoras: 7100,
    totalComidas: 480,
    total: 7580,
    cantidadEmpleados: 12,
    cantidadReportes: 30,
    motivoAnulacion: 'Se ejecutó con el haber básico anterior.',
    fechaAnulacion: DateTime(2026, 9, 3, 16, 45),
    codEmpleadoAnulador: BigInt.from(31),
    nombreAnulador: 'Salazar Rivera Jorge',
  ),
];

/// La acción O de la empresa del organigrama: nombre y detalle del SP.
const opcionesFalsas = <HexParametroOpcionEntity>[
  HexParametroOpcionEntity(
    valor: 6,
    texto: 'GENERAL',
    detalle: 'Código 6 · 65 cargos en su organigrama',
  ),
  HexParametroOpcionEntity(
    valor: 1,
    texto: 'IMPEXPAP',
    detalle: 'Código 1 · 80 cargos en su organigrama',
  ),
];

/// El catálogo de `fun_thex_parametroClave` (D33), todo con valor vigente.
const catalogoFalso = <HexParametroClaveEntity>[
  HexParametroClaveEntity(
    clave: 'DIVISOR_COSTO_HORA',
    nombre: 'Divisor del costo hora',
    tipoValor: 'NUMERO',
    unidad: 'horas al mes',
    obligatorio: true,
    tieneVigente: true,
  ),
  HexParametroClaveEntity(
    clave: 'FECHA_INICIO_MODULO',
    nombre: 'Inicio del módulo',
    tipoValor: 'FECHA',
    obligatorio: true,
    tieneVigente: true,
  ),
  HexParametroClaveEntity(
    clave: 'MINUTOS_MINIMOS_EXTRA',
    nombre: 'Minutos mínimos para el reporte automático',
    tipoValor: 'NUMERO',
    unidad: 'minutos',
    tieneVigente: true,
  ),
  HexParametroClaveEntity(
    clave: 'MINUTOS_ALERTA_BIOMETRICO',
    nombre: 'Tolerancia entre la app y el biométrico',
    tipoValor: 'NUMERO',
    unidad: 'minutos',
  ),
];

final parametrosFalsos = <HexParametroEntity>[
  HexParametroEntity(
    idParametro: BigInt.one,
    clave: 'DIVISOR_COSTO_HORA',
    valorNumero: 240,
    leyenda: 'Divisor del costo hora (30 días × 8 h)',
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
  HexParametroEntity(
    idParametro: BigInt.two,
    clave: 'MINUTOS_MINIMOS_EXTRA',
    valorNumero: 15,
    leyenda: 'Minutos mínimos para que cuente una hora extra',
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
  HexParametroEntity(
    idParametro: BigInt.from(3),
    clave: 'FECHA_INICIO_MODULO',
    valorFecha: DateTime(2026, 11, 1),
    leyenda: 'Primer día que se reporta con el módulo',
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
  // Una vigencia ya cerrada: queda en la lista, sin «Vigente».
  HexParametroEntity(
    idParametro: BigInt.from(4),
    clave: 'DIVISOR_COSTO_HORA',
    valorNumero: 230,
    leyenda: 'Divisor anterior',
    vigenteDesde: DateTime(2025, 1, 1),
    vigenteHasta: DateTime(2025, 12, 31),
  ),
];

HexTramoEntity _tramo(
  int id,
  String codigo,
  String leyenda,
  String tipoDia,
  String desde,
  String hasta,
  double multiplicador,
  int orden,
) => HexTramoEntity(
  idTramo: BigInt.from(id),
  codigo: codigo,
  leyenda: leyenda,
  tipoDia: tipoDia,
  horaDesde: desde,
  horaHasta: hasta,
  multiplicador: multiplicador,
  orden: orden,
  vigenteDesde: _desde2026,
  esVigente: true,
);

/// Los cinco tramos vigentes; `00:00:00` como fin significa las 24:00.
final tramosFalsos = <HexTramoEntity>[
  _tramo(1, 'HS', 'Hora extra simple', 'HABIL', '06:00:00', '20:00:00', 1, 1),
  _tramo(
    2,
    'H50',
    'Hora extra con recargo del 50 %',
    'HABIL',
    '20:00:00',
    '00:00:00',
    1.5,
    2,
  ),
  _tramo(
    3,
    'H100',
    'Hora extra con recargo del 100 %',
    'HABIL',
    '00:00:00',
    '06:00:00',
    2,
    3,
  ),
  _tramo(
    4,
    'HD',
    'Hora doble de domingo',
    'DOMINGO',
    '00:00:00',
    '00:00:00',
    2,
    1,
  ),
  _tramo(
    5,
    'HF',
    'Hora doble de feriado',
    'FERIADO',
    '00:00:00',
    '00:00:00',
    2,
    1,
  ),
  // La vigencia anterior de H50, ya cerrada (la leyenda de códigos no la ve).
  HexTramoEntity(
    idTramo: BigInt.from(6),
    codigo: 'H50',
    leyenda: 'Hora al 50 %',
    tipoDia: 'HABIL',
    horaDesde: '20:00:00',
    horaHasta: '00:00:00',
    multiplicador: 1.25,
    orden: 2,
    vigenteDesde: DateTime(2025, 1, 1),
    vigenteHasta: DateTime(2025, 12, 31),
  ),
];

/// Las tres comidas; el almuerzo no tiene ventana y está inactivo.
final comidasFalsas = <HexComidaEntity>[
  HexComidaEntity(
    idComida: BigInt.from(1),
    codigo: 'D',
    leyenda: 'Desayuno',
    codigoDoble: 'DD',
    leyendaDoble: 'Doble desayuno',
    horaDesde: '06:00:00',
    horaHasta: '07:00:00',
    monto: 10,
    montoDoble: 20,
    orden: 1,
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
  HexComidaEntity(
    idComida: BigInt.from(2),
    codigo: 'A',
    leyenda: 'Almuerzo',
    codigoDoble: 'DA',
    leyendaDoble: 'Doble almuerzo',
    monto: 15,
    montoDoble: 30,
    activo: false,
    orden: 2,
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
  HexComidaEntity(
    idComida: BigInt.from(3),
    codigo: 'C',
    leyenda: 'Cena',
    codigoDoble: 'DC',
    leyendaDoble: 'Doble cena',
    horaDesde: '18:00:00',
    horaHasta: '20:00:00',
    monto: 15,
    montoDoble: 30,
    orden: 3,
    vigenteDesde: _desde2026,
    esVigente: true,
  ),
];

/// La bitácora de configuración (D22), del cambio más reciente al más antiguo;
/// el de la vigencia inicial de parámetros lo hizo un script.
final historialConfiguracionFalso = <HexConfiguracionEventoEntity>[
  HexConfiguracionEventoEntity(
    idEvento: BigInt.from(5),
    entidad: 'COMIDA',
    entidadTexto: 'Comida',
    idRegistro: BigInt.from(3),
    descripcion: 'C · Cena',
    accion: 'U',
    accionTexto: 'Leyenda editada',
    campo: 'leyendaDoble',
    campoTexto: 'Leyenda doble',
    valorAnterior: 'Cena doble',
    valorNuevo: 'Doble cena',
    audUsuario: BigInt.from(7),
    nombreUsuario: 'Salazar Rivera Jorge',
    audFecha: DateTime(2026, 10, 20, 9, 30),
    totalFilas: 1,
  ),
  HexConfiguracionEventoEntity(
    idEvento: BigInt.from(4),
    entidad: 'TRAMO',
    entidadTexto: 'Tramo',
    idRegistro: BigInt.two,
    descripcion: 'H50 · Día hábil',
    accion: 'U',
    accionTexto: 'Leyenda editada',
    campo: 'leyenda',
    campoTexto: 'Leyenda',
    valorAnterior: 'Hora al 50 %',
    valorNuevo: 'Hora extra con recargo del 50 %',
    audUsuario: BigInt.from(7),
    nombreUsuario: 'Salazar Rivera Jorge',
    audFecha: DateTime(2026, 10, 18, 16, 5),
    totalFilas: 2,
  ),
  HexConfiguracionEventoEntity(
    idEvento: BigInt.from(3),
    entidad: 'TRAMO',
    entidadTexto: 'Tramo',
    idRegistro: BigInt.two,
    descripcion: 'H50 · Día hábil',
    accion: 'N',
    accionTexto: 'Nueva vigencia',
    valorNuevo: '20:00–24:00 ×1,5 desde 01/01/2026',
    audUsuario: BigInt.from(7),
    nombreUsuario: 'Salazar Rivera Jorge',
    audFecha: DateTime(2025, 12, 20, 10),
    totalFilas: 2,
  ),
  HexConfiguracionEventoEntity(
    idEvento: BigInt.two,
    entidad: 'PARAMETRO',
    entidadTexto: 'Parámetro',
    idRegistro: BigInt.from(5),
    descripcion: 'DIVISOR_COSTO_HORA',
    accion: 'D',
    accionTexto: 'Vigencia eliminada',
    valorAnterior: '250 desde 01/12/2026',
    audUsuario: BigInt.from(7),
    nombreUsuario: 'Salazar Rivera Jorge',
    audFecha: DateTime(2026, 10, 15, 11),
    totalFilas: 2,
  ),
  HexConfiguracionEventoEntity(
    idEvento: BigInt.one,
    entidad: 'PARAMETRO',
    entidadTexto: 'Parámetro',
    idRegistro: BigInt.one,
    descripcion: 'DIVISOR_COSTO_HORA',
    accion: 'N',
    accionTexto: 'Nueva vigencia',
    valorNuevo: '240 desde 01/01/2026',
    audFecha: DateTime(2025, 12, 1),
    totalFilas: 2,
  ),
];

/// Dos encargados (nivel 1, su rama, D34) y un jefe de área asignado a mano a
/// uno de ellos (nivel 2, D35): el par trae el cargo y la rama del encargado.
final aprobadoresFalsos = <HexAprobadorEntity>[
  HexAprobadorEntity(
    idAprobador: BigInt.from(1),
    codEmpleadoAprobador: BigInt.from(7),
    nombreAprobador: 'Rojas Vargas Luis',
    nivel: 1,
    nivelTexto: 'Encargado',
    codCargo: BigInt.from(182),
    cargo: 'Responsable de producción',
    cantidadRama: 2,
    textoAlcance: 'Su rama: 2 empleados',
    vigenteDesde: _desde2026,
    esVigente: true,
    aprobadorActivo: true,
  ),
  HexAprobadorEntity(
    idAprobador: BigInt.from(2),
    codEmpleadoAprobador: BigInt.from(8),
    nombreAprobador: 'Paredes Limachi Rosa',
    nivel: 2,
    nivelTexto: 'Jefe de área',
    codCargo: BigInt.from(176),
    cargo: 'Supervisora de almacenes',
    cantidadRama: 5,
    codEmpleadoAprobado: BigInt.from(9),
    nombreAprobado: 'Quispe Mamani Ana',
    textoAlcance: 'Aprueba lo que firma Quispe Mamani Ana (5 empleados)',
    vigenteDesde: _desde2026,
    esVigente: true,
    aprobadorActivo: true,
  ),
  HexAprobadorEntity(
    idAprobador: BigInt.from(6),
    codEmpleadoAprobador: BigInt.from(9),
    nombreAprobador: 'Quispe Mamani Ana',
    nivel: 1,
    nivelTexto: 'Encargado',
    codCargo: BigInt.from(176),
    cargo: 'Supervisora de almacenes',
    cantidadRama: 5,
    textoAlcance: 'Su rama: 5 empleados',
    vigenteDesde: _desde2026,
    esVigente: true,
    aprobadorActivo: true,
  ),
];

/// Un rol de encargado (nivel 1) para armar casos en las pruebas.
HexAprobadorEntity rolAprobadorFalso(
  int id,
  int cod,
  String nombre, {
  String? cargo,
  String? avisoCargo,
  int rama = 0,
  DateTime? desde,
  DateTime? hasta,
  bool vigente = true,
  bool activo = true,
}) => HexAprobadorEntity(
  idAprobador: BigInt.from(id),
  codEmpleadoAprobador: BigInt.from(cod),
  nombreAprobador: nombre,
  nivel: 1,
  nivelTexto: 'Encargado',
  cargo: cargo,
  avisoCargo: avisoCargo,
  cantidadRama: rama,
  textoAlcance: 'Su rama: $rama empleados',
  vigenteDesde: desde ?? _desde2026,
  vigenteHasta: hasta,
  esVigente: vigente,
  aprobadorActivo: activo,
);

/// Un par jefe de área → encargado (nivel 2): como en el SP, el cargo y la
/// rama son los del encargado y [activo] es el del jefe.
HexAprobadorEntity parAprobadorFalso(
  int id,
  int codJefe,
  String jefe,
  int cod,
  String nombre, {
  String? cargo,
  int rama = 0,
  DateTime? desde,
  DateTime? hasta,
  bool vigente = true,
  bool activo = true,
}) => HexAprobadorEntity(
  idAprobador: BigInt.from(id),
  codEmpleadoAprobador: BigInt.from(codJefe),
  nombreAprobador: jefe,
  nivel: 2,
  nivelTexto: 'Jefe de área',
  cargo: cargo,
  cantidadRama: rama,
  codEmpleadoAprobado: BigInt.from(cod),
  nombreAprobado: nombre,
  textoAlcance: 'Aprueba lo que firma $nombre ($rama empleados)',
  vigenteDesde: desde ?? _desde2026,
  vigenteHasta: hasta,
  esVigente: vigente,
  aprobadorActivo: activo,
);

/// Un par observador → encargado (nivel 3, D45): como el del jefe de área,
/// con el cargo y la rama del encargado.
HexAprobadorEntity observadorAprobadorFalso(
  int id,
  int codObservador,
  String observador,
  int cod,
  String nombre, {
  String? cargo,
  int rama = 0,
  DateTime? desde,
  DateTime? hasta,
  bool vigente = true,
  bool activo = true,
}) => HexAprobadorEntity(
  idAprobador: BigInt.from(id),
  codEmpleadoAprobador: BigInt.from(codObservador),
  nombreAprobador: observador,
  nivel: 3,
  nivelTexto: 'Observador',
  cargo: cargo,
  cantidadRama: rama,
  codEmpleadoAprobado: BigInt.from(cod),
  nombreAprobado: nombre,
  textoAlcance: 'Observa lo que firma $nombre ($rama empleados)',
  vigenteDesde: desde ?? _desde2026,
  vigenteHasta: hasta,
  esVigente: vigente,
  aprobadorActivo: activo,
);

/// Los encargados para elegir como los manda E (D35): uno sin jefe y otra que
/// ya aprueba un jefe.
final encargadosFalsos = <HexEncargadoOpcionEntity>[
  HexEncargadoOpcionEntity(
    codEmpleado: BigInt.from(7),
    nombreEmpleado: 'Rojas Vargas Luis',
    cargo: 'Responsable de producción',
    cantidadRama: 2,
  ),
  HexEncargadoOpcionEntity(
    codEmpleado: BigInt.from(9),
    nombreEmpleado: 'Quispe Mamani Ana',
    cargo: 'Supervisora de almacenes',
    cantidadRama: 5,
    jefesActuales: 'Paredes Limachi Rosa',
  ),
];

/// La rama de un aprobador como la manda R, en orden de árbol: aprobación
/// directa, un empleado sin aprobador (bajo dos cargos vacantes) y dos firmas.
const _cargoJefe = 'Jefe comercial y de producción';
final ramaFalsa = <HexRamaEmpleadoEntity>[
  HexRamaEmpleadoEntity(
    codEmpleado: BigInt.from(12),
    nombreEmpleado: 'Vargas Ruiz Eva',
    codCargo: BigInt.from(162),
    cargo: 'Ejecutivo comercial',
    codSucursal: BigInt.two,
    nombreSucursal: 'Almacén Central',
    profundidad: 1,
    aprueba: 'Paredes Limachi Rosa',
    textoFirma:
        'Aprueba directo: Paredes Limachi Rosa (sin encargado en su rama)',
    cargoAprobador: _cargoJefe,
    rutaCargo: 'Ejecutivo comercial',
  ),
  HexRamaEmpleadoEntity(
    codEmpleado: BigInt.from(13),
    nombreEmpleado: 'Mamani Cruz Rubén',
    codCargo: BigInt.from(141),
    cargo: 'Estibador',
    codSucursal: BigInt.two,
    nombreSucursal: 'Almacén Central',
    profundidad: 3,
    textoFirma: 'Sin aprobador en su rama',
    cargoAprobador: _cargoJefe,
    rutaCargo: 'Responsable de distribución › Chofer B › Estibador',
  ),
  HexRamaEmpleadoEntity(
    codEmpleado: BigInt.from(10),
    nombreEmpleado: 'Choque Flores Mario',
    codCargo: BigInt.from(140),
    cargo: 'Operario de máquina',
    codSucursal: _sucursal,
    nombreSucursal: 'Planta El Alto',
    profundidad: 2,
    vistoBueno: 'Rojas Vargas Luis',
    aprueba: 'Paredes Limachi Rosa',
    textoFirma:
        'Visto bueno: Rojas Vargas Luis · Aprueba: Paredes Limachi Rosa',
    cargoAprobador: _cargoJefe,
    rutaCargo: 'Responsable de producción › Operario de máquina',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// MAPA DE TRAMOS Y SIMULADOR
// ═══════════════════════════════════════════════════════════════════════════

const String textoHuecoFalso =
    'De 20:00 a 20:01 ningún tramo paga: haga que «H50» empiece a las 20:00. '
    'La hora de fin no se incluye: el tramo siguiente empieza a esa misma hora.';

HexTramoMapaEntity _pieza(
  String tipoDia,
  String textoTipoDia,
  int orden,
  int desde,
  int hasta, {
  String clase = 'TRAMO',
  String? codigo,
  String? leyenda,
  double? multiplicador,
  bool esPropuesto = false,
  String? texto,
}) {
  String hora(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
  return HexTramoMapaEntity(
    tipoDia: tipoDia,
    textoTipoDia: textoTipoDia,
    orden: orden,
    desdeMin: desde,
    hastaMin: hasta,
    horaDesde: hora(desde),
    horaHasta: hora(hasta),
    clase: clase,
    codigo: codigo,
    leyenda: leyenda,
    multiplicador: multiplicador,
    esPropuesto: esPropuesto,
    texto: texto,
  );
}

List<HexTramoMapaEntity> _habil({required bool conHueco}) => [
  _pieza(
    'HABIL',
    'Días hábiles',
    1,
    0,
    360,
    codigo: 'H100',
    leyenda: 'Hora extra con recargo del 100 %',
    multiplicador: 2,
  ),
  _pieza(
    'HABIL',
    'Días hábiles',
    2,
    360,
    1200,
    codigo: 'HS',
    leyenda: 'Hora extra simple',
    multiplicador: 1,
  ),
  if (conHueco)
    _pieza(
      'HABIL',
      'Días hábiles',
      3,
      1200,
      1201,
      clase: 'HUECO',
      texto: textoHuecoFalso,
    ),
  _pieza(
    'HABIL',
    'Días hábiles',
    4,
    conHueco ? 1201 : 1200,
    1440,
    codigo: 'H50',
    leyenda: 'Hora extra con recargo del 50 %',
    multiplicador: 1.5,
    esPropuesto: !conHueco,
  ),
  _pieza(
    'DOMINGO',
    'Domingos',
    1,
    0,
    1440,
    codigo: 'HD',
    leyenda: 'Hora doble de domingo',
    multiplicador: 2,
  ),
  _pieza(
    'FERIADO',
    'Feriados',
    1,
    0,
    1440,
    codigo: 'HF',
    leyenda: 'Hora doble de feriado',
    multiplicador: 2,
  ),
  // Las ventanas de comida, después de los tramos de cada tipo de día.
  for (final (tipo, texto, ultimo) in [
    ('HABIL', 'Días hábiles', conHueco ? 4 : 3),
    ('DOMINGO', 'Domingos', 1),
    ('FERIADO', 'Feriados', 1),
  ])
    for (final (i, (codigo, leyenda, desde, hasta, minutos))
        in [
          ('D', 'Desayuno', 360, 420, 60),
          ('A', 'Almuerzo', 720, 750, 30),
          ('C', 'Cena', 1080, 1200, 60),
        ].indexed)
      _pieza(
        tipo,
        texto,
        ultimo + i + 1,
        desde,
        hasta,
        clase: 'COMIDA',
        codigo: codigo,
        leyenda: leyenda,
        texto:
            codigo == 'C'
                ? textoCenaFalso
                : '$leyenda: la gana el bloque de $minutos min.',
      ),
];

/// El texto que arma el SP para la cena (acción M de p_list_thex_Tramo).
const String textoCenaFalso =
    'Cena: la gana, una vez por jornada, el bloque completo de 60 min que '
    'empiece desde las 18:00 y antes de las 20:00; esa hora se paga como cena '
    'y no como hora extra. Si el bloque siguiente de 60 min también se '
    'completa, se paga como doble cena.';

/// Hoy: H100 00–06, HS 06–20, hueco 20:00–20:01 y H50 20:01–24; en cada
/// tipo de día, las comidas D 06–07, A 12:00–12:30 y C 18–20.
final mapaTramosFalso = _habil(conHueco: true);

/// Con la propuesta H50 20:00–24:00: el día hábil queda completo.
final mapaTramosPropuestoFalso = _habil(conHueco: false);

HexSimulacionSegmentoEntity _segmento(
  int orden,
  (int, int) de,
  (int, int) a, {
  required String clase,
  required String codigo,
  required String leyenda,
  double? multiplicador,
  required double monto,
  required String textoPago,
}) {
  final desde = DateTime(2026, 11, 5, de.$1, de.$2);
  final hasta = DateTime(2026, 11, 5, a.$1, a.$2);
  final minutos = hasta.difference(desde).inMinutes;
  String hora(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:'
      '${f.minute.toString().padLeft(2, '0')}';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return HexSimulacionSegmentoEntity(
    orden: orden,
    desde: desde,
    hasta: hasta,
    horaDesde: hora(desde),
    horaHasta: hora(hasta),
    minutos: minutos,
    duracionTexto: [if (h > 0) '$h h', if (m > 0) '$m min'].join(' '),
    clase: clase,
    codigo: codigo,
    leyenda: leyenda,
    multiplicador: multiplicador,
    monto: monto,
    textoPago: textoPago,
    resumen: '6 h 36 min en total',
  );
}

/// Manuel (155) el 05/11: 15:00–21:36, cena de 18 a 19, total 149,40 Bs.
final simulacionManuelFalsa = HexSimulacionEntity(
  jornada: HexSimulacionJornadaEntity(
    codEmpleado: BigInt.from(155),
    nombreEmpleado: 'Manuel Quispe',
    cargo: 'Operario',
    nombreSucursal: 'Santa Cruz',
    fechaJornada: DateTime(2026, 11, 5),
    tipoDia: 'HABIL',
    textoTipoDia: 'Día hábil',
    horarioIngreso: DateTime(2026, 11, 5, 7),
    horarioSalida: DateTime(2026, 11, 5, 15),
    textoHorario: 'De 07:00 a 15:00',
    textoMarcas: 'Biométrico: entrada 06:55, salida 21:36',
    conAsignacion: true,
    textoAsignacion: 'Asignada por su encargado',
    textoReporte: 'Sin reporte todavía',
    inicioUsado: DateTime(2026, 11, 5, 15),
    finUsado: DateTime(2026, 11, 5, 21, 36),
    textoOrigen: 'Desde el fin del horario hasta la salida del biométrico',
    haberBasico: 5040,
    divisor: 240,
    costoHora: 21,
    totalHoras: 134.40,
    totalComidas: 15,
    total: 149.40,
    resumen: '5 h 36 min de horas extra y una cena',
  ),
  segmentos: [
    _segmento(
      1,
      (15, 0),
      (18, 0),
      clase: 'HORA',
      codigo: 'HS',
      leyenda: 'Hora extra simple',
      multiplicador: 1,
      monto: 63,
      textoPago: 'Se paga como hora: ×1 (simple)',
    ),
    _segmento(
      2,
      (18, 0),
      (19, 0),
      clase: 'COMIDA',
      codigo: 'C',
      leyenda: 'Cena',
      monto: 15,
      textoPago: 'Gana la cena (1 h): se paga solo con la comida',
    ),
    _segmento(
      3,
      (19, 0),
      (20, 0),
      clase: 'HORA',
      codigo: 'HS',
      leyenda: 'Hora extra simple',
      multiplicador: 1,
      monto: 21,
      textoPago: 'Se paga como hora: ×1 (simple)',
    ),
    _segmento(
      4,
      (20, 0),
      (21, 36),
      clase: 'HORA',
      codigo: 'H50',
      leyenda: 'Hora extra con recargo del 50 %',
      multiplicador: 1.5,
      monto: 50.40,
      textoPago: 'Se paga como hora: ×1,5 (recargo del 50 %)',
    ),
  ],
  avisos: const [
    HexSimulacionAvisoEntity(
      orden: 1,
      nivel: 'ERROR',
      texto: 'De 20:00 a 20:01 ningún tramo paga.',
      queHacer: 'Haga que «H50» empiece a las 20:00.',
      quien: 'RRHH · Tramos',
    ),
    HexSimulacionAvisoEntity(
      orden: 2,
      nivel: 'AVISO',
      texto: 'La salida salió del biométrico.',
      queHacer: 'Si marcó tarde, pida al encargado que la corrija.',
      quien: 'Encargado',
    ),
    HexSimulacionAvisoEntity(
      orden: 3,
      nivel: 'INFO',
      texto: 'Costo hora: haber básico ÷ 240.',
    ),
  ],
);
