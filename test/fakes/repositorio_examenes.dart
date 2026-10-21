import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_candidata_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estadistica_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_vigente_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_ranking_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respondio_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';
import 'package:bosque_flutter/domain/repositories/examenes_repository.dart';

import 'repositorio_rendicion_examen.dart';

/// Repositorio de empleados en memoria: lo que leen las pantallas del módulo.
/// Lo que no se usa en las pruebas de pantalla avisa con [UnimplementedError].
class ExamenesFalso extends RendicionFalsa implements ExamenesRepository {
  ExamenesFalso({super.estado, super.segundos});

  final areas = [
    TcpeAreaEntity(codArea: BigInt.one, nombreArea: 'Producción'),
    TcpeAreaEntity(codArea: BigInt.two, nombreArea: 'Administración y finanzas'),
  ];

  final categorias = [
    TcpeClasificacionEntity(codClasificacion: BigInt.from(5), codArea: BigInt.one, nombre: 'Seguridad industrial', modalidad: 'O'),
    TcpeClasificacionEntity(codClasificacion: BigInt.from(6), codArea: BigInt.one, nombre: 'Manejo de bobinadora'),
    TcpeClasificacionEntity(codClasificacion: BigInt.from(7), codArea: BigInt.two, nombre: 'Contabilidad básica', activo: false),
  ];

  late final preguntasBanco = [
    for (var i = 1; i <= 23; i++)
      TcpeBancoPreguntaEntity(
        codPregunta: BigInt.from(i),
        codClasificacion: BigInt.from(5),
        nombreClasificacion: 'Seguridad industrial',
        nombreArea: 'Producción',
        pregunta:
            i.isEven
                ? '¿Qué elemento de protección personal es obligatorio al operar la bobinadora número $i en el turno nocturno?'
                : 'Describe el procedimiento de bloqueo y etiquetado antes de limpiar los rodillos de la máquina $i.',
        esCerrada: i.isEven,
        cantOpciones: i.isEven ? 4 : 0,
        cantValidas: i.isEven ? 1 : 0,
        usadaEnExamenes: i % 3,
        activo: i != 4,
      ),
  ];

  final lotes = [
    TcpeLoteEntity(
      codRolExamen: BigInt.from(40),
      titulo: 'Convocatoria operadores de bobinadora 2026',
      nombreArea: 'Producción',
      nombreClasificacion: 'Seguridad industrial',
      codClasificacion: BigInt.from(5),
      modalidad: 'O',
      duracionMinutos: 90,
      cantidadPreg: 20,
      fecha: DateTime(2026, 10, 20),
      horaInicio: '08:30:00',
      horaFin: '10:00:00',
      examenes: 12,
      sinIniciar: 3,
      enCurso: 2,
      vencidos: 1,
      porRevisar: 2,
      calificados: 4,
      promedio: 63.5,
      notaAprobacion: 51,
      mostrarRespuestas: true,
      aprobados: 3,
      reprobados: 1,
      inicioVentana: DateTime(2026, 10, 20, 8, 30),
      finVentana: DateTime(2026, 10, 20, 10),
    ),
    TcpeLoteEntity(
      codRolExamen: BigInt.from(41),
      titulo: 'Examen escrito de contabilidad',
      nombreClasificacion: 'Contabilidad básica',
      modalidad: 'E',
      duracionMinutos: 60,
      cantidadPreg: 15,
      fecha: DateTime(2026, 10, 22),
      examenes: 5,
      sinIniciar: 5,
    ),
  ];

