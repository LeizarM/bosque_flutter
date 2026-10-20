import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';

/// Lo que necesita la pantalla de rendición, venga de un empleado
/// (`/examenes/mis-examenes/*`) o de un postulante (`/examen-publico/examenes/*`).
/// El dueño del examen nunca viaja en el body: el backend lo saca del token.
abstract class RendicionExamenRepository {
  /// `p_list_tcpe_Rendir` M: los exámenes de quien está conectado.
  Future<List<TcpeEstadoRendicionEntity>> listarExamenes();

  /// `p_list_tcpe_Rendir` E. Null si el examen no es de quien pregunta.
  Future<TcpeEstadoRendicionEntity?> estadoExamen(BigInt codExamen);

  /// `p_list_tcpe_Rendir` P (solo `EN_CURSO`).
  Future<List<TcpePreguntaRendicionEntity>> preguntasExamen(BigInt codExamen);

  /// `p_list_tcpe_Rendir` O (solo `EN_CURSO`). Nunca trae cuál es la válida.
  Future<List<TcpeOpcionRendicionEntity>> opcionesExamen(BigInt codExamen);

  /// `p_abm_tcpe_Rendir` I: pone la hora de inicio si no la tenía. Devuelve
  /// los segundos restantes que calcula el servidor (null si no vinieron).
  Future<int?> iniciarExamen(BigInt codExamen);

  /// `p_abm_tcpe_Rendir` R: en una cerrada [opciones] reemplaza las marcas
  /// (vacía = sin responder); en una abierta va [respuestaU]. Devuelve los
  /// segundos restantes. Vencido el tiempo: 400 y la entrega ya quedó guardada.
  Future<int?> responderPregunta({
    required BigInt codExamen,
    required BigInt codPreguntaH,
    List<BigInt>? opciones,
    String? respuestaU,
  });

  /// `p_abm_tcpe_Rendir` F: entrega el examen. Llamarlo dos veces no da error.
  Future<void> finalizarExamen(BigInt codExamen);

  /// `p_list_tcpe_Rendir` F: la devolución de un examen ya entregado, una fila
  /// por opción. Vacía si todavía no se entregó.
  Future<List<TcpeDevolucionItemEntity>> devolucionExamen(BigInt codExamen);

  /// `p_abm_tcpe_Rendir` A: sigue activo en [codPreguntaH]; con [salioPestana]
  /// cuenta una salida de la pestaña. Devuelve los segundos restantes.
  Future<int?> latido({required BigInt codExamen, BigInt? codPreguntaH, bool salioPestana = false});

  /// `p_list_tcpe_Config` L: límites, valores por defecto y textos del módulo.
  Future<List<TcpeConfigEntity>> configuracion();
}
