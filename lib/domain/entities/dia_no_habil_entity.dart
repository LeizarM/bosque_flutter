/// Un día del rango que **no descuenta** vacación, y por qué.
///
/// **Origen:** `POST /permiso-rrhh/permisos/dias-no-habiles`, que aplica la
/// misma regla que `f_CalcularDiasHabilesPermiso` al grabar. Si las dos se
/// separan, la pantalla explicaría una resta distinta de la que se guarda.
///
/// Los domingos **no** vienen del servidor: se deducen de la fecha y la UI los
/// arma sola.
class DiaNoHabilEntity {
  const DiaNoHabilEntity({
    required this.fecha,
    required this.tipo,
    required this.motivo,
  });

  final DateTime fecha;

  /// `FERIADO`, `SABADO_LIBRE` o `DOMINGO` (este último lo pone la UI).
  final String tipo;

  final String motivo;

  static const String feriado = 'FERIADO';
  static const String sabadoLibre = 'SABADO_LIBRE';
  static const String domingo = 'DOMINGO';
}
