// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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

/// El build con el que arrancó esta pestaña (lo deja web/flutter_bootstrap.js).
String? buildWebEnEjecucion() =>
    globalContext['bosqueBuild']?.dartify()?.toString();
