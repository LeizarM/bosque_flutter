import 'dart:async';

/// Consulta cada [intervalo] mientras la pantalla está visible, nunca dos a
/// la vez. Al volver a verse consulta enseguida. Lo usan el panel "En vivo" y
/// el espejo; quien lo crea decide qué es "visible" (ciclo de vida, diálogo).
class SondeoPeriodico {
  SondeoPeriodico({required this.consultar, required Duration intervalo}) : _intervalo = intervalo;

  final Future<void> Function() consultar;
  Duration _intervalo;
  Timer? _timer;
  bool _visible = true;
  bool _consultando = false;
  bool _detenido = true;

  bool get visible => _visible;
  bool get activo => _timer != null;

  /// Empieza a contar; la primera consulta la hace quien llama si la quiere ya.
  void iniciar() {
    _detenido = false;
    _programar();
  }

  set visible(bool valor) {
    if (valor == _visible) return;
    _visible = valor;
    _programar();
    if (valor && !_detenido) ahora();
  }

  set intervalo(Duration valor) {
    if (valor == _intervalo || valor <= Duration.zero) return;
    _intervalo = valor;
    _programar();
  }

  /// Consulta ya (si se ve y no hay otra en curso).
  Future<void> ahora() async {
    if (!_visible || _consultando || _detenido) return;
    _consultando = true;
    try {
      await consultar();
    } catch (_) {
      // Quien consulta muestra su error; el sondeo sigue.
    } finally {
      _consultando = false;
    }
  }

  void detener() {
    _detenido = true;
    _timer?.cancel();
    _timer = null;
  }

  void _programar() {
    _timer?.cancel();
    _timer = !_visible || _detenido ? null : Timer.periodic(_intervalo, (_) => ahora());
  }
}
