import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';

class CiudadVentaModel {
  final int codUsuario;
  final int codCiudad;
  final String ciudad;

  CiudadVentaModel({
    required this.codUsuario,
    required this.codCiudad,
    required this.ciudad,
  });

  factory CiudadVentaModel.fromJson(Map<String, dynamic> json) =>
      CiudadVentaModel(
        codUsuario: (json['codUsuario'] as num?)?.toInt() ?? 0,
        codCiudad: (json['codCiudad'] as num?)?.toInt() ?? 0,
        ciudad: _tipoTitulo((json['ciudad'] as String?)?.trim() ?? ''),
      );

  /// "LA PAZ" -> "La Paz". Así se ven en chips y casillas.
  static String _tipoTitulo(String texto) => texto
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');

  factory CiudadVentaModel.fromEntity(CiudadVentaEntity e) => CiudadVentaModel(
    codUsuario: e.codUsuario,
    codCiudad: e.codCiudad,
    ciudad: e.ciudad,
  );

  Map<String, dynamic> toJson() => {
    'codUsuario': codUsuario,
    'codCiudad': codCiudad,
  };

  CiudadVentaEntity toEntity() => CiudadVentaEntity(
    codUsuario: codUsuario,
    codCiudad: codCiudad,
    ciudad: ciudad,
  );
}

class CiudadesPermitidasModel {
  final List<CiudadVentaModel> ciudades;
  final bool todas;
  final bool esAdmin;
  final int codCiudadInicial;

  CiudadesPermitidasModel({
    required this.ciudades,
    required this.todas,
    required this.esAdmin,
    required this.codCiudadInicial,
  });

  factory CiudadesPermitidasModel.fromJson(Map<String, dynamic> json) =>
      CiudadesPermitidasModel(
        ciudades:
            ((json['ciudades'] as List<dynamic>?) ?? [])
                .map(
                  (c) => CiudadVentaModel.fromJson(c as Map<String, dynamic>),
                )
                .toList(),
        todas: json['todas'] == true,
        esAdmin: json['esAdmin'] == true,
        codCiudadInicial: (json['codCiudadInicial'] as num?)?.toInt() ?? 0,
      );

  CiudadesPermitidasEntity toEntity() => CiudadesPermitidasEntity(
    ciudades: ciudades.map((c) => c.toEntity()).toList(),
    todas: todas,
    esAdmin: esAdmin,
    codCiudadInicial: codCiudadInicial,
  );
}
