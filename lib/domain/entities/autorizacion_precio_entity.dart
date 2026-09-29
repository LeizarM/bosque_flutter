/// Autorizacion de una propuesta de precio (tabla tpr_autorizacion).
/// Es el registro de aprobacion/rechazo que cuelga de tpr_propuesta.
///
/// OJO con [esAprobada]: NO es un booleano aunque el nombre lo sugiera. Es un
/// entero con cuatro estados del dominio v_tipos grupo 38 (0 Pendiente,
/// 1 Aprobada, 2 No Aprobada, 3 En Espera). Nunca lo trates como bandera:
/// usa los getters derivados de abajo.
///
/// [audUsuario] y [audFecha] quedan vacios mientras la autorizacion no fue
/// decidida: el ABM los deja en NULL cuando [esAprobada] es 0 o 3.
class AutorizacionPrecioEntity {
  /// bigint IDENTITY. Vale 0 mientras no se inserta.
  final BigInt idAutorizacion;

  /// FK a tpr_propuesta.
  final BigInt idPropuesta;

  /// Estado de cuatro valores: 0 Pendiente, 1 Aprobada, 2 No Aprobada,
  /// 3 En Espera. Es int a proposito, nunca bool.
  final int esAprobada;

  /// Usuario que aprobo o rechazo. Cero si todavia no hubo decision.
  final BigInt audUsuario;

  /// Fecha de la aprobacion o rechazo. Null si todavia no hubo decision.
  final DateTime? audFecha;

  const AutorizacionPrecioEntity({
    required this.idAutorizacion,
    required this.idPropuesta,
    required this.esAprobada,
    required this.audUsuario,
    required this.audFecha,
  });

  /// 0 = Pendiente. Espera que alguien la revise.
  bool get esPendiente => esAprobada == 0;

  /// 1 = Aprobada.
  bool get estaAprobada => esAprobada == 1;

  /// 2 = No Aprobada. El autorizador la rechazo.
  bool get fueRechazada => esAprobada == 2;

  /// 3 = En Espera. Quedo en pausa, no es lo mismo que Pendiente.
  bool get estaEnEspera => esAprobada == 3;

  /// Etiqueta lista para mostrar en la pantalla.
  String get etiquetaEstado {
    switch (esAprobada) {
      case 0:
        return 'Pendiente';
      case 1:
        return 'Aprobada';
      case 2:
        return 'No Aprobada';
      case 3:
        return 'En Espera';
      default:
        return 'Desconocido';
    }
  }

  /// Ya hubo decision: solo Aprobada y No Aprobada cierran el ciclo.
  bool get fueDecidida => estaAprobada || fueRechazada;

  /// Sigue abierta: Pendiente o En Espera. Es el filtro de la bandeja.
  bool get sigueAbierta => esPendiente || estaEnEspera;

  /// Hay dato de auditoria cargado para mostrar quien y cuando decidio.
  bool get tieneAuditoria => audFecha != null && audUsuario > BigInt.zero;

  AutorizacionPrecioEntity copyWith({
    BigInt? idAutorizacion,
    BigInt? idPropuesta,
    int? esAprobada,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => AutorizacionPrecioEntity(
    idAutorizacion: idAutorizacion ?? this.idAutorizacion,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    esAprobada: esAprobada ?? this.esAprobada,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
