import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_fase_entity.dart';

/// `tcpe_seleccionFase`: Fase elegida para una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_SeleccionFase` (sin `password2`) más `nombreUsuario`.
class TcpeSeleccionFaseModel {
  final BigInt codSeleccionFase;
  final BigInt? codConvocatoria;
  final BigInt? codFase;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeSeleccionFaseModel({
    required this.codSeleccionFase,
    this.codConvocatoria,
    this.codFase,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeSeleccionFaseModel.fromJson(Map<String, dynamic> json) => TcpeSeleccionFaseModel(
    codSeleccionFase: tcpeBigInt(json['codSeleccionFase']) ?? BigInt.zero,
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    codFase: tcpeBigInt(json['codFase']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codSeleccionFase': codSeleccionFase.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'codFase': codFase?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeSeleccionFaseEntity toEntity() => TcpeSeleccionFaseEntity(
    codSeleccionFase: codSeleccionFase,
    codConvocatoria: codConvocatoria,
    codFase: codFase,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeSeleccionFaseModel.fromEntity(TcpeSeleccionFaseEntity e) => TcpeSeleccionFaseModel(
    codSeleccionFase: e.codSeleccionFase,
    codConvocatoria: e.codConvocatoria,
    codFase: e.codFase,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