  final resultados = [
    TcpeResultadoExamenEntity(
      codExamen: BigInt.from(100),
      login: 'IPX-56',
      nombreCompleto: 'Ana María Quispe Mamani',
      ci: '7654321 LP',
      estado: 'POR_REVISAR',
      fechaInicio: DateTime(2026, 10, 20, 8, 31),
      fechaFin: DateTime(2026, 10, 20, 9, 40),
      totalPreguntas: 20,
      respondidas: 19,
      abiertasPendientes: 2,
      codUsuario: BigInt.from(50),
    ),
    TcpeResultadoExamenEntity(
      codExamen: BigInt.from(101),
      login: 'IPX-57',
      nombreCompleto: 'Carlos Rojas',
      estado: 'CALIFICADO',
      resultado: 72.5,
      aprobado: true,
      totalPreguntas: 20,
      respondidas: 20,
      notaAprobacion: 51,
    ),
    TcpeResultadoExamenEntity(codExamen: BigInt.from(102), login: 'IPX-58', estado: 'SIN_INICIAR', totalPreguntas: 20),
  ];

  /// Cuántas veces se consultó el panel "En vivo".
  int consultasMonitor = 0;

  final monitor = [
    TcpeMonitorExamenEntity(
      codExamen: BigInt.from(100),
      login: 'IPX-56',
      nombreCompleto: 'Ana María Quispe Mamani',
      estado: 'EN_CURSO',
      segundosRestantes: 1500,
      totalPreguntas: 20,
      respondidas: 7,
      ordenActual: 8,
      conexion: 'CONECTADO',
      salidasPestana: 2,
      ultimaSalida: DateTime(2026, 10, 20, 9, 2),
    ),
    TcpeMonitorExamenEntity(
      codExamen: BigInt.from(103),
      login: 'IPX-59',
      nombreCompleto: 'Luis Rojas',
      estado: 'EN_CURSO',
      segundosRestantes: 240,
      totalPreguntas: 20,
      respondidas: 15,
      ordenActual: 16,
      conexion: 'DESCONECTADO',
    ),
    TcpeMonitorExamenEntity(codExamen: BigInt.from(101), login: 'IPX-57', estado: 'CALIFICADO', conexion: '-', totalPreguntas: 20, respondidas: 20),
  ];

  @override
  Future<List<TcpeMonitorLoteEntity>> monitorLotes() async => [
    TcpeMonitorLoteEntity(codRolExamen: BigInt.from(40), titulo: 'Convocatoria operadores de bobinadora 2026', examenes: 12, sinIniciar: 3, enCurso: 2),
  ];

  @override
  Future<List<TcpeMonitorExamenEntity>> monitorExamenes(BigInt codRolExamen) async {
    consultasMonitor++;
    return monitor;
  }

  @override
  Future<List<TcpeEspejoItemEntity>> espejo(BigInt codExamen) async => espejoDe(codExamen);

  static List<TcpeEspejoItemEntity> espejoDe(BigInt codExamen) => [
    for (final (cod, texto, marcada, valida) in [
      (301, 'Guantes anticorte', true, true),
      (302, 'Gorra', false, false),
      (303, 'Lentes de seguridad', true, true),
    ])
      TcpeEspejoItemEntity(
        codExamen: codExamen,
        nombreCompleto: 'Ana María Quispe Mamani',
        estado: 'EN_CURSO',
        segundosRestantes: 1500,
        conexion: 'CONECTADO',
        totalPreguntas: 20,
        respondidas: 7,
        ordenActual: 8,
        codPreguntaH: BigInt.from(8),
        pregunta: '¿Qué elementos de protección son obligatorios junto a la bobinadora?',
        esCerrada: true,
        codRsptaOpH: BigInt.from(cod),
        opcionRspta: texto,
        marcada: marcada,
        esValido: valida,
      ),
  ];

  @override
  Future<List<E>> listarCatalogo<E>(TcpeCatalogo<E> catalogo, {Map<String, Object?> filtros = const {}}) async {
    final Object lista = switch (catalogo.entidad) {
      'area' => areas,
      'clasificacion' => categorias,
      'usuario' => [
        TcpeUsuarioEntity(codUsuario: BigInt.from(50), login: 'IPX-56', nombres: 'Ana María', apellidoPaterno: 'Quispe', ci: '7654321', codArea: BigInt.one),
        TcpeUsuarioEntity(codUsuario: BigInt.from(51), login: 'IPX-57', activo: false),
        TcpeUsuarioEntity(codUsuario: BigInt.from(52), login: null, codEmpleado: BigInt.from(9)),
      ],
      _ => <E>[],
    };
    return (lista as List).cast<E>();
  }

