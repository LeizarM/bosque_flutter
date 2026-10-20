import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:universal_html/html.dart' as html;

/// Avisa cuando quien rinde deja la pestaña o la app. En web escucha
/// `visibilitychange` y `blur`; en el teléfono, el ciclo de vida. Puede avisar
/// dos veces por la misma salida: quien lo usa las agrupa.
class DetectorSalidaPestana with WidgetsBindingObserver {
  DetectorSalidaPestana(this.alSalir);

  final VoidCallback alSalir;
  final List<StreamSubscription<Object?>> _suscripciones = [];
  bool _observando = false;

  void iniciar() {
    if (kIsWeb) {
      _suscripciones
        ..add(html.document.onVisibilityChange.listen((_) {
          if (html.document.hidden ?? false) alSalir();
        }))
        ..add(html.window.onBlur.listen((_) => alSalir()));
    } else if (!_observando) {
      WidgetsBinding.instance.addObserver(this);
      _observando = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) alSalir();
  }

  void detener() {
    for (final s in _suscripciones) {
      s.cancel();
    }
    _suscripciones.clear();
    if (_observando) {
      WidgetsBinding.instance.removeObserver(this);
      _observando = false;
    }
  }
}
