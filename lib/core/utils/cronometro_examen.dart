import 'dart:math' as math;

/// Cuánto le queda al examen según el servidor. Nunca se calcula contra
/// `fechaLimite` (el reloj del dispositivo no es confiable): descuenta lo
/// transcurrido desde el último `segundosRestantes` ([sincronizar]).
class CronometroExamen {
  CronometroExamen({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;
  int _base = 0;
  DateTime? _marca;

  bool get sincronizado => _marca != null;

  void sincronizar(int segundosServidor) {
    _base = math.max(0, segundosServidor);
    _marca = _reloj();
  }

  int get restantes {
    final marca = _marca;
    if (marca == null) return 0;
    final pasados = _reloj().difference(marca).inMilliseconds ~/ 1000;
    return math.max(0, _base - pasados);
  }

  bool get agotado => sincronizado && restantes == 0;

  /// `mm:ss`, o `h:mm:ss` desde la hora.
  static String formato(int segundos) {
    final s = math.max(0, segundos);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '${m.toString().padLeft(2, '0')}:$ss';
  }

  /// Últimos 5 minutos: el reloj cambia de tono.
  static bool enAviso(int segundos) => segundos <= 300;

  /// Último minuto.
  static bool critico(int segundos) => segundos <= 60;
}