  @override
  Future<List<TcpeBancoPreguntaEntity>> listarPreguntas({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    BigInt? codArea,
    bool? activo,
    String? texto,
  }) async => [
    for (final p in preguntasBanco)
      if ((activo == null || p.activo == activo) && (codClasificacion == null || p.codClasificacion == codClasificacion)) p,
  ];

  @override
  Future<List<TcpeBancoOpcionEntity>> listarOpciones({BigInt? codPregunta, BigInt? codClasificacion}) async => [];

  @override
  Future<List<TcpeLoteEntity>> listarLotes({
    BigInt? codRolExamen,
    BigInt? codArea,
    BigInt? codClasificacion,
    String? modalidad,
  }) async => lotes;

  @override
  Future<int> preguntasDisponibles(BigInt codClasificacion) async => 40;

  /// Lo que devuelve `Lote` E; [loteDeElegibles] guarda el lote con el que se pidió.
  final elegibles = [
    TcpeEmpleadoElegibleEntity(codEmpleado: BigInt.from(180), nombreCompleto: 'Aguilar Cuenca Omar', ci: '4899241 LP', cargo: 'OPERADOR DE BOBINADORA'),
    TcpeEmpleadoElegibleEntity(codEmpleado: BigInt.from(181), nombreCompleto: 'Quispe Mamani Ronaldo', ci: '6764264 LP', cargo: 'CAJERO'),
    TcpeEmpleadoElegibleEntity(
      codEmpleado: BigInt.from(182),
      nombreCompleto: 'Rojas Vargas Luis',
      ci: '4755783 CB',
      cargo: 'AUXILIAR CONTABLE',
      puedeRendir: false,
      motivo: 'No tiene usuario en BOSQUE: créale uno antes de asignarle un examen.',
    ),
  ];
  BigInt? loteDeElegibles;

  @override
  Future<List<TcpeEmpleadoElegibleEntity>> empleadosElegibles({BigInt? codRolExamen}) async {
    loteDeElegibles = codRolExamen;
    return elegibles;
  }

  @override
  Future<List<TcpeResultadoExamenEntity>> listarResultados(BigInt codRolExamen) async => resultados;

  /// La última pregunta guardada desde el editor, con sus opciones.
  ({TcpeBancoPreguntaEntity pregunta, List<TcpeBancoOpcionEntity> opciones})? guardada;

  @override
  Future<BigInt> guardarPregunta(TcpeBancoPreguntaEntity pregunta, List<TcpeBancoOpcionEntity> opciones) async {
    guardada = (pregunta: pregunta, opciones: opciones);
    return pregunta.codPregunta == BigInt.zero ? BigInt.from(99) : pregunta.codPregunta;
  }

  // ── v6: duplicados e importación ───────────────────────────────────────
  /// Lo que devuelve `Banco` D; cada consulta guarda el texto buscado.
  List<TcpeDuplicadoPreguntaEntity> duplicados = [];
  final textosBuscados = <String>[];

  @override
  Future<List<TcpeDuplicadoPreguntaEntity>> buscarDuplicados(BigInt codClasificacion, String texto) async {
    textosBuscados.add(texto);
    return duplicados;
  }

  List<TcpePreguntaImportarEntity>? validadas;
  List<TcpePreguntaImportarEntity>? importadas;

