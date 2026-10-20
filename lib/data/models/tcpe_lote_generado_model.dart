import 'package:bosque_flutter/data/models/tcpe_credencial_model.dart';
import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_generado_entity.dart';

/// `{codRolExamen, credenciales:[{codExamen, login, password}]}`.
class TcpeLoteGeneradoModel {
  final BigInt codRolExamen;
  final List<TcpeCredencialModel> credenciales;

  const TcpeLoteGeneradoModel({
    required this.codRolExamen,
    this.credenciales = const [],
  });

  factory TcpeLoteGeneradoModel.fromJson(Map<String, dynamic> json) =>
      TcpeLoteGeneradoModel(
        codRolExamen: tcpeBigInt(json['codRolExamen']) ?? BigInt.zero,
        credenciales: [
          for (final c in (json['credenciales'] as List<dynamic>? ?? const []))
            if (c is Map) TcpeCredencialModel.fromJson(Map<String, dynamic>.from(c)),
        ],
      );

  Map<String, dynamic> toJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'credenciales': [for (final c in credenciales) c.toJson()],
  };

  TcpeLoteGeneradoEntity toEntity() => TcpeLoteGeneradoEntity(
    codRolExamen: codRolExamen,
    credenciales: [for (final c in credenciales) c.toEntity()],
  );

  factory TcpeLoteGeneradoModel.fromEntity(TcpeLoteGeneradoEntity e) =>
      TcpeLoteGeneradoModel(
        codRolExamen: e.codRolExamen,
        credenciales: [
          for (final c in e.credenciales) TcpeCredencialModel.fromEntity(c),
        ],
      );
}
