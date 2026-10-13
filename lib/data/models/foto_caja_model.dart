import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';

class FotoCajaModel {
  final int codFoto;
  final int codCaja;
  final int orden;
  final String? ruta;
  final int audUsuario;
  final DateTime? audFecha;

  const FotoCajaModel({
    required this.codFoto,
    required this.codCaja,
    required this.orden,
    this.ruta,
    this.audUsuario = 0,
    this.audFecha,
  });

  factory FotoCajaModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return FotoCajaModel(
      codFoto: entero('codFoto') ?? 0,
      codCaja: entero('codCaja') ?? 0,
      orden: entero('orden') ?? 0,
      ruta: json['ruta'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'codFoto': codFoto,
    'codCaja': codCaja,
    'orden': orden,
    'ruta': ruta,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
  };

  FotoCajaEntity toEntity() => FotoCajaEntity(
    codFoto: codFoto,
    codCaja: codCaja,
    orden: orden,
    ruta: ruta,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory FotoCajaModel.fromEntity(FotoCajaEntity e) => FotoCajaModel(
    codFoto: e.codFoto,
    codCaja: e.codCaja,
    orden: e.orden,
    ruta: e.ruta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
