import 'package:flutter/foundation.dart';

/// Imprime solo en modo debug y es ignorado en producción.
void console(Object? object) {
  if (kDebugMode) {
    ///console(object.toString());
  }
}
