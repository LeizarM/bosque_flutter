/// Lo que responde `POST /cheque/clientes/actualizar-sap` («Actualizar datos
/// SAP»): la frase que el servidor redacto para el usuario. No es una tabla: es el
/// resultado de una accion.
///
/// No lleva cuantos clientes se trajeron: el procedimiento del servidor no lo
/// informa (no tiene salidas y lo comparte Depositos, asi que no se altera).
class ActualizarSociosSapEntity {
  /// El `message` del servidor, listo para mostrar tal cual.
  final String mensaje;

  const ActualizarSociosSapEntity({required this.mensaje});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActualizarSociosSapEntity && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
