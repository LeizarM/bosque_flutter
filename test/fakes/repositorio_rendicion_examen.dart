import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';
import 'package:bosque_flutter/domain/repositories/postulante_examen_repository.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

/// Un examen de 3 preguntas (2 cerradas y 1 abierta) que se rinde en memoria.
class RendicionFalsa implements RendicionExamenRepository {
  RendicionFalsa({String estado = 'EN_CURSO', int segundos = 1800})
    : estadoActual = TcpeEstadoRendicionEntity(
        codExamen: BigInt.from(10),
        titulo: 'Operadores de bobinadora',
        nombreClasificacion: 'Seguridad industrial',
        modalidad: 'O',
        duracionMinutos: 30,
        totalPreguntas: 3,
        estado: estado,
        segundosRestantes: segundos,
      );

  TcpeEstadoRendicionEntity estadoActual;

  /// Lo que devuelve `responder` como segundos restantes.
  int? segundosAlResponder = 1500;

  /// Si no es null, `responder` falla con esto.
  Object? errorAlResponder;

  /// Si el error de `responder` entrega el examen (vencido) o lo deja en curso.
  bool errorEntrega = true;

  final List<({BigInt codPreguntaH, List<BigInt>? opciones, String? respuestaU})> respuestas = [];

  /// Los latidos recibidos, con la pregunta que veía y si salió de la pestaña.
  final List<({BigInt? codPreguntaH, bool salioPestana})> latidos = [];

  /// Lo que devuelve el latido como segundos restantes (null = no sincroniza).
  int? segundosAlLatido;

  /// La devolución: dos cerradas (una acertada, una fallada) y una abierta
  /// pendiente. Con [mostrarRespuestas] en falso, `esValido` viene null.
  bool mostrarRespuestas = true;

  /// La configuración que responde el servidor.
  List<TcpeConfigEntity> config = const [
    TcpeConfigEntity(clave: 'avisoSalidaExamen', valor: 'No puedes salir: entrega tu examen.'),
    TcpeConfigEntity(clave: 'notaAprobacionDefecto', valor: '60'),
  ];
  int iniciados = 0;
  int finalizados = 0;

  final preguntas = [
    TcpePreguntaRendicionEntity(
      codPreguntaH: BigInt.from(1),
      orden: 1,
      pregunta: '¿Qué elemento de protección es obligatorio junto a la bobinadora?',
      esCerrada: true,
      codRespuestaH: BigInt.from(11),
    ),
    TcpePreguntaRendicionEntity(
      codPreguntaH: BigInt.from(2),
      orden: 2,
      pregunta: '¿Cuáles de estos gramajes corresponden a papel bond?',
      esCerrada: true,
      codRespuestaH: BigInt.from(12),
    ),
    TcpePreguntaRendicionEntity(
      codPreguntaH: BigInt.from(3),
      orden: 3,
      pregunta: 'Describe el procedimiento de bloqueo antes de limpiar los rodillos.',
      esCerrada: false,
      codRespuestaH: BigInt.from(13),
    ),
  ];

  final opciones = [
    TcpeOpcionRendicionEntity(codRsptaOpH: BigInt.from(101), codPreguntaH: BigInt.from(1), opcionRspta: 'Guantes anticorte'),
    TcpeOpcionRendicionEntity(codRsptaOpH: BigInt.from(102), codPreguntaH: BigInt.from(1), opcionRspta: 'Gorra'),
    TcpeOpcionRendicionEntity(codRsptaOpH: BigInt.from(201), codPreguntaH: BigInt.from(2), opcionRspta: '75 g/m²'),
    TcpeOpcionRendicionEntity(codRsptaOpH: BigInt.from(202), codPreguntaH: BigInt.from(2), opcionRspta: '180 g/m²'),
  ];

  @override
  Future<List<TcpeEstadoRendicionEntity>> listarExamenes() async => [estadoActual];

  @override
  Future<TcpeEstadoRendicionEntity?> estadoExamen(BigInt codExamen) async => estadoActual;

  @override
  Future<List<TcpePreguntaRendicionEntity>> preguntasExamen(BigInt codExamen) async => preguntas;

  @override
  Future<List<TcpeOpcionRendicionEntity>> opcionesExamen(BigInt codExamen) async => opciones;

