/// Respuesta al pedir un código de recuperación: a qué correo se envió
/// (enmascarado, p. ej. `j****z@esppapel.com`), cuántos minutos vale y cuánto
/// hay que esperar para pedir otro (los dos salen de trec_configuracion).
class RecuperacionEnviadaEntity {
  final String correo;
  final int minutosVigencia;
  final int segundosParaReenviar;

  const RecuperacionEnviadaEntity({
    required this.correo,
    required this.minutosVigencia,
    required this.segundosParaReenviar,
  });
}
