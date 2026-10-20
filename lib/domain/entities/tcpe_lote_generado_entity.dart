import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';

/// Respuesta de `/examenes/lotes/generar` y `/agregar`: el lote y las
/// credenciales de los exámenes recién creados. Las claves vienen en claro
/// **una sola vez**: hay que imprimirlas ahora.
class TcpeLoteGeneradoEntity {
  final BigInt codRolExamen;
  final List<TcpeCredencialEntity> credenciales;

  const TcpeLoteGeneradoEntity({
    required this.codRolExamen,
    this.credenciales = const [],
  });
}
