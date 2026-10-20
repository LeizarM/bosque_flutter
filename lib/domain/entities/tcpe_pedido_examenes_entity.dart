import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';

/// Cómo se indican los externos de un pedido: anónimos por cantidad o una
/// lista de personas con CI.
enum ModoExternos { cantidad, personas }

/// A quiénes van los exámenes nuevos de un lote (lote mixto): [cantidad]
/// externos anónimos, [personas] externos con CI y [codEmpleados], juntos si
/// hace falta. Solo los externos en línea reciben una clave temporal al azar.
class TcpePedidoExamenesEntity {
  final int cantidad;
  final List<TcpePersonaExamenEntity> personas;
  final List<BigInt> codEmpleados;

  const TcpePedidoExamenesEntity({this.cantidad = 0, this.personas = const [], this.codEmpleados = const []});

  const TcpePedidoExamenesEntity.cantidad(int cantidad) : this(cantidad: cantidad);

  const TcpePedidoExamenesEntity.personas(List<TcpePersonaExamenEntity> personas) : this(personas: personas);

  const TcpePedidoExamenesEntity.empleados(List<BigInt> codEmpleados) : this(codEmpleados: codEmpleados);

  /// Exámenes para externos: los anónimos más las personas con CI.
  int get externos => cantidad + personas.length;

  /// Cuántos exámenes pide en total.
  int get total => externos + codEmpleados.length;
}
