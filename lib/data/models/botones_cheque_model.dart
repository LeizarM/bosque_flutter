import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';

/// BotonesChequeDto del backend: cuatro booleanos y los 4 caracteres de la
/// rama K de los que salen.
///
/// Si faltara un booleano se lee del caracter que le corresponde: cualquier
/// cosa que no sea un `1` deshabilita, igual que el servidor.
class BotonesChequeModel {
  final bool fechaCobro;
  final bool devolver;
  final bool cerrarConVerificacion;
  final bool cerrarSinVerificacion;
  final String codigo;

  const BotonesChequeModel({
    required this.fechaCobro,
    required this.devolver,
    required this.cerrarConVerificacion,
    required this.cerrarSinVerificacion,
    required this.codigo,
  });

  factory BotonesChequeModel.fromJson(Map<String, dynamic> json) {
    final codigo = (json['codigo'] ?? '').toString().trim();
    bool leer(String clave, int posicion) {
      final v = json[clave];
      if (v is bool) return v;
      return codigo.length > posicion && codigo[posicion] == '1';
    }

    return BotonesChequeModel(
      fechaCobro: leer('fechaCobro', 0),
      devolver: leer('devolver', 1),
      cerrarConVerificacion: leer('cerrarConVerificacion', 2),
      cerrarSinVerificacion: leer('cerrarSinVerificacion', 3),
      codigo: codigo,
    );
  }

  Map<String, dynamic> toJson() => {
    'fechaCobro': fechaCobro,
    'devolver': devolver,
    'cerrarConVerificacion': cerrarConVerificacion,
    'cerrarSinVerificacion': cerrarSinVerificacion,
    'codigo': codigo,
  };

  BotonesChequeEntity toEntity() => BotonesChequeEntity(
    fechaCobro: fechaCobro,
    devolver: devolver,
    cerrarConVerificacion: cerrarConVerificacion,
    cerrarSinVerificacion: cerrarSinVerificacion,
    codigo: codigo,
  );

  factory BotonesChequeModel.fromEntity(BotonesChequeEntity e) =>
      BotonesChequeModel(
        fechaCobro: e.fechaCobro,
        devolver: e.devolver,
        cerrarConVerificacion: e.cerrarConVerificacion,
        cerrarSinVerificacion: e.cerrarSinVerificacion,
        codigo: e.codigo,
      );
}
