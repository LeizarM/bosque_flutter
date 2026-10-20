import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';

/// `tcpe_clasificacion`: Categoría del banco de preguntas, dentro de un área.
/// Columnas de `p_list_tcpe_Clasificacion` (sin `password2`) más `nombreUsuario`.
class TcpeClasificacionModel {
  final BigInt codClasificacion;
  final BigInt? codArea;
  final BigInt? codCurso;
  final String? nombre;
  final String? modalidad;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeClasificacionModel({
    required this.codClasificacion,
    this.codArea,
    this.codCurso,
    this.nombre,
    this.modalidad,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeClasificacionModel.fromJson(Map<String, dynamic> json) => TcpeClasificacionModel(
    codClasificacion: tcpeBigInt(json['codClasificacion']) ?? BigInt.zero,
    codArea: tcpeBigInt(json['codArea']),
    codCurso: tcpeBigInt(json['codCurso']),
    nombre: tcpeTexto(json['nombre']),
    modalidad: tcpeTexto(json['modalidad']),
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codClasificacion': codClasificacion.toInt(),
    'codArea': codArea?.toInt(),
    'codCurso': codCurso?.toInt(),
    'nombre': nombre,
    'modalidad': modalidad,
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeClasificacionEntity toEntity() => TcpeClasificacionEntity(
    codClasificacion: codClasificacion,
    codArea: codArea,
    codCurso: codCurso,
    nombre: nombre,
    modalidad: modalidad,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeClasificacionModel.fromEntity(TcpeClasificacionEntity e) => TcpeClasificacionModel(
    codClasificacion: e.codClasificacion,
    codArea: e.codArea,
    codCurso: e.codCurso,
    nombre: e.nombre,
    modalidad: e.modalidad,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
