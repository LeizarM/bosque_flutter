// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Recarga la app web limpiando service workers y cache.
void hardReloadWeb() {
  // Desregistrar service workers
  html.window.navigator.serviceWorker
      ?.getRegistrations()
      .then((regs) {
        for (final reg in regs) {
          reg.unregister();
        }
        // Hard reload (true = bypass cache)
        html.window.location.reload();
      })
      .catchError((_) {
        html.window.location.reload();
      });
}
