import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_entity.dart';

/// `tcpe_tipo`: Catálogo genérico de tipos (sin uso).
/// Columnas de `p_list_tcpe_Tipo` (sin `password2`) más `nombreUsuario`.
class TcpeTipoModel {
  final BigInt codTipo;
  final String? nombre;
  final bool? esVigente;
  final int? idGrupo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeTipoModel({
    required this.codTipo,
    this.nombre,
    this.esVigente,
    this.idGrupo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeTipoModel.fromJson(Map<String, dynamic> json) => TcpeTipoModel(
    codTipo: tcpeBigInt(json['codTipo']) ?? BigInt.zero,
    nombre: tcpeTexto(json['nombre']),
    esVigente: tcpeBool(json['esVigente']),
    idGrupo: tcpeInt(json['idGrupo']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codTipo': codTipo.toInt(),
    'nombre': nombre,
    'esVigente': esVigente,
    'idGrupo': idGrupo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeTipoEntity toEntity() => TcpeTipoEntity(
    codTipo: codTipo,
    nombre: nombre,
    esVigente: esVigente,
    idGrupo: idGrupo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeTipoModel.fromEntity(TcpeTipoEntity e) => TcpeTipoModel(
    codTipo: e.codTipo,
    nombre: e.nombre,
    esVigente: e.esVigente,
    idGrupo: e.idGrupo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
