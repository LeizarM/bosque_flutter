import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';

/// `tcpe_usuario`: Usuario del módulo: empleado evaluado o postulante externo (login IPX-n).
/// Columnas de `p_list_tcpe_Usuario` (sin `password2`) más `nombreUsuario`.
class TcpeUsuarioModel {
  final BigInt codUsuario;
  final BigInt? codEmpleado;
  final BigInt? codTipoUsuario;
  final String? ci;
  final BigInt? codArea;
  final String? nombres;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? login;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeUsuarioModel({
    required this.codUsuario,
    this.codEmpleado,
    this.codTipoUsuario,
    this.ci,
    this.codArea,
    this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.login,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeUsuarioModel.fromJson(Map<String, dynamic> json) => TcpeUsuarioModel(
    codUsuario: tcpeBigInt(json['codUsuario']) ?? BigInt.zero,
    codEmpleado: tcpeBigInt(json['codEmpleado']),
    codTipoUsuario: tcpeBigInt(json['codTipoUsuario']),
    ci: tcpeTexto(json['ci']),
    codArea: tcpeBigInt(json['codArea']),
    nombres: tcpeTexto(json['nombres']),
    apellidoPaterno: tcpeTexto(json['apellidoPaterno']),
    apellidoMaterno: tcpeTexto(json['apellidoMaterno']),
    login: tcpeTexto(json['login']),
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codUsuario': codUsuario.toInt(),
    'codEmpleado': codEmpleado?.toInt(),
    'codTipoUsuario': codTipoUsuario?.toInt(),
    'ci': ci,
    'codArea': codArea?.toInt(),
    'nombres': nombres,
    'apellidoPaterno': apellidoPaterno,
    'apellidoMaterno': apellidoMaterno,
    'login': login,
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeUsuarioEntity toEntity() => TcpeUsuarioEntity(
    codUsuario: codUsuario,
    codEmpleado: codEmpleado,
    codTipoUsuario: codTipoUsuario,
    ci: ci,
    codArea: codArea,
    nombres: nombres,
    apellidoPaterno: apellidoPaterno,
    apellidoMaterno: apellidoMaterno,
    login: login,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeUsuarioModel.fromEntity(TcpeUsuarioEntity e) => TcpeUsuarioModel(
    codUsuario: e.codUsuario,
    codEmpleado: e.codEmpleado,
    codTipoUsuario: e.codTipoUsuario,
    ci: e.ci,
    codArea: e.codArea,
    nombres: e.nombres,
    apellidoPaterno: e.apellidoPaterno,
    apellidoMaterno: e.apellidoMaterno,
    login: e.login,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
