import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';

/// Respuesta de `/cheque/clientes/actualizar-sap`: el envelope completo
/// `{ message, data, status }`, con `data` nulo (el servidor no informa cuantos
/// clientes trajo). DTO de apoyo del backend, no una tabla.
///
/// Lectura tolerante: un `message` ausente o vacio deja un texto neutro; el exito
/// lo decide el codigo HTTP, no este cuerpo.
class ActualizarSociosSapModel {
  /// Lo que se muestra si el servidor no mandara su frase.
  static const String mensajePorDefecto =
      'Clientes actualizados desde SAP. Los cheques de los clientes que antes '
      'no estaban cargados ya aparecen en la lista.';

  final String mensaje;

  const ActualizarSociosSapModel({required this.mensaje});

  factory ActualizarSociosSapModel.fromJson(Map<String, dynamic> json) {
    final mensaje = (json['message']?.toString() ?? '').trim();
    return ActualizarSociosSapModel(
      mensaje: mensaje.isEmpty ? mensajePorDefecto : mensaje,
    );
  }

  Map<String, dynamic> toJson() => {'message': mensaje};

  ActualizarSociosSapEntity toEntity() =>
      ActualizarSociosSapEntity(mensaje: mensaje);

  factory ActualizarSociosSapModel.fromEntity(ActualizarSociosSapEntity e) =>
      ActualizarSociosSapModel(mensaje: e.mensaje);
}
