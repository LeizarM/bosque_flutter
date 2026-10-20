import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_usuario_entity.dart';

/// `tcpe_tipoUsuario`: Tipo de usuario del módulo (2 = evaluado).
/// Columnas de `p_list_tcpe_TipoUsuario` (sin `password2`) más `nombreUsuario`.
class TcpeTipoUsuarioModel {
  final BigInt codTipoUsuario;
  final String? tipo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeTipoUsuarioModel({
    required this.codTipoUsuario,
    this.tipo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeTipoUsuarioModel.fromJson(Map<String, dynamic> json) => TcpeTipoUsuarioModel(
    codTipoUsuario: tcpeBigInt(json['codTipoUsuario']) ?? BigInt.zero,
    tipo: tcpeTexto(json['tipo']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codTipoUsuario': codTipoUsuario.toInt(),
    'tipo': tipo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeTipoUsuarioEntity toEntity() => TcpeTipoUsuarioEntity(
    codTipoUsuario: codTipoUsuario,
    tipo: tipo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeTipoUsuarioModel.fromEntity(TcpeTipoUsuarioEntity e) => TcpeTipoUsuarioModel(
    codTipoUsuario: e.codTipoUsuario,
    tipo: e.tipo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
