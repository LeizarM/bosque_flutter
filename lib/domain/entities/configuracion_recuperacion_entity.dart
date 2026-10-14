/// Un parámetro de la recuperación de acceso (trec_configuracion).
///
/// En los de tipo `secreto` (la contraseña SMTP) el valor nunca viaja: solo
/// [configurado] dice si está cargado.
class ConfiguracionRecuperacionEntity {
  final String clave;
  final String? valor;
  final String nombre;
  final String descripcion;

  /// texto, numero, correo, dominios, opcion o secreto: cómo se edita y valida.
  final String tipo;
  final List<String> opciones;
  final int? minimo;
  final int? maximo;
  final String grupo;
  final int orden;
  final int? audUsuario;
  final DateTime? audFecha;
  final bool configurado;

  const ConfiguracionRecuperacionEntity({
    required this.clave,
    required this.valor,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.opciones,
    required this.minimo,
    required this.maximo,
    required this.grupo,
    required this.orden,
    required this.audUsuario,
    required this.audFecha,
    required this.configurado,
  });

  bool get esSecreto => tipo == 'secreto';
}