  /// Imita `BancoLote` V: un texto repetido es del archivo, uno con «repetida»
  /// ya está en el banco y una cerrada con menos de 2 opciones es error.
  static List<TcpeFilaImportacionEntity> validacionFalsa(List<TcpePreguntaImportarEntity> preguntas) {
    final vistos = <String>{};
    final filas = <TcpeFilaImportacionEntity>[];
    for (final (i, p) in preguntas.indexed) {
      final (estado, mensaje) =
          !vistos.add(p.pregunta.toLowerCase())
              ? (EstadoFilaImportacion.duplicadaEnArchivo, 'Repite una fila anterior del archivo.')
              : p.pregunta.contains('repetida')
              ? (EstadoFilaImportacion.duplicadaEnBanco, 'Ya existe una pregunta igual en la categoria.')
              : p.esCerrada && p.opciones.length < 2
              ? (EstadoFilaImportacion.error, 'Una pregunta cerrada lleva al menos 2 opciones.')
              : (EstadoFilaImportacion.ok, null);
      filas.add(
        TcpeFilaImportacionEntity(
          fila: i + 1,
          pregunta: p.pregunta,
          esCerrada: p.esCerrada,
          cantOpciones: p.opciones.length,
          cantValidas: p.opciones.where((o) => o.esValido).length,
          estado: estado,
          mensaje: mensaje,
          codPreguntaExistente: estado == EstadoFilaImportacion.duplicadaEnBanco ? BigInt.from(2) : null,
        ),
      );
    }
    return filas;
  }

  @override
  Future<List<TcpeFilaImportacionEntity>> validarImportacion(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  ) async {
    validadas = preguntas;
    return validacionFalsa(preguntas);
  }

  @override
  Future<TcpeResultadoImportacionEntity> importarPreguntas(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  ) async {
    importadas = preguntas;
    final ok = validacionFalsa(preguntas).where((f) => f.importable).length;
    return TcpeResultadoImportacionEntity(
      insertadas: ok,
      mensaje: 'Se importaron $ok preguntas; ${preguntas.length - ok} se omitieron por estar duplicadas o tener errores.',
    );
  }

  // ── v11: ranking y preguntas de la semana ─────────────────────────────
  Object? errorRanking;
  List<TcpeRankingPreguntaEntity> ranking = [
    TcpeRankingPreguntaEntity(
      puesto: 1,
      codClasificacion: BigInt.from(5),
      nombreClasificacion: 'Seguridad industrial',
      nombreArea: 'Producción',
      codPregunta: BigInt.from(8),
      pregunta: '¿Qué elemento de protección personal es obligatorio al operar la bobinadora?',
      veces: 8,
      aciertos: 1,
      fallos: 7,
      sinResponder: 1,
      incompletas: 0,
      porcentajeFallo: 87.5,
      errorComun: 'Guantes de látex',
      vecesErrorComun: 4,
    ),
    TcpeRankingPreguntaEntity(
      puesto: 2,
      codClasificacion: BigInt.from(5),
      nombreClasificacion: 'Seguridad industrial',
      nombreArea: 'Producción',
      codPregunta: BigInt.from(10),
      pregunta: '¿Qué colores tiene la señal de riesgo eléctrico?',
      veces: 8,
      aciertos: 2,
      fallos: 6,
      incompletas: 6,
      porcentajeFallo: 75,
    ),
    TcpeRankingPreguntaEntity(
      puesto: 1,
      codClasificacion: BigInt.from(7),
      nombreClasificacion: 'Contabilidad básica',
      nombreArea: 'Administración y finanzas',
      codPregunta: BigInt.from(31),
      pregunta: 'Describe qué es un asiento de ajuste.',
      esCerrada: false,
      veces: 4,
      aciertos: 3,
      fallos: 1,
      porcentajeFallo: 25,
    ),
  ];

