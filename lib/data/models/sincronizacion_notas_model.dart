/// Respuesta de traer las notas desde SAP.
///
/// Las tres respuestas del procedimiento son normales y ninguna es un error:
/// cargó, no hacía falta porque los datos eran frescos, o ya había otra carga
/// en curso. La pantalla solo necesita saber si tiene que releer.
class SincronizacionNotasModel {
  const SincronizacionNotasModel({
    required this.sincronizado,
    this.minutosDesde,
    this.mensaje,
  });

  final bool sincronizado;
  final int? minutosDesde;
  final String? mensaje;

  factory SincronizacionNotasModel.fromJson(Map<String, dynamic> json) =>
      SincronizacionNotasModel(
        sincronizado: json['sincronizado'] == true || json['sincronizado'] == 1,
        minutosDesde: json['minutosDesde'] as int?,
        mensaje: json['mensaje'] as String?,
      );
}
