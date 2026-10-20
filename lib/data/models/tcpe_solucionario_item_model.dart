import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_solucionario_item_entity.dart';

/// Una opción (o la pregunta abierta) de un examen, para los PDF (`p_list_tcpe_Resultado` S).
class TcpeSolucionarioItemModel {
  final BigInt? codExamen;
  final BigInt? codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool esValido;

  const TcpeSolucionarioItemModel({
    this.codExamen,
    this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.codRsptaOpH,
    this.opcionRspta,
    this.esValido = false,
  });

  factory TcpeSolucionarioItemModel.fromJson(Map<String, dynamic> json) => TcpeSolucionarioItemModel(
    codExamen: tcpeBigInt(json['codExamen']),
    codPreguntaH: tcpeBigInt(json['codPreguntaH']),
    orden: tcpeInt(json['orden']) ?? 0,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen?.toInt(),
    'codPreguntaH': codPreguntaH?.toInt(),
    'orden': orden,
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'codRsptaOpH': codRsptaOpH?.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
  };

  TcpeSolucionarioItemEntity toEntity() => TcpeSolucionarioItemEntity(
    codExamen: codExamen,
    codPreguntaH: codPreguntaH,
    orden: orden,
    pregunta: pregunta,
    esCerrada: esCerrada,
    codRsptaOpH: codRsptaOpH,
    opcionRspta: opcionRspta,
    esValido: esValido,
  );

  factory TcpeSolucionarioItemModel.fromEntity(TcpeSolucionarioItemEntity e) => TcpeSolucionarioItemModel(
    codExamen: e.codExamen,
    codPreguntaH: e.codPreguntaH,
    orden: e.orden,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    codRsptaOpH: e.codRsptaOpH,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
  );
}