  @override
  Future<List<TcpeRankingPreguntaEntity>> rankingPreguntas({
    BigInt? codClasificacion,
    BigInt? codRolExamen,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    if (errorRanking != null) throw errorRanking!;
    return [
      for (final r in ranking)
        if (codClasificacion == null || r.codClasificacion == codClasificacion) r,
    ];
  }

  Object? errorVigentes;
  List<TcpePreguntaSemanaVigenteEntity> vigentes = [];

  /// La correcta de cada vigente: el SP la manda (esValido) solo después de responder.
  Map<BigInt, BigInt> correctaDe = {};
  final respondidas = <(BigInt, BigInt)>[];

  /// Una vigente sin responder, con su correcta en [correctaDe].
  void ponerVigente({bool mostrarRespuesta = true}) {
    final cod = BigInt.from(1);
    correctaDe = {cod: BigInt.from(102)};
    vigentes = [
      TcpePreguntaSemanaVigenteEntity(
        codPreguntaSemana: cod,
        titulo: 'Pregunta de la semana',
        pregunta: '¿Cada cuánto se revisa el extintor de la planta?',
        fechaInicio: DateTime(2026, 10, 20),
        fechaFin: DateTime(2026, 10, 26),
        diasRestantes: 6,
        mostrarRespuesta: mostrarRespuesta,
        respuestas: 3,
        opciones: [
          TcpeOpcionSemanaEntity(codPreguntaSemana: cod, codRsptaOp: BigInt.from(101), opcionRspta: 'Cada año'),
          TcpeOpcionSemanaEntity(codPreguntaSemana: cod, codRsptaOp: BigInt.from(102), opcionRspta: 'Cada mes'),
          TcpeOpcionSemanaEntity(codPreguntaSemana: cod, codRsptaOp: BigInt.from(103), opcionRspta: 'Nunca'),
        ],
      ),
    ];
  }

  @override
  Future<List<TcpePreguntaSemanaVigenteEntity>> preguntasSemanaVigentes() async {
    if (errorVigentes != null) throw errorVigentes!;
    return vigentes;
  }

  @override
  Future<String?> responderPreguntaSemana(BigInt codPreguntaSemana, BigInt codRsptaOp) async {
    respondidas.add((codPreguntaSemana, codRsptaOp));
    final correcta = correctaDe[codPreguntaSemana];
    final acerto = correcta == codRsptaOp;
    String? mensaje;
    vigentes = [
      for (final v in vigentes)
        if (v.codPreguntaSemana != codPreguntaSemana)
          v
        else
          v.copyWith(
            respondida: true,
            codRsptaOpElegida: codRsptaOp,
            respuestas: v.respuestas + 1,
            esCorrecta: v.mostrarRespuesta ? acerto : null,
            mensaje:
                mensaje =
                    !v.mostrarRespuesta
                        ? 'Gracias: tu respuesta quedó registrada.'
                        : acerto
                        ? '¡Correcto! Elegiste la respuesta correcta.'
                        : 'No era esa. La respuesta correcta es: Cada mes.',
            opciones: [
              for (final o in v.opciones)
                TcpeOpcionSemanaEntity(
                  codPreguntaSemana: o.codPreguntaSemana,
                  codRsptaOp: o.codRsptaOp,
                  opcionRspta: o.opcionRspta,
                  elegida: o.codRsptaOp == codRsptaOp,
                  esValido: v.mostrarRespuesta ? o.codRsptaOp == correcta : null,
                ),
            ],
          ),
    ];
    return mensaje;
  }

  List<TcpePreguntaSemanaEntity> preguntasSemana = [
    TcpePreguntaSemanaEntity(
      codPreguntaSemana: BigInt.from(1),
      codPregunta: BigInt.from(8),
      tituloMostrado: 'Pregunta de la semana',
      pregunta: '¿Cada cuánto se revisa el extintor de la planta?',
      codClasificacion: BigInt.from(5),
      nombreClasificacion: 'Seguridad industrial',
      fechaInicio: DateTime(2026, 10, 20),
      fechaFin: DateTime(2026, 10, 26),
      estado: 'VIGENTE',
      respuestas: 12,
      correctas: 9,
      porcentajeAcierto: 75,
    ),
    TcpePreguntaSemanaEntity(
      codPreguntaSemana: BigInt.from(2),
      codPregunta: BigInt.from(10),
      titulo: 'Seguridad eléctrica',
      tituloMostrado: 'Seguridad eléctrica',
      pregunta: '¿Qué colores tiene la señal de riesgo eléctrico?',
      nombreClasificacion: 'Seguridad industrial',
      fechaInicio: DateTime(2026, 10, 27),
      fechaFin: DateTime(2026, 11, 2),
      estado: 'PROGRAMADA',
    ),
    TcpePreguntaSemanaEntity(
      codPreguntaSemana: BigInt.from(3),
      codPregunta: BigInt.from(12),
      tituloMostrado: 'Pregunta de la semana',
      pregunta: '¿Dónde está el botiquín del galpón?',
      nombreClasificacion: 'Seguridad industrial',
      fechaInicio: DateTime(2026, 10, 1),
      fechaFin: DateTime(2026, 10, 7),
      activo: false,
      estado: 'INACTIVA',
      respuestas: 30,
      correctas: 12,
      porcentajeAcierto: 40,
    ),
  ];

  @override
  Future<List<TcpePreguntaSemanaEntity>> listarPreguntasSemana({bool? activo}) async => [
    for (final p in preguntasSemana)
      if (activo == null || p.activo == activo) p,
  ];

  @override
  Future<List<TcpeRespondioSemanaEntity>> respuestasPreguntaSemana(BigInt codPreguntaSemana) async => [
    TcpeRespondioSemanaEntity(
      codRsptaSemana: BigInt.from(1),
      login: 'rhoward',
      nombreCompleto: 'HOWARD ESCOBAR ROGER',
      cargo: 'EJECUTIVO COMERCIAL SCZ',
      opcionRspta: 'Cada mes',
      esCorrecta: true,
      fechaRespuesta: DateTime(2026, 10, 20, 9, 15),
    ),
    TcpeRespondioSemanaEntity(
      codRsptaSemana: BigInt.from(2),
      login: 'fmunoz',
      nombreCompleto: 'MUÑOZ LUIS FERNANDO',
      cargo: 'ESTIBADOR SCZ',
      opcionRspta: 'Cada año',
      fechaRespuesta: DateTime(2026, 10, 20, 10, 2),
    ),
  ];

  @override
  Future<List<TcpeEstadisticaSemanaEntity>> estadisticaPreguntaSemana(BigInt codPreguntaSemana) async => [
    TcpeEstadisticaSemanaEntity(codRsptaOp: BigInt.from(101), opcionRspta: 'Cada año', veces: 1, porcentaje: 50),
    TcpeEstadisticaSemanaEntity(
      codRsptaOp: BigInt.from(102),
      opcionRspta: 'Cada mes',
      esValido: true,
      veces: 1,
      porcentaje: 50,
    ),
    TcpeEstadisticaSemanaEntity(codRsptaOp: BigInt.from(103), opcionRspta: 'Nunca'),
  ];

  @override
  Future<List<TcpeCandidataSemanaEntity>> candidatasPreguntaSemana({
    BigInt? codClasificacion,
    String? texto,
  }) async => [
    TcpeCandidataSemanaEntity(
      codPregunta: BigInt.from(8),
      nombreClasificacion: 'Seguridad industrial',
      pregunta: '¿Cada cuánto se revisa el extintor de la planta?',
      cantOpciones: 3,
      cantValidas: 1,
      puedeElegirse: true,
      vecesUsada: 1,
    ),
    TcpeCandidataSemanaEntity(
      codPregunta: BigInt.from(9),
      nombreClasificacion: 'Seguridad industrial',
      pregunta: 'Describe el bloqueo y etiquetado de la máquina.',
      motivo: 'Es abierta: la pregunta de la semana se responde eligiendo una opción.',
    ),
  ];

  String? ultimaGuardada;

  @override
  Future<String?> guardarPreguntaSemana(TcpePreguntaSemanaEntity pregunta) async {
    ultimaGuardada = '${pregunta.codPregunta}';
    return 'Pregunta de la semana registrada.';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('ExamenesFalso: ${invocation.memberName}');
}
