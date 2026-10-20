import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';

/// Una pregunta de la carga en lote, tal como sale de la plantilla. Las reglas
/// (opciones mínimas, válidas, duplicados) las valida `p_list_tcpe_BancoLote`.
class TcpePreguntaImportarEntity {
  final String pregunta;
  final bool esCerrada;
  final String? respuesta;
  final int? prioridad;
  final List<TcpeBancoOpcionEntity> opciones;

  const TcpePreguntaImportarEntity({
    required this.pregunta,
    required this.esCerrada,
    this.respuesta,
    this.prioridad,
    this.opciones = const [],
  });

  TcpePreguntaImportarEntity copyWith({
    String? pregunta,
    bool? esCerrada,
    String? respuesta,
    int? prioridad,
    List<TcpeBancoOpcionEntity>? opciones,
  }) => TcpePreguntaImportarEntity(
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    respuesta: respuesta ?? this.respuesta,
    prioridad: prioridad ?? this.prioridad,
    opciones: opciones ?? this.opciones,
  );
}