  @override
  Future<int?> iniciarExamen(BigInt codExamen) async {
    iniciados++;
    estadoActual = estadoActual.copyWith(estado: 'EN_CURSO');
    return estadoActual.segundosRestantes;
  }

  @override
  Future<int?> responderPregunta({
    required BigInt codExamen,
    required BigInt codPreguntaH,
    List<BigInt>? opciones,
    String? respuestaU,
  }) async {
    respuestas.add((codPreguntaH: codPreguntaH, opciones: opciones, respuestaU: respuestaU));
    final error = errorAlResponder;
    if (error != null) {
      // Como el backend al vencer: entrega el examen y avisa con un 400.
      if (errorEntrega) estadoActual = estadoActual.copyWith(estado: 'POR_REVISAR', segundosRestantes: 0);
      throw error;
    }
    return segundosAlResponder;
  }

  @override
  Future<void> finalizarExamen(BigInt codExamen) async {
    finalizados++;
    estadoActual = estadoActual.copyWith(estado: 'POR_REVISAR', segundosRestantes: 0);
  }

  @override
  Future<int?> latido({required BigInt codExamen, BigInt? codPreguntaH, bool salioPestana = false}) async {
    latidos.add((codPreguntaH: codPreguntaH, salioPestana: salioPestana));
    return segundosAlLatido;
  }

  @override
  Future<List<TcpeConfigEntity>> configuracion() async => config;

  @override
  Future<List<TcpeDevolucionItemEntity>> devolucionExamen(BigInt codExamen) async {
    bool? v(bool valida) => mostrarRespuestas ? valida : null;
    return [
      TcpeDevolucionItemEntity(codPreguntaH: BigInt.from(1), orden: 1, pregunta: preguntas[0].pregunta, esCerrada: true, esCorrecta: true, codRsptaOpH: BigInt.from(101), opcionRspta: 'Guantes anticorte', marcada: true, esValido: v(true)),
      TcpeDevolucionItemEntity(codPreguntaH: BigInt.from(1), orden: 1, pregunta: preguntas[0].pregunta, esCerrada: true, esCorrecta: true, codRsptaOpH: BigInt.from(102), opcionRspta: 'Gorra', esValido: v(false)),
      TcpeDevolucionItemEntity(codPreguntaH: BigInt.from(2), orden: 2, pregunta: preguntas[1].pregunta, esCerrada: true, esCorrecta: false, codRsptaOpH: BigInt.from(201), opcionRspta: '75 g/m²', esValido: v(true)),
      TcpeDevolucionItemEntity(codPreguntaH: BigInt.from(2), orden: 2, pregunta: preguntas[1].pregunta, esCerrada: true, esCorrecta: false, codRsptaOpH: BigInt.from(202), opcionRspta: '180 g/m²', marcada: true, esValido: v(false)),
      TcpeDevolucionItemEntity(codPreguntaH: BigInt.from(3), orden: 3, pregunta: preguntas[2].pregunta, respuestaU: 'Cortar la energía y colocar el candado.'),
    ];
  }
}

/// El postulante en memoria: misma rendición y una sesión configurable.
class PostulanteFalso extends RendicionFalsa implements PostulanteExamenRepository {
  PostulanteFalso({this.sesion, super.estado, super.segundos});

  TcpeSesionPostulanteEntity? sesion;
  int salidas = 0;
  int registros = 0;

  @override
  Future<TcpeSesionPostulanteEntity> ingresar(String login, String password) async {
    if (password != 'Kq7mZt9wHp') throw Exception('Usuario o clave incorrectos.');
    return sesion = TcpeSesionPostulanteEntity(
      token: 'a.b.c',
      codUsuario: BigInt.from(50),
      login: login,
      datosCompletos: true,
      nombres: 'Ana',
    );
  }

  @override
  Future<void> registrarDatos({
    required String ci,
    required String nombres,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    registros++;
    await marcarDatosCompletos();
  }

  @override
  Future<TcpeSesionPostulanteEntity?> sesionVigente() async => sesion;

  @override
  Future<void> marcarDatosCompletos() async => sesion = sesion?.copyWith(datosCompletos: true);

  @override
  Future<void> salir() async {
    salidas++;
    sesion = null;
  }
}
