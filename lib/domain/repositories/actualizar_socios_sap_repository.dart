import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';

/// «Actualizar datos SAP» de la pantalla de Cheques: trae a la base del Bosque
/// los clientes nuevos de SAP. Un solo endpoint, sin cuerpo; el usuario de
/// auditoria sale del token.
abstract class ActualizarSociosSapRepository {
  /// `POST /cheque/clientes/actualizar-sap`. Exige el boton `btnNuevoCH`. Trae
  /// las cuatro empresas de SAP a la vez y tarda cerca de medio segundo. El
  /// servidor no dice cuantos clientes trajo: devuelve solo su frase.
  ///
  /// Un fallo (sin permiso, otra actualizacion en curso, SAP sin responder) llega
  /// como excepcion con el texto completo del servidor, para mostrarlo tal cual.
  Future<ActualizarSociosSapEntity> actualizar();
}
