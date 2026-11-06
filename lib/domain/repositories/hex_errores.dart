/// Resultado de una escritura: el `data` que devolvió el SP (id, o la cantidad
/// en aprobar-grupo) y su `errormsg`, el texto que se le muestra al usuario.
typedef HexRespuesta = ({BigInt id, String mensaje});

/// Una página de una bandeja y el total de filas que informa el SP.
typedef PaginaHex<T> = ({List<T> filas, int total});

/// Respuesta del backend que la pantalla trata aparte de un fallo técnico.
/// [mensaje] es el texto del servidor y se muestra tal cual, sin `humanizar`.
sealed class ErrorHex implements Exception {
  const ErrorHex(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// 403: falta la pantalla, el botón o el empleado en el token.
final class SinPermisoHex extends ErrorHex {
  const SinPermisoHex(super.mensaje);
}

/// 400 `confirmable`: si el usuario acepta, se reenvía el mismo cuerpo con
/// `confirmado: true`.
final class ConfirmacionHex extends ErrorHex {
  const ConfirmacionHex(super.mensaje);
}

/// 409: el dato cambió entre tanto (otro usuario o un doble toque). Se avisa y
/// se recarga; reintentar no sirve.
final class ConflictoHex extends ErrorHex {
  const ConflictoHex(super.mensaje);
}

/// 400 de negocio: la regla que el SP no dejó pasar.
final class NegocioHex extends ErrorHex {
  const NegocioHex(super.mensaje);
}

/// 204 donde la pantalla esperaba contenido (el PDF de una planilla que no
/// existe). No es un fallo técnico: se avisa con [mensaje] y nada más.
final class SinDatosHex extends ErrorHex {
  const SinDatosHex(super.mensaje);
}
