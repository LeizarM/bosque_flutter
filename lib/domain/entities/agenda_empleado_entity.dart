/// Un compañero en la agenda del Dashboard: quién es, qué cargo tiene, en qué
/// sucursal está y sus números corporativos (puede no tener ninguno).
class AgendaEmpleadoEntity {
  final BigInt codEmpleado;
  final String nombreCompleto;
  final String cargo;
  final int codSucursal;
  final String sucursal;
  final String empresa;
  final List<String> telefonos;

  /// Si quien mira puede abrir su ficha: la misma regla que la ficha del
  /// trabajador, decidida en el servidor.
  final bool puedeVerFicha;

  const AgendaEmpleadoEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.cargo = '',
    this.codSucursal = 0,
    this.sucursal = '',
    this.empresa = '',
    this.telefonos = const [],
    this.puedeVerFicha = false,
  });

  bool get tieneCorporativo => telefonos.isNotEmpty;

  /// Primera letra de la primera y de la última palabra, para el avatar.
  String get iniciales {
    final partes =
        nombreCompleto.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
