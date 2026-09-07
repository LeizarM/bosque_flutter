// Destino final: lib/domain/entities/resultado_dependientes_entity.dart
import 'package:bosque_flutter/domain/entities/dependiente_cargo_entity.dart';

/// Envuelve la respuesta de listar-dependientes-jefe: a diferencia de un
/// CRUD normal, una lista vacía acá puede significar "no autorizado" O
/// "autorizado pero sin dependientes" — hay que distinguirlas para mostrar
/// el mensaje correcto (ver TareasColors y la pantalla de asignación).
class ResultadoDependientesEntity {
  final bool autorizado;
  final String mensaje;
  final List<DependienteCargoEntity> dependientes;

  const ResultadoDependientesEntity({
    required this.autorizado,
    required this.mensaje,
    required this.dependientes,
  });
}
