/// Una opción de un combo que arma el servidor: el código que se guarda, el
/// texto que se ve y un grupo (la empresa de una sucursal, por ejemplo).
class OpcionEntity {
  final int codigo;
  final String nombre;
  final String grupo;

  const OpcionEntity({
    required this.codigo,
    required this.nombre,
    this.grupo = '',
  });
}
